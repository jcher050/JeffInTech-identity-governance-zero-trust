<#
.SYNOPSIS
    Creates the security groups required for the JeffInTech
    Entra Identity Modernization project.

.DESCRIPTION
    This script:

    1. Connects to Microsoft Graph.
    2. Creates dynamic department security groups.
    3. Creates assigned security groups used for IAM/security controls.
    4. Creates a role-assignable group for PIM.
    5. Finds JeffInTech contractors by employeeType.
    6. Adds contractors to GRP-Contractors.
    7. Avoids recreating existing groups or duplicate memberships.

.NOTES
    Project: JeffInTech Entra Identity Modernization
    Environment: Fictional portfolio/lab environment
#>

# ============================================================
# 1. Safety / error handling
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================"
Write-Host " JeffInTech Entra Group Provisioning"
Write-Host "============================================================"
Write-Host ""


# ============================================================
# 2. Import required Microsoft Graph modules
# ============================================================

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Users


# ============================================================
# 3. Microsoft Graph permissions
# ============================================================

$RequiredScopes = @(
    "Group.ReadWrite.All",
    "User.Read.All",
    "RoleManagement.ReadWrite.Directory"
)

$Context = Get-MgContext

if (-not $Context) {

    Write-Host "No Microsoft Graph session found."
    Write-Host "Connecting to Microsoft Graph..."

    Connect-MgGraph `
        -Scopes $RequiredScopes `
        -NoWelcome
}
else {

    $MissingScopes = @(
        $RequiredScopes |
        Where-Object {
            $_ -notin $Context.Scopes
        }
    )

    if ($MissingScopes.Count -gt 0) {

        Write-Host "Current Graph session is missing required permissions:"
        $MissingScopes | ForEach-Object {
            Write-Host " - $_"
        }

        Write-Host ""
        Write-Host "Reconnecting to Microsoft Graph..."

        Disconnect-MgGraph | Out-Null

        Connect-MgGraph `
            -Scopes $RequiredScopes `
            -NoWelcome
    }
}

$Context = Get-MgContext

Write-Host ""
Write-Host "Connected to Microsoft Graph as:"
Write-Host $Context.Account
Write-Host ""


# ============================================================
# 4. Helper function - find a group safely
# ============================================================

function Get-JeffInTechGroup {

    param(
        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $Groups = @(
        Get-MgGroup `
            -Filter "displayName eq '$DisplayName'" `
            -Property `
                Id,
                DisplayName,
                Description,
                GroupTypes,
                MembershipRule,
                MembershipRuleProcessingState,
                IsAssignableToRole,
                SecurityEnabled,
                MailEnabled
    )

    if ($Groups.Count -gt 1) {

        throw "More than one group named '$DisplayName' exists. Resolve the duplicate names before continuing."
    }

    if ($Groups.Count -eq 1) {

        return $Groups[0]
    }

    return $null
}


# ============================================================
# 5. Define dynamic department groups
# ============================================================

$DynamicGroups = @(

    @{
        Name        = "GRP-Department-Finance"
        Description = "JeffInTech Finance department security group populated dynamically from the Entra department attribute."
        Rule        = 'user.department -eq "Finance"'
    },

    @{
        Name        = "GRP-Department-Sales"
        Description = "JeffInTech Sales department security group populated dynamically from the Entra department attribute."
        Rule        = 'user.department -eq "Sales"'
    },

    @{
        Name        = "GRP-Department-HR"
        Description = "JeffInTech HR department security group populated dynamically from the Entra department attribute."
        Rule        = 'user.department -eq "HR"'
    },

    @{
        Name        = "GRP-Department-IT"
        Description = "JeffInTech IT department security group populated dynamically from the Entra department attribute."
        Rule        = 'user.department -eq "IT"'
    }
)


# ============================================================
# 6. Create / validate dynamic department groups
# ============================================================

Write-Host "Creating dynamic department groups..."
Write-Host ""

foreach ($Group in $DynamicGroups) {

    $ExistingGroup =
        Get-JeffInTechGroup `
            -DisplayName $Group.Name

    if (-not $ExistingGroup) {

        $MailNickname =
            $Group.Name.Replace("-", "").ToLower()

        $Parameters = @{
            displayName                   = $Group.Name
            description                   = $Group.Description
            mailEnabled                   = $false
            mailNickname                  = $MailNickname
            securityEnabled               = $true
            groupTypes                    = @("DynamicMembership")
            membershipRule                = $Group.Rule
            membershipRuleProcessingState = "On"
        }

        $CreatedGroup =
            New-MgGroup `
                -BodyParameter $Parameters

        Write-Host "[CREATED] $($Group.Name)"
        Write-Host "          Rule: $($Group.Rule)"
    }
    else {

        # ----------------------------------------------------
        # Protect against accidentally using a static group
        # with the same name.
        # ----------------------------------------------------

        if (
            $ExistingGroup.GroupTypes -notcontains
            "DynamicMembership"
        ) {

            throw @"
$($Group.Name) already exists, but it is NOT a dynamic group.

For safety, this script will not automatically convert an
existing assigned group into a dynamic group.

Review the group manually before continuing.
"@
        }

        # ----------------------------------------------------
        # Make sure the existing dynamic rule is correct
        # ----------------------------------------------------

        if (
            $ExistingGroup.MembershipRule -ne $Group.Rule -or
            $ExistingGroup.MembershipRuleProcessingState -ne "On"
        ) {

            Update-MgGroup `
                -GroupId $ExistingGroup.Id `
                -MembershipRule $Group.Rule `
                -MembershipRuleProcessingState "On" `
                -Description $Group.Description

            Write-Host "[UPDATED] $($Group.Name)"
            Write-Host "          Rule: $($Group.Rule)"
        }
        else {

            Write-Host "[EXISTS]  $($Group.Name)"
        }
    }
}


# ============================================================
# 7. Define assigned security groups
# ============================================================

$AssignedGroups = @(

    @{
        Name        = "GRP-SSPR-Pilot"
        Description = "JeffInTech pilot group for Self-Service Password Reset."
    },

    @{
        Name        = "GRP-Passwordless-Pilot"
        Description = "JeffInTech pilot group for passwordless authentication deployment."
    },

    @{
        Name        = "GRP-CA-Admins"
        Description = "JeffInTech group used to target administrator Conditional Access controls."
    },

    @{
        Name        = "GRP-CA-SensitiveApps"
        Description = "JeffInTech security group used with Conditional Access controls for sensitive applications."
    },

    @{
        Name        = "GRP-Contractors"
        Description = "JeffInTech contractors synchronized from HR employeeType data."
    }
)


# ============================================================
# 8. Create assigned security groups
# ============================================================

Write-Host ""
Write-Host "Creating assigned IAM/security groups..."
Write-Host ""

foreach ($Group in $AssignedGroups) {

    $ExistingGroup =
        Get-JeffInTechGroup `
            -DisplayName $Group.Name

    if (-not $ExistingGroup) {

        $MailNickname =
            $Group.Name.Replace("-", "").ToLower()

        $CreatedGroup =
            New-MgGroup `
                -DisplayName $Group.Name `
                -Description $Group.Description `
                -MailEnabled:$false `
                -MailNickname $MailNickname `
                -SecurityEnabled:$true

        Write-Host "[CREATED] $($Group.Name)"
    }
    else {

        # ----------------------------------------------------
        # These groups should use assigned membership.
        # ----------------------------------------------------

        if (
            $ExistingGroup.GroupTypes -contains
            "DynamicMembership"
        ) {

            throw "$($Group.Name) exists but is configured as a dynamic group. Review it before continuing."
        }

        Write-Host "[EXISTS]  $($Group.Name)"
    }
}


# ============================================================
# 9. Create role-assignable PIM security group
# ============================================================

Write-Host ""
Write-Host "Checking PIM role-assignable group..."
Write-Host ""

$PimGroupName = "GRP-PIM-CloudOperators"

$PimGroup =
    Get-JeffInTechGroup `
        -DisplayName $PimGroupName


if (-not $PimGroup) {

    $PimParameters = @{

        displayName =
            $PimGroupName

        description =
            "JeffInTech Cloud Operators group designed for privileged access through Microsoft Entra PIM."

        mailEnabled =
            $false

        mailNickname =
            "grppimcloudoperators"

        securityEnabled =
            $true

        isAssignableToRole =
            $true
    }

    try {

        $PimGroup =
            New-MgGroup `
                -BodyParameter $PimParameters

        Write-Host "[CREATED] $PimGroupName"
        Write-Host "          Role assignable: True"
    }
    catch {

        Write-Host ""
        Write-Host "[ERROR] Unable to create the PIM role-assignable group."
        Write-Host ""
        Write-Host "Verify that:"
        Write-Host "  - Your tenant supports role-assignable groups."
        Write-Host "  - Your account has sufficient Entra privileges."
        Write-Host "  - RoleManagement.ReadWrite.Directory was consented."
        Write-Host ""

        throw
    }
}
else {

    # --------------------------------------------------------
    # isAssignableToRole cannot be changed after creation.
    # --------------------------------------------------------

    if ($PimGroup.IsAssignableToRole -ne $true) {

        throw @"
GRP-PIM-CloudOperators already exists, but it was NOT created
as a role-assignable group.

Microsoft Entra does not allow isAssignableToRole to be changed
from false to true after the group has been created.

For this lab, delete/recreate the group after confirming it is
safe to do so, or create a new role-assignable group.
"@
    }

    if (
        $PimGroup.GroupTypes -contains
        "DynamicMembership"
    ) {

        throw "GRP-PIM-CloudOperators cannot be a dynamic group because role-assignable groups require assigned membership."
    }

    Write-Host "[EXISTS]  $PimGroupName"
    Write-Host "          Role assignable: True"
}


# ============================================================
# 10. Find GRP-Contractors
# ============================================================

Write-Host ""
Write-Host "Synchronizing JeffInTech contractors..."
Write-Host ""

$ContractorGroup =
    Get-JeffInTechGroup `
        -DisplayName "GRP-Contractors"

if (-not $ContractorGroup) {

    throw "GRP-Contractors could not be found."
}


# ============================================================
# 11. Get JeffInTech contractor identities
#
# employeeType tells us the worker relationship.
# UPN domain limits this operation to JeffInTech lab users.
# ============================================================

$Contractors = @(

    Get-MgUser `
        -All `
        -Property `
            Id,
            DisplayName,
            UserPrincipalName,
            EmployeeType |
    Where-Object {

        $_.EmployeeType -eq "Contractor" -and
        $_.UserPrincipalName -like "*@jeffintech.com"
    }
)


Write-Host "JeffInTech contractors found: $($Contractors.Count)"
Write-Host ""


# ============================================================
# 12. Read existing contractor group membership
# ============================================================

$ExistingContractorMembers = @(

    Get-MgGroupMember `
        -GroupId $ContractorGroup.Id `
        -All
)

$ExistingMemberIds =
    @(
        $ExistingContractorMembers |
        ForEach-Object {
            $_.Id
        }
    )


# ============================================================
# 13. Add missing contractors
# ============================================================

foreach ($Contractor in $Contractors) {

    if (
        $Contractor.Id -notin
        $ExistingMemberIds
    ) {

        $Reference = @{

            "@odata.id" =
                "https://graph.microsoft.com/v1.0/directoryObjects/$($Contractor.Id)"
        }

        try {

            New-MgGroupMemberByRef `
                -GroupId $ContractorGroup.Id `
                -BodyParameter $Reference

            Write-Host "[ADDED]   $($Contractor.DisplayName)"
            Write-Host "          $($Contractor.UserPrincipalName)"
        }
        catch {

            Write-Host ""
            Write-Host "[ERROR] Could not add:"
            Write-Host "        $($Contractor.DisplayName)"
            Write-Host ""
            Write-Host $_.Exception.Message
            Write-Host ""

            throw
        }
    }
    else {

        Write-Host "[MEMBER]  $($Contractor.DisplayName)"
    }
}


# ============================================================
# 14. Validation / summary
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host " JeffInTech Group Provisioning Complete"
Write-Host "============================================================"
Write-Host ""

$JeffInTechGroupNames = @(
    "GRP-Department-Finance",
    "GRP-Department-Sales",
    "GRP-Department-HR",
    "GRP-Department-IT",
    "GRP-SSPR-Pilot",
    "GRP-Passwordless-Pilot",
    "GRP-CA-Admins",
    "GRP-CA-SensitiveApps",
    "GRP-PIM-CloudOperators",
    "GRP-Contractors"
)

$Results = foreach ($GroupName in $JeffInTechGroupNames) {

    $Group =
        Get-JeffInTechGroup `
            -DisplayName $GroupName

    if ($Group) {

        [PSCustomObject]@{

            DisplayName =
                $Group.DisplayName

            MembershipType =
                if (
                    $Group.GroupTypes -contains
                    "DynamicMembership"
                ) {
                    "Dynamic"
                }
                else {
                    "Assigned"
                }

            RoleAssignable =
                $Group.IsAssignableToRole

            DynamicRule =
                $Group.MembershipRule
        }
    }
}

$Results |
    Format-Table `
        DisplayName,
        MembershipType,
        RoleAssignable,
        DynamicRule `
        -AutoSize

Write-Host ""
Write-Host "Expected total JeffInTech IAM groups: 10"
Write-Host "Groups found: $($Results.Count)"
Write-Host ""

Write-Host "Script completed successfully."
Write-Host ""
