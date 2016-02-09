#
# Create a new Centos VM in ARM
#

# Global variables
$machineName = ‘redondomc’
$resourceGroupName = ‘redondo2’
$location = ‘westus’
$virtualNetworkName = ‘redondo2-vnet’
$networkSecurityGroupName = ‘redondo2-nsg’
$applicationServerAvailabilitySetName = ‘mc-availability-set’
$storageAccountname = ‘redondostoragewest’
$applicationServerSize = ‘Basic_A2’
$imagePublisher = ‘openlogic’
$imageOffer = ‘centos’
$ubuntuOSSku = ‘6.7’
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
    # Create a VNET with 2 Subnets
    $frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24
    $backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24
    New-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $frontendSubnet,$backendSubnet
}

# existing resources
$applicationServerSecurityGroup = Get-AzureRmNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName
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