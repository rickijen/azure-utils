# Create a Windows Server 2016 Nano Server VM in Azure
# http://www.thomasmaurer.ch/2016/11/how-to-deploy-nano-server-in-azure/
# https://blogs.technet.microsoft.com/nanoserver/2016/10/12/nano-server-in-the-azure-gallery-and-vm-agent-support/
# https://raw.githubusercontent.com/Microsoft/DockerTools/master/ConfigureWindowsDockerHost.ps1


# Prerequisites
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Import-Module .\NanoServerAzureHelper.psm1

# New-NanoServerAzureVM -Location westus –VMName "rbnano02" -AdminUsername "weswes" -VaultName "rb01keyvault" -ResourceGroupName "testrg001" -Verbose
# C:\Users\rijen> Enter-PSSession -ConnectionUri "https://rbnano02.westus.cloudapp.azure.com:5986/WSMAN" -Credential "weswes"
# [rbnano02.westus.cloudapp.azure.com]: PS C:\Users\weswes\Documents>
