#
# Set Credentials for Azure login
#

# Generate password file
#$credential = Get-Credential
#$credential.Password | ConvertFrom-SecureString | Set-Content C:\Users\rijen\azure-utils\startup\azpassword.txt

$installedPasswordFile = "C:\Users\rijen\azure-utils\startup\azpassword.txt"
$packagedPasswordFile = Join-Path (Split-Path $profile) azpassword.txt

If (Test-Path $installedPasswordFile){
    # // File exists
    $passwordFile = $installedPasswordFile
} Else {
    Write-Output "Use packaged password"
    $passwordFile = $packagedPasswordFile
}

$azUser = "coadmin@rickijengmail.onmicrosoft.com"
$azPassword = Get-Content $passwordFile | ConvertTo-SecureString
$azCredential = New-Object System.Management.Automation.PSCredential $azUser,$azPassword

Write-Output "Add ARM account"
Add-AzureRmAccount -Credential $azCredential

Write-Output "Add ASM account"
Add-AzureAccount -Credential $azCredential

