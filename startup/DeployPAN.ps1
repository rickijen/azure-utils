#
# Create a new Ubuntu VM in ARM
#

# Global variables
$machineName = 'pan001’
$resourceGroupName = ‘targetRg001’
$location = ‘westus’
$virtualNetworkName = ‘prodVnet001’
$storageAccountname = ‘prodstorage001’
$applicationServerSize = ‘Standard_D3’
$imagePublisher = ‘paloaltonetworks’
$imageOffer = ‘vmseries1’
$Sku = ‘byol’
$adminUsername = ‘agnadmin’
$adminPassword = 'K8y738ggQ9930p'

# existing resources
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create new nics
# 3 subnets for PAN have to be created prior to running the following and the Subnet ID has to match
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel $machineName
$networkInterface0 = New-AzureRmNetworkInterface -Name 'panNicMgmt' -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[2].Id -PublicIpAddressId $publicIpAddress.Id
$networkInterface1 = New-AzureRmNetworkInterface -Name 'panNicDmz' -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[3].Id
$networkInterface2 = New-AzureRmNetworkInterface -Name 'panNicTrust' -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[4].Id

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + “vhds/” + $machineName + $diskName + “.vhd”

# Create a new Linux osProfile object for configuration
$osProfile = [Microsoft.Azure.Management.Compute.Models.OsProfile]::new()
$osProfile.ComputerName = $machineName
$osProfile.AdminUsername = $adminUsername
$osProfile.AdminPassword = $adminPassword
$osProfile.LinuxConfiguration = [Microsoft.Azure.Management.Compute.Models.LinuxConfiguration]::new()
$osProfile.LinuxConfiguration.DisablePasswordAuthentication = $false
$osProfile.LinuxConfiguration.Ssh = [Microsoft.Azure.Management.Compute.Models.SshConfiguration]::new()

# New VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $applicationServerSize
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version “latest”
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface1.Id
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface2.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage
# $virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName

Set-AzureRmVMPlan -VM $virtualMachineConfig -Name $Sku -Product $imageOffer -Publisher $imagePublisher

$virtualMachineConfig.OSProfile = $osProfile

# Create the VM
Write-Output "`nCreateing $machineName ......`n"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig
