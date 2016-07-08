#
# Create a new Palo Alto VM in ARM
#

# Global variables
$machineName = "pan003"
$resourceGroupName = "newrg"
$location = "westus"
$virtualNetworkName = "newrgvnet"
# Use Standard storage account, not Premium.
$storageAccountname = "clisto3323197029newrgvm0"
$vmSize = "Standard_D3"
$imagePublisher = "paloaltonetworks"
$imageOffer = "vmseries1"
$Sku = "byol"

# sample username & password
# agnadmin
# K8y738ggQ9930p

# existing resources
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountname

# create 1 new public IP & 3 new nics
# 3 subnets for PAN have to be created prior to running the following and the Subnet ID has to match
#
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -AllocationMethod Dynamic -Name $machineName -Location $location -DomainNameLabel $machineName
$networkInterface0 = New-AzureRmNetworkInterface -Name "pan003NicMgmt" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[2].Id -PublicIpAddressId $publicIpAddress.Id
$networkInterface1 = New-AzureRmNetworkInterface -Name "pan003NicDmz" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[3].Id
$networkInterface2 = New-AzureRmNetworkInterface -Name "pan003NicTrust" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $virtualNetwork.Subnets[4].Id

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + “vhds/” + $machineName + $diskName + “.vhd”

# New VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface1.Id
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $networkInterface2.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage

# set the plan since it's a marketplace image
Set-AzureRmVMPlan -VM $virtualMachineConfig -Name $Sku -Product $imageOffer -Publisher $imagePublisher

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential -Message "Type the user name and password of the PAN (Linux) VM."

#Set the Windows operating system configuration and add the NIC
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName -Credential $cred

# Create the PAN VM
Write-Output "Createing $machineName ......"
New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $virtualMachineConfig
