#
# Set Credentials for Azure Internal Consumption login
#

# Generate password file
#$credential = Get-Credential
#$credential.Password | ConvertFrom-SecureString | Set-Content C:\Users\rijen\azure-utils\startup\azmspassword.txt

$installedPasswordFile = "C:\Users\rijen\azure-utils\startup\azmspassword.txt"
$packagedPasswordFile = Join-Path (Split-Path $profile) azmspassword.txt

If (Test-Path $installedPasswordFile){
    # // File exists
    $passwordFile = $installedPasswordFile
} Else {
    Write-Output "Use packaged password"
    $passwordFile = $packagedPasswordFile
}

#$azUser = "redondojen@outlook.com"
$azUser = "rickijen@gmail.com"

$azPassword = Get-Content $passwordFile | ConvertTo-SecureString
$azCredential = New-Object System.Management.Automation.PSCredential $azUser,$azPassword

Write-Output "Add ARM account"
Add-AzureRmAccount -Credential $azCredential

Write-Output "Add ASM account"
Add-AzureAccount -Credential $azCredential

