#
# Create a new Ubuntu VM with 2 Nics as NAT gateway
#

# Global variables
$machineName = "UbuntuNATGW"
$resourceGroupName = "technicolor"
$location = "West US"
$virtualNetworkName = "vnet001"
#$avSetName="availSetASAv"
# Use Standard storage account, not Premium.
$storageAccountname = "technicolorstorage"
$vmSize = "Standard_D3"
$imagePublisher = "Canonical"
$imageOffer = "UbuntuServer"
$Sku = "14.04.4-LTS"

# sample username & password
# agnadmin
# K8y738ggQ9930p

# existing resources
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create 1 new public IP & 2 nics
# 2 subnets for ASAv have to be created prior to running the following and the Subnet ID has to match
#
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Static -Name $machineName -Location $location -DomainNameLabel "ubuntunatgwpublicip"
$networkInterface0 = New-AzureRmNetworkInterface -Name "frontNic" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIpAddress.Id
$networkInterface1 = New-AzureRmNetworkInterface -Name "backNic" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[1].Id

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $machineName + $diskName + ".vhd"

# New VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface1.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage

#$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $OSDiskUri -Caching ReadWrite -CreateOption attach 

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential -Message "Type the user name and password of the NATGW VM."

#Set the Linux operating system configuration
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName -Credential $cred

# Create the PAN VM
Write-Output "Creating $machineName ......"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig
