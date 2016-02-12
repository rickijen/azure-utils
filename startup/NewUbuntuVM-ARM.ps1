#
# Create a new Ubuntu VM in ARM
#

# Global variables
$machineName = ‘rb02srv02’
$resourceGroupName = ‘rb02’
$location = ‘westus’
$virtualNetworkName = ‘rb02-vnet02’
$networkSecurityGroupName = ‘rb02-nsg02’
#$applicationServerAvailabilitySetName = ‘rb-availability-set’
$storageAccountname = ‘rb02storage’
$applicationServerSize = ‘Basic_A2’
$imagePublisher = ‘Canonical’
$imageOffer = ‘UbuntuServer’
$ubuntuOSSku = ‘14.04.3-LTS’
$adminUsername = ‘weswes’
$sshKeyPath = ‘/home/’ + $adminUsername + ‘/.ssh/authorized_keys’
$sshKeyData = [IO.File]::ReadAllText("C:\Users\rijen\rijen_public_key")

# New resource group and resources required to build a new VM
<#
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
New-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location
New-AzureRmNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Type Standard_LRS -Location $location -Name $storageAccountname
New-AzureRmAvailabilitySet -Name $applicationServerAvailabilitySetName -ResourceGroupName $resourceGroupName -Location $location
#>

# Virtual Network
$vnet=Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
if ($vnet -eq $null) {
    # Create a VNET with 2 Subnets and a GatewaySubnet
    $frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.2.1.0/24
    $backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.2.2.0/24
    $gwsubnet=New-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -AddressPrefix 10.2.0.0/28
    New-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.2.0.0/16 -Subnet $frontendSubnet,$backendSubnet,$gwsubnet
    
    $gwpip= New-AzureRmPublicIpAddress -Name vnet01gwpip1 -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic

    $vnet = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
    $gwsubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
    $gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name vnet02gwipconfig1 -SubnetId $gwsubnet.Id -PublicIpAddressId $gwpip.Id 
    New-AzureRmVirtualNetworkGateway -Name vnet02gw -ResourceGroupName $resourceGroupName -Location $location -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased
}

# existing resources
#$applicationServerAvailabilitySet = Get-AzureRmAvailabilitySet –Name $applicationServerAvailabilitySetName –ResourceGroupName $resourceGroupName
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create new resources
$subnetIndex=0 #frontend subnet
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel $machineName
$networkInterface = New-AzureRmNetworkInterface -Name $machineName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[$subnetIndex].Id -PublicIpAddressId $publicIpAddress.Id

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + “vhds/” + $machineName + $diskName + “.vhd”

# Prepare SSH keys
$sshPublicKey = [Microsoft.Azure.Management.Compute.Models.SshPublicKey]::new()
$sshPublicKey.KeyData = $sshKeyData
$sshPublicKey.Path = $sshKeyPath
$sshPublicKeyList = New-Object ‘System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.SshPublicKey]’
$sshPublicKeyList.Add($sshPublicKey)

# Create a new Linux osProfile object for configuration
$osProfile = [Microsoft.Azure.Management.Compute.Models.OsProfile]::new()
$osProfile.ComputerName = $machineName
$osProfile.AdminUsername = $adminUsername
$osProfile.LinuxConfiguration = [Microsoft.Azure.Management.Compute.Models.LinuxConfiguration]::new()
$osProfile.LinuxConfiguration.DisablePasswordAuthentication = $true
$osProfile.LinuxConfiguration.Ssh = [Microsoft.Azure.Management.Compute.Models.SshConfiguration]::new()
$osProfile.LinuxConfiguration.Ssh.PublicKeys = $sshPublicKeyList

# New VM config
#$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $applicationServerSize -AvailabilitySetId $applicationServerAvailabilitySet.Id
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $applicationServerSize
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $ubuntuOSSku -Version “latest”
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage
$virtualMachineConfig.OSProfile = $osProfile

# Create the VM
Write-Output "`nCreateing $machineName ......`n"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig