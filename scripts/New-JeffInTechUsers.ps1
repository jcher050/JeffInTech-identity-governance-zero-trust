# ============================================================
# New-JeffInTechUsers.ps1
#
# Purpose:
# Create and update fictional JeffInTech users from the
# HR source-of-truth CSV using Microsoft Graph PowerShell.
# ============================================================

Import-Module Microsoft.Graph.Users

$CsvPath = "../SC-300/hr-users-sample.csv"

$Users = Import-Csv $CsvPath

function New-JeffInTechTemporaryPassword {

    $bytes = New-Object byte[] 18

    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)

    $randomValue =
        [Convert]::ToBase64String($bytes) -replace '[^a-zA-Z0-9]', 'x'

    return "Jt!9$($randomValue.Substring(0,16))"
}


Write-Host "Starting JeffInTech identity provisioning..."

foreach ($User in $Users) {

    Write-Host "Processing $($User.displayName)..."

    # --------------------------------------------------------
    # Look for existing account
    # --------------------------------------------------------

    $ExistingUser = Get-MgUser `
        -Filter "userPrincipalName eq '$($User.UPN)'" `
        -Property Id,DisplayName,UserPrincipalName

    if (-not $ExistingUser) {

        $TemporaryPassword = New-JeffInTechTemporaryPassword

        $PasswordProfile = @{
            Password = $TemporaryPassword
            ForceChangePasswordNextSignIn = $true
        }

        $NewUserParameters = @{
            AccountEnabled    = $true
            DisplayName       = $User.displayName
            GivenName         = $User.givenName
            Surname           = $User.surname
            UserPrincipalName = $User.UPN
            MailNickname      = ($User.UPN.Split("@")[0])
            PasswordProfile   = $PasswordProfile
        }

        $CreatedUser = New-MgUser @NewUserParameters

        Write-Host "Created $($User.UPN)"

        $UserId = $CreatedUser.Id
    }
    else {

        Write-Host "$($User.UPN) already exists. Updating attributes."

        $UserId = $ExistingUser.Id
    }


    # --------------------------------------------------------
    # Populate HR / identity attributes
    # --------------------------------------------------------

    $UpdateParameters = @{
        department       = $User.department
        jobTitle         = $User.jobTitle
        usageLocation    = $User.usageLocation
        employeeId       = $User.employeeId
        employeeType     = $User.employeeType
        companyName      = $User.companyName
        employeeHireDate = $User.employeeHireDate
    }

    Update-MgUser `
        -UserId $UserId `
        -BodyParameter $UpdateParameters


    # --------------------------------------------------------
    # Populate leave date only when present
    # --------------------------------------------------------

    if (-not [string]::IsNullOrWhiteSpace($User.employeeLeaveDateTime)) {

        Update-MgUser `
            -UserId $UserId `
            -EmployeeLeaveDateTime $User.employeeLeaveDateTime

        Write-Host "Leave date configured for $($User.UPN)"
    }
}


# ============================================================
# SECOND PASS: Assign managers
#
# Managers must already exist before their relationship can
# be assigned. This is why manager assignment occurs after
# all users have been created.
# ============================================================

Write-Host "Assigning managers..."

foreach ($User in $Users) {

    if (-not [string]::IsNullOrWhiteSpace($User.manager)) {

        $Employee =
            Get-MgUser `
                -UserId $User.UPN `
                -Property Id,UserPrincipalName

        $Manager =
            Get-MgUser `
                -UserId $User.manager `
                -Property Id,UserPrincipalName

        $ManagerReference = @{
            "@odata.id" =
            "https://graph.microsoft.com/v1.0/users/$($Manager.Id)"
        }

        Set-MgUserManagerByRef `
            -UserId $Employee.Id `
            -BodyParameter $ManagerReference

        Write-Host "$($User.displayName) -> Manager: $($User.manager)"
    }
}


Write-Host "JeffInTech user provisioning complete."
