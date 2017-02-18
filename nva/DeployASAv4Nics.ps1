#
# Create a new Cisco ASAv VM in ARM
#

# Global variables
$machineName = "ASR-CiscoASAv-03"
$resourceGroupName = "WestASR-ARM"
$location = "West US"
$virtualNetworkName = "EpicorFailoverARM"
$avSetName="availSetASAv"
# Use Standard storage account, not Premium.
$storageAccountname = "epicorasrcasav"
$vmSize = "Standard_D3"
$imagePublisher = "cisco"
$imageOffer = "cisco-asav"
$Sku = "asav-azure-byol"

# existing resources
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create 1 new public IP & 4 nics
# 4 subnets for ASAv have to be created prior to running the following and the Subnet ID has to match
#
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel "asrasavpublicip"
$networkInterface0 = New-AzureRmNetworkInterface -Name "asav03NicMgmt" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[4].Id -PublicIpAddressId $publicIpAddress.Id
$networkInterface1 = New-AzureRmNetworkInterface -Name "asav03NicPublic" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[2].Id
$networkInterface2 = New-AzureRmNetworkInterface -Name "asav03NicApp" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[0].Id
$networkInterface3 = New-AzureRmNetworkInterface -Name "asav03NicInfra" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[1].Id

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + “vhds/” + $machineName + $diskName + “.vhd”

#Attach the VM to an Availability Set so it can be attached to Azure LB
$avSet=New-AzureRmAvailabilitySet -Name $avSetName -ResourceGroupName $resourceGroupName -Location $location

# New VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize -AvailabilitySetId $avSet.Id
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface1.Id
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface2.Id
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface3.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage

#$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $OSDiskUri -Caching ReadWrite -CreateOption attach 

# set the plan since it's a marketplace image
Set-AzureRmVMPlan -VM $virtualMachineConfig -Name $Sku -Product $imageOffer -Publisher $imagePublisher

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential -Message "Type the user name and password of the ASAv VM."

#Set the Windows operating system configuration and add the NIC
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName -Credential $cred

# Create the PAN VM
Write-Output "Creating $machineName ......"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig
