#
# Create a new Ubuntu VM with existing vhd
#

# Global variables
$machineName = "rb02newminecraft"
$resourceGroupName = "redondo2"
$location = "West US"
$virtualNetworkName = "redondo2"
#$avSetName="availSetASAv"
# Use Standard storage account, not Premium.
$storageAccountname = "redondo29363"
$vmSize = "Standard_F1"
$imagePublisher = "Canonical"
$imageOffer = "UbuntuServer"
$Sku = "14.04.4-LTS"
$osDiskUri = "https://redondo29363.blob.core.windows.net/vhds/minecraftnew2016626201357.vhd"

# existing resources
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create 1 new public IP & 2 nics, each nic on a separate subnet
# 2 subnets for NAT GW have to be created prior to running the following and the Subnet ID has to match
#
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel "rbminecraftpublicip"
$networkInterface0 = New-AzureRmNetworkInterface -Name $machineName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIpAddress.Id

# Prepare OS Disk
# $diskName="OSDisk"
# $osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $machineName + $diskName + ".vhd"

# New VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize
#$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface0.Id -Primary
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption attach -Linux

#$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $OSDiskUri -Caching ReadWrite -CreateOption attach 

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential -Message "Type the user name and password of the NATGW VM."

#Set the Linux operating system configuration
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -ComputerName $machineName -Credential $cred

# Create the PAN VM
Write-Output "Creating $machineName ......"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig
