# Connect-EntraGraph.ps1
# Purpose: Establish Microsoft Graph connectivity for the Apex IAM automation project.
# Install and connect to the Microsoft Graph PowerShell module

Get-ExecutionPolicy
#EXPLANATION: Displays the current PowerShell script execution policy (e.g., Restricted, RemoteSigned, Bypass). This determines what types of scripts are allowed to run.

Set-ExecutionPolicy -ExecutionPolicy Bypass
#EXPLANATION: Temporarily sets the script execution policy to Bypass, allowing all scripts to run without prompts or warnings.

Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
#EXPLANATION: Installs the base Microsoft Graph PowerShell module for the current user from the PowerShell Gallery, forcing installation even if already present.

Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
#EXPLANATION: Installs the Microsoft.Graph.Users module, which includes cmdlets for managing user accounts, scoped to the current user.

Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.ReadWrite.All"
#EXPLANATION: Connects to Microsoft Graph with delegated permissions to read/write both users and groups.

Disconnect-MgGraph
#Completely disconnect from Microsoft Graph Then close the PowerShell window completely. Open a brand-new PowerShell window.

$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# Explicitly specifying the tenant so Graph doesn't accidentally authenticate against another Microsoft account or tenant.

$Scopes = @(
    "User.Read.All",
    "User.ReadWrite.All",
    "User-LifeCycleInfo.ReadWrite.All",
    "Group.ReadWrite.All"
)

Connect-MgGraph `
    -TenantId $TenantId `
    -Scopes $Scopes `
    -ContextScope Process `
    -UseDeviceCode

#-UseDeviceCode - This gives us a clean authentication path instead of relying on a cached browser/WAM session. Microsoft supports device-code authentication directly with Connect-MgGraph.
# You'll see something similar to:
# To sign in, use a web browser to open
#  https://microsoft.com/devicelogin
# and enter the code XXXXXXXX

Invoke-MgGraphRequest `
    -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/me?`$select=id,displayName,userPrincipalName"
# First, test your own Graph identity:

Connect-MgGraph -Scopes "Organization.Read.All", "Group.ReadWrite.All", "User.ReadWrite.All" -TenantID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" 
# EXPLANATION: Connects to Microsoft Graph with permissions to read/write across the entire organization.       

Get-MgUser -All
# EXPLANATION: Retrieves a list of all user accounts in Microsoft Entra ID (formerly Azure AD).

New-MgUser -AccountEnabled:$true -DisplayName "Justin Blakely" -MailNickname "justinblakely" -UserPrincipalName "justinblakely@examlabpractice.com" -PasswordProfile @{ ForceChangePasswordNextSignIn = $true; Password = "P@ssword123!" }
#EXPLANATION: Creates a new Entra ID user with the specified display name, login details, and a temporary password that must be changed at first sign-in.

Remove-MgUser -UserId (Get-MgUser -Filter "userPrincipalName eq 'justinblakely@jeffintech.com'").Id -Confirm:$false
#EXPLANATION: Delete the user named Justin Blakeyly

Create a users.csv file:

DisplayName, MailNickname, UserPrincipalName
Justin Blakely,justinblakely,justinblakely@examlabpractice.com
Sarah Lee,sarahlee,sarah.lee@examlabpractice.com
Robert Kim,robertkim,robert.kim@examlabpractice.com
EXPLANATION: Creates a CSV file with user info to be used in bulk user creation.

$PasswordProfile = @{ Password = "P@ssword123!"; ForceChangePasswordNextSignIn = $true }
#EXPLANATION: Defines a password profile for new users, requiring them to change their password at next sign-in.

Import-Csv -Path ".\users.csv" | ForEach-Object { New-MgUser -AccountEnabled:$true -DisplayName $_.DisplayName -MailNickname $_.MailNickname -UserPrincipalName $_.UserPrincipalName -PasswordProfile $PasswordProfile }
#EXPLANATION: Reads the users.csv file and creates a new user for each row using the shared password profile.

Import-Csv -Path ".\users.csv" | ForEach-Object { $user = Get-MgUser -Filter "userPrincipalName eq '$($_.UserPrincipalName)'"; if ($user) { Remove-MgUser -UserId $user.Id -Confirm:$false } }
#EXPLANATION: Reads the users.csv file and deletes each user listed if they exist, skipping confirmation prompts.

Get-MgSubscribedSku
#EXPLANATION: Lists all the license SKUs available in your tenant, including ID and usage data.

Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId, ConsumedUnits, PrepaidUnits
#EXPLANATION: Displays only key fields (SKU name, ID, number used, and number purchased) from the license list.

Set-MgUserLicense -UserId "justinblakely@examlabpractice.com" -AddLicenses @{SkuId = "06ebc4ee-1bb5-47dd-8120-11324bc54e06"} -RemoveLicenses @()
#EXPLANATION: Assigns a Microsoft 365 license to the specified user using the license’s SKU ID.

Set-MgUserLicense -UserId "jc@examlabpractice.com" -AddLicenses @{SkuId = "06ebc4ee-1bb5-47dd-8120-11324bc54e06"} -RemoveLicenses @()
#EXPLANATION: Same as above, but for a different user (jc@examlabpractice.com).

New-MgGroup -DisplayName "Test Group" -MailEnabled:$true -MailNickname "testgroup" -SecurityEnabled:$false -GroupTypes @("Unified")
#EXPLANATION: Creates a Microsoft 365 Group (not a security group) with mail capabilities and Teams/SharePoint integration.

New-MgGroupMemberByRef
#EXPLANATION: Adds a member to a group using a reference to the user's object ID (requires more parameters in practice).



# Verify all 25 JeffInTech identities
$JeffInTechUsers = Get-MgUser `
    -All `
    -Property Id,DisplayName,UserPrincipalName,Department,JobTitle,EmployeeId,EmployeeType

$JeffInTechUsers = $JeffInTechUsers |
    Where-Object {
        $_.UserPrincipalName -like "*@jeffintech.com"
    }

$JeffInTechUsers.Count
# Verify all 25 JeffInTech identities


#  display all identities cleanly
$JeffInTechUsers |
    Sort-Object EmployeeId |
    Select-Object `
        EmployeeId,
        DisplayName,
        UserPrincipalName,
        Department,
        JobTitle,
        EmployeeType |
    Format-Table -AutoSize
  #  display all identities cleanly

#Verify the identities before moving on
Get-MgUser `
    -All `
    -Property Id,DisplayName,UserPrincipalName,Department,JobTitle,EmployeeId,EmployeeType,EmployeeHireDate `
|
Where-Object {
    $_.UserPrincipalName -like "*@jeffintech.com"
} |
Select-Object `
    EmployeeId,
    DisplayName,
    UserPrincipalName,
    Department,
    JobTitle,
    EmployeeType,
    EmployeeHireDate |
Format-Table
#Verify the identities before moving on














  
