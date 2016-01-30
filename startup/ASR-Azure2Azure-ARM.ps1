#
# Set up ASR to protect Azure VMs
#

# Register the services for SiteRecovery and RecoveryServices
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.SiteRecovery
Register-AzureRmProviderFeature -FeatureName betaAccess -ProviderNamespace Microsoft.RecoveryServices

# New Recovery Services Vault
$vault = New-AzureRmRecoveryServicesVault -Name redondo2-asr-vault -ResouceGroupName redondo2 -Location westus

# Download settings file from Recovery Services Vault
$Path = 'C:\Users\rijen\Downloads\'
Get-AzureRmRecoveryServicesVaultSettingsFile -Vault $vault -Path $Path

# Import settings file into Site Recovery Vault
Import-AzureRmSiteRecoveryVaultSettingsFile -Path C:\Users\rijen\Downloads\redondo2-asr-vault_2016-01-30T00-14-08.VaultCredentials

# New ASR site
$sitename = "Redondo2-asr-site"                #Specify site friendly name
New-AzureRmSiteRecoverySite -Name $sitename

# Make sure the job is done
# Get-AzureRmSiteRecoveryJob

$SiteIdentifier = Get-AzureRmSiteRecoverySite -Name $sitename | Select -ExpandProperty SiteIdentifier
Get-AzureRmRecoveryServicesVaultSettingsFile -Vault $vault -SiteIdentifier $SiteIdentifier -SiteFriendlyName $sitename -Path $Path

#
# Download and install the Azure Site Recovery Provider and Azure Recovery Services Agent on your Hyper-V host
#
#http://download.microsoft.com/download/E/F/A/EFAE1CB6-8140-4352-8F87-7677B9AD004A/AzureSiteRecoveryProvider.exe

