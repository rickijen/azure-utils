# names
$machineName = ‘redondomc’

# New resource group and resources required to build a new VM
<#
New-AzureRmResourceGroup -Name redondo2 -Location westus
New-AzureRmNetworkSecurityGroup -Name redondo2-nsg -ResourceGroupName redondo2 -Location westus
New-AzureRmStorageAccount -ResourceGroupName redondo2 -Type Standard_LRS -Location westus -Name redondostoragewest
New-AzureRmAvailabilitySet -Name mc-availability-set -ResourceGroupName redondo2 -Location westus
#>

#Virtual Network with 2 subnets
<#
$resourceGroupName="redondo2"
$location="westus"
$virtualNetworkName = ‘redondo2-vnet’
$frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24
$backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24
New-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $frontendSubnet,$backendSubnet
#>

$resourceGroupName = ‘redondo2’
$virtualNetworkName = ‘redondo2-vnet’
$networkSecurityGroupName = ‘redondo2-nsg’
$applicationServerAvailabilitySetName = ‘mc-availability-set’
$storageAccountname = ‘redondostoragewest’

# variables
$location = ‘westus’
$applicationServerSize = ‘Basic_A2’
$imagePublisher = ‘openlogic’
$imageOffer = ‘centos’
$ubuntuOSSku = ‘6.7’
$adminUsername = ‘weswes’
$sshKeyPath = ‘/home/’ + $adminUsername + ‘/.ssh/authorized_keys’
$sshKeyData = [IO.File]::ReadAllText("C:\Users\rijen\rijen_public_key")

# existing resources
$applicationServerSecurityGroup = Get-AzureRmNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName
$applicationServerAvailabilitySet = Get-AzureRmAvailabilitySet –Name $applicationServerAvailabilitySetName –ResourceGroupName $resourceGroupName
$virtualNetwork = $virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# NIC & DNS name
<#
$nicName="mc-nic0"
$domName="redondomc"
$subnetIndex=0
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id
#>

# create new resources
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel $machineName
$networkInterface = New-AzureRmNetworkInterface -Name $machineName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[$subnetIndex].Id -PublicIpAddressId $publicIpAddress.Id
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + “vhds/” + $machineName + “.vhd”

$sshPublicKey = [Microsoft.Azure.Management.Compute.Models.SshPublicKey]::new()
$sshPublicKey.KeyData = $sshKeyData
$sshPublicKey.Path = $sshKeyPath
$sshPublicKeyList = New-Object ‘System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.SshPublicKey]’
$sshPublicKeyList.Add($sshPublicKey)

$osProfile = [Microsoft.Azure.Management.Compute.Models.OsProfile]::new()
$osProfile.ComputerName = $machineName
$osProfile.AdminUsername = $adminUsername
$osProfile.LinuxConfiguration = [Microsoft.Azure.Management.Compute.Models.LinuxConfiguration]::new()
$osProfile.LinuxConfiguration.DisablePasswordAuthentication = $true
$osProfile.LinuxConfiguration.Ssh = [Microsoft.Azure.Management.Compute.Models.SshConfiguration]::new()
$osProfile.LinuxConfiguration.Ssh.PublicKeys = $sshPublicKeyList

$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $applicationServerSize -AvailabilitySetId $applicationServerAvailabilitySet.Id
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $ubuntuOSSku -Version “latest”
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage
$virtualMachineConfig.OSProfile = $osProfile

# Specify the OS disk name and create the VM
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig