<#
.SYNOPSIS
    Creates the security groups required for the JeffInTech
    Entra Identity Modernization portfolio project.

.DESCRIPTION
    This script:

    1. Uses the existing Microsoft Graph session when possible.
    2. Validates that the session is connected to the JeffInTech tenant.
    3. Reconnects with Device Code authentication only if required.
    4. Creates four dynamic department security groups.
    5. Creates assigned IAM/security groups.
    6. Creates a role-assignable security group for PIM.
    7. Finds JeffInTech contractors using employeeType.
    8. Adds those contractors to GRP-Contractors.
    9. Avoids recreating existing groups or duplicate memberships.
    10. Produces a validation summary at the end.

.NOTES
    Project: JeffInTech Entra Identity Modernization
    Environment: Fictional portfolio/lab environment
#>


# ============================================================
# 1. Safety/error handling
# ============================================================

# StrictMode = catch mistakes
Set-StrictMode -Version Latest  ### Safety setup If I use an undefined variable or make a sloppy scripting mistake, PowerShell is more likely to catch it instead of quietly continuing.
$ErrorActionPreference = "Stop"  ## stop on errors. If a real error happens, stop the script instead of continuing.

## Make the console readable; print a clean heading to the terminal
Write-Host ""
Write-Host "============================================================"
Write-Host " JeffInTech Entra Group Provisioning"
Write-Host "============================================================"
Write-Host ""
## Make the console readable; print a clean heading to the terminal


# ============================================================
# 2. JeffInTech tenant configuration
# ============================================================

# Stores the ID of the Microsoft Entra tenant
$TargetTenantId = "xxxxxxxxxx-xxxxx-xxxx-xxxx-xxxxxxx"

# Stores your company domain so the script can recognize JeffInTech accounts
$JeffInTechDomain = "jeffintech.com"


# ============================================================
# 3. Import Microsoft Graph modules
# ============================================================

Write-Host "Loading Microsoft Graph modules..." ## Make the console readable; print a clean heading to the terminal

Import-Module Microsoft.Graph.Authentication  
Import-Module Microsoft.Graph.Groups          
Import-Module Microsoft.Graph.Users

Write-Host "[OK] Microsoft Graph modules loaded."  ## Make the console readable; print a clean heading to the terminal
Write-Host "" ## Make the console readable; print a clean heading to the terminal


# ============================================================
# 4. Microsoft Graph permissions
#
# Group.ReadWrite.All
#     Create and manage the security groups.
#
# User.Read.All
#     Read users and HR attributes such as employeeType.
#
# RoleManagement.ReadWrite.Directory
#     Required for privileged/role management operations and
#     useful for the PIM portion of this project.
# ============================================================

$RequiredScopes = @(
    "Group.ReadWrite.All",
    "User.Read.All",
    "RoleManagement.ReadWrite.Directory"
)


# ============================================================
# 5. Validate the existing Microsoft Graph connection
# ============================================================

$Context = Get-MgContext

$ReconnectRequired = $false


if (-not $Context) {

    Write-Host "[INFO] No active Microsoft Graph session was found."

    $ReconnectRequired = $true
}
else {

    Write-Host "[OK] Existing Microsoft Graph session found."
    Write-Host "     Tenant: $($Context.TenantId)"
    Write-Host "     Auth:   $($Context.AuthType)"
    Write-Host "     Scope:  $($Context.ContextScope)"
    Write-Host ""


    # --------------------------------------------------------
    # Make sure we are operating against the correct tenant.
    # --------------------------------------------------------

    if ($Context.TenantId -ne $TargetTenantId) {

        Write-Host "[WARNING] The current session is connected to:"
        Write-Host "          $($Context.TenantId)"
        Write-Host ""
        Write-Host "Expected JeffInTech tenant:"
        Write-Host "          $TargetTenantId"
        Write-Host ""

        $ReconnectRequired = $true
    }


    # --------------------------------------------------------
    # Make sure the Graph token contains our required scopes.
    # --------------------------------------------------------

    $MissingScopes = @(
        $RequiredScopes |
        Where-Object {
            $_ -notin $Context.Scopes
        }
    )


    if ($MissingScopes.Count -gt 0) {

        Write-Host "[WARNING] Current session is missing Graph permissions:"

        foreach ($Scope in $MissingScopes) {

            Write-Host "          - $Scope"
        }

        Write-Host ""

        $ReconnectRequired = $true
    }
}


# ============================================================
# 6. Reconnect only when necessary
#
# This matches the authentication method that already worked
# successfully for you:
#
# -TenantId
# -Scopes
# -UseDeviceCode
# -ContextScope Process
# ============================================================

if ($ReconnectRequired) {

    Write-Host "Reconnecting to Microsoft Graph..."
    Write-Host ""

    if (Get-MgContext) {

        Disconnect-MgGraph | Out-Null
    }


    Connect-MgGraph `
        -TenantId $TargetTenantId `
        -Scopes $RequiredScopes `
        -UseDeviceCode `
        -ContextScope Process `
        -NoWelcome


    $Context = Get-MgContext
}


# ============================================================
# 7. Final connection validation
# ============================================================

if (-not $Context) {

    throw "Microsoft Graph authentication failed."
}


if ($Context.TenantId -ne $TargetTenantId) {

    throw "Connected tenant does not match the JeffInTech tenant."
}


Write-Host ""
Write-Host "[CONNECTED] Microsoft Graph"
Write-Host "Tenant ID:     $($Context.TenantId)"
Write-Host "Authentication:$($Context.AuthType)"
Write-Host "Context Scope: $($Context.ContextScope)"

if ($Context.Account) {

    Write-Host "Account:       $($Context.Account)"
}
else {

    Write-Host "Account:       Device-code delegated session"
}

Write-Host ""


# ============================================================
# 8. Helper function
#
# Finds exactly one group by display name.
#
# This protects the script from accidentally modifying the
# wrong group when duplicate names exist.
# ============================================================

function Get-JeffInTechGroup {

    param(

        [Parameter(Mandatory)]
        [string]$DisplayName
    )


    # Escape apostrophes for OData just in case one is ever
    # used in a group display name.

    $SafeDisplayName =
        $DisplayName.Replace("'", "''")


    $Groups = @(

        Get-MgGroup `
            -Filter "displayName eq '$SafeDisplayName'" `
            -Property `
                Id,
                DisplayName,
                Description,
                GroupTypes,
                MembershipRule,
                MembershipRuleProcessingState,
                IsAssignableToRole,
                SecurityEnabled,
                MailEnabled,
                MailNickname
    )


    if ($Groups.Count -gt 1) {

        throw @"
More than one group named '$DisplayName' exists.

Resolve the duplicate group names before running this script.
"@
    }


    if ($Groups.Count -eq 1) {

        return $Groups[0]
    }


    return $null
}


# ============================================================
# 9. Define dynamic department groups
#
# These groups are attribute driven.
#
# Example:
#
# department = Finance
#          ↓
# GRP-Department-Finance
#
# If the department changes later, Entra reevaluates the rule.
# ============================================================

$DynamicGroups = @(

    @{
        Name =
            "GRP-Department-Finance"

        Description =
            "JeffInTech Finance department security group populated dynamically from the Entra department attribute."

        Rule =
            'user.department -eq "Finance"'
    },

    @{
        Name =
            "GRP-Department-Sales"

        Description =
            "JeffInTech Sales department security group populated dynamically from the Entra department attribute."

        Rule =
            'user.department -eq "Sales"'
    },

    @{
        Name =
            "GRP-Department-HR"

        Description =
            "JeffInTech HR department security group populated dynamically from the Entra department attribute."

        Rule =
            'user.department -eq "HR"'
    },

    @{
        Name =
            "GRP-Department-IT"

        Description =
            "JeffInTech IT department security group populated dynamically from the Entra department attribute."

        Rule =
            'user.department -eq "IT"'
    }
)


# ============================================================
# 10. Create / validate dynamic department groups
# ============================================================

Write-Host "------------------------------------------------------------"
Write-Host " Creating Dynamic Department Groups"
Write-Host "------------------------------------------------------------"
Write-Host ""


foreach ($Group in $DynamicGroups) {

    $ExistingGroup =
        Get-JeffInTechGroup `
            -DisplayName $Group.Name


    # --------------------------------------------------------
    # GROUP DOES NOT EXIST
    # --------------------------------------------------------

    if (-not $ExistingGroup) {

        $MailNickname =
            $Group.Name.Replace("-", "").ToLower()


        $Parameters = @{

            displayName =
                $Group.Name

            description =
                $Group.Description

            mailEnabled =
                $false

            mailNickname =
                $MailNickname

            securityEnabled =
                $true

            groupTypes =
                @("DynamicMembership")

            membershipRule =
                $Group.Rule

            membershipRuleProcessingState =
                "On"
        }


        try {

            $CreatedGroup =
                New-MgGroup `
                    -BodyParameter $Parameters


            Write-Host "[CREATED] $($Group.Name)"
            Write-Host "          $($Group.Rule)"
            Write-Host ""
        }
        catch {

            Write-Host ""
            Write-Host "[ERROR] Could not create $($Group.Name)"
            Write-Host ""
            Write-Host $_.Exception.Message
            Write-Host ""

            throw @"
Dynamic group creation failed.

Common causes include:

1. The tenant does not have the Microsoft Entra licensing
   required for dynamic membership.

2. Your signed-in account does not have enough administrative
   privileges.

3. Group.ReadWrite.All was not successfully consented.
"@
        }
    }


    # --------------------------------------------------------
    # GROUP ALREADY EXISTS
    # --------------------------------------------------------

    else {

        # ----------------------------------------------------
        # Protect against accidentally using a STATIC group
        # that happens to have the same name.
        # ----------------------------------------------------

        if (
            $ExistingGroup.GroupTypes -notcontains
            "DynamicMembership"
        ) {

            throw @"
$($Group.Name) already exists but it is NOT configured for
dynamic membership.

For safety, the script will not automatically convert it.

Review the existing group in Microsoft Entra before continuing.
"@
        }


        # ----------------------------------------------------
        # Correct the membership rule if necessary.
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
            Write-Host "          $($Group.Rule)"
            Write-Host ""
        }
        else {

            Write-Host "[EXISTS]  $($Group.Name)"
            Write-Host ""
        }
    }
}


# ============================================================
# 11. Define assigned security groups
#
# These groups SHOULD NOT be driven automatically by department.
#
# Membership will be deliberately controlled later during the
# appropriate project phase.
# ============================================================

$AssignedGroups = @(

    @{
        Name =
            "GRP-SSPR-Pilot"

        Description =
            "JeffInTech pilot group for Self-Service Password Reset."
    },

    @{
        Name =
            "GRP-Passwordless-Pilot"

        Description =
            "JeffInTech pilot group for passwordless authentication deployment."
    },

    @{
        Name =
            "GRP-CA-Admins"

        Description =
            "JeffInTech group used to target administrator Conditional Access controls."
    },

    @{
        Name =
            "GRP-CA-SensitiveApps"

        Description =
            "JeffInTech security group used with Conditional Access controls for sensitive applications."
    },

    @{
        Name =
            "GRP-Contractors"

        Description =
            "JeffInTech contractor security group synchronized from HR employeeType data."
    }
)


# ============================================================
# 12. Create assigned IAM/security groups
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Creating Assigned IAM / Security Groups"
Write-Host "------------------------------------------------------------"
Write-Host ""


foreach ($Group in $AssignedGroups) {

    $ExistingGroup =
        Get-JeffInTechGroup `
            -DisplayName $Group.Name


    if (-not $ExistingGroup) {

        $MailNickname =
            $Group.Name.Replace("-", "").ToLower()


        New-MgGroup `
            -DisplayName $Group.Name `
            -Description $Group.Description `
            -MailEnabled:$false `
            -MailNickname $MailNickname `
            -SecurityEnabled:$true |
        Out-Null


        Write-Host "[CREATED] $($Group.Name)"
    }
    else {

        # ----------------------------------------------------
        # Assigned groups must not accidentally be configured
        # as dynamic groups.
        # ----------------------------------------------------

        if (
            $ExistingGroup.GroupTypes -contains
            "DynamicMembership"
        ) {

            throw @"
$($Group.Name) exists but is configured as a dynamic group.

This JeffInTech design expects this group to use assigned
membership.

Review the group before continuing.
"@
        }


        Write-Host "[EXISTS]  $($Group.Name)"
    }
}


# ============================================================
# 13. Create PIM role-assignable security group
#
# IMPORTANT:
#
# isAssignableToRole must be selected WHEN THE GROUP IS CREATED.
# It cannot simply be turned on later.
#
# Role-assignable groups also use assigned membership rather
# than dynamic membership.
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Creating / Validating PIM Cloud Operators Group"
Write-Host "------------------------------------------------------------"
Write-Host ""


$PimGroupName =
    "GRP-PIM-CloudOperators"


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
        Write-Host "[ERROR] Unable to create $PimGroupName."
        Write-Host ""
        Write-Host $_.Exception.Message
        Write-Host ""
        Write-Host "Check the following:"
        Write-Host ""
        Write-Host "  1. Your tenant has the required Entra licensing."
        Write-Host "  2. Your account has Privileged Role Administrator"
        Write-Host "     or sufficient equivalent privileges."
        Write-Host "  3. Group.ReadWrite.All was consented."
        Write-Host "  4. RoleManagement.ReadWrite.Directory was consented."
        Write-Host ""

        throw
    }
}
else {

    # --------------------------------------------------------
    # This property cannot be turned from false to true later.
    # --------------------------------------------------------

    if ($PimGroup.IsAssignableToRole -ne $true) {

        throw @"
GRP-PIM-CloudOperators already exists, but it was NOT created
as a role-assignable group.

Microsoft Entra does not allow an ordinary group to be changed
into a role-assignable group later.

Because this is your lab environment, we can delete and recreate
that specific group if necessary after verifying its contents.
"@
    }


    if (
        $PimGroup.GroupTypes -contains
        "DynamicMembership"
    ) {

        throw @"
GRP-PIM-CloudOperators is configured incorrectly.

A role-assignable group must use ASSIGNED membership rather than
dynamic membership.
"@
    }


    Write-Host "[EXISTS]  $PimGroupName"
    Write-Host "          Role assignable: True"
}


# ============================================================
# 14. Locate GRP-Contractors
# ============================================================

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Synchronizing Contractor Membership"
Write-Host "------------------------------------------------------------"
Write-Host ""


$ContractorGroup =
    Get-JeffInTechGroup `
        -DisplayName "GRP-Contractors"


if (-not $ContractorGroup) {

    throw "GRP-Contractors could not be found."
}


# ============================================================
# 15. Find JeffInTech contractor identities
#
# We require BOTH:
#
# employeeType = Contractor
#
# AND
#
# UPN ending in @jeffintech.com
#
# This prevents the script from accidentally touching guests
# or unrelated identities in the tenant.
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
        $_.UserPrincipalName -like "*@$JeffInTechDomain"
    }
)


Write-Host "JeffInTech contractors found: $($Contractors.Count)"
Write-Host ""


# ============================================================
# 16. Important lab-stage warning
#
# If users were created but HR attributes have not yet been
# populated, employeeType may still be empty.
#
# THAT IS NOT A FAILURE.
#
# We simply leave GRP-Contractors empty for now.
# ============================================================

if ($Contractors.Count -eq 0) {

    Write-Host "[INFO] No users currently have:"
    Write-Host ""
    Write-Host "       employeeType = Contractor"
    Write-Host ""
    Write-Host "This is OK if we have not populated the JeffInTech HR"
    Write-Host "attributes yet."
    Write-Host ""
    Write-Host "GRP-Contractors was created successfully."
    Write-Host "We will populate it after the HR identity data is loaded."
    Write-Host ""
}


# ============================================================
# 17. Read current contractor group membership
# ============================================================

$ExistingContractorMembers = @(

    Get-MgGroupMember `
        -GroupId $ContractorGroup.Id `
        -All
)


$ExistingMemberIds = @(

    $ExistingContractorMembers |
    ForEach-Object {

        $_.Id
    }
)


# ============================================================
# 18. Add missing contractor identities
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
            Write-Host "[ERROR] Could not add contractor:"
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
# 19. Validation / final report
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
Write-Host "Expected JeffInTech IAM groups: 10"
Write-Host "JeffInTech IAM groups found:    $($Results.Count)"
Write-Host ""


if ($Results.Count -eq 10) {

    Write-Host "[SUCCESS] All 10 JeffInTech IAM groups exist."
}
else {

    Write-Host "[WARNING] Expected 10 groups but found $($Results.Count)."
}


Write-Host ""
Write-Host "Script completed."
Write-Host ""
