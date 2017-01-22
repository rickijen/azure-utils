Login-AzureRmAccount
Set-AzureRmContext -SubscriptionId 2e45430a-b715-4eb1-9bb0-3f9425ee2711

$rgName = "ISCALA-PROD"
$location = "West Europe"
$storageAccName = "iscala"
$vmName = "AZISCALAMOSAPT1"
# https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_F1s"
# Name of the disk that holds the OS
$osDiskName = "iScalaOSDisk"
$urlOfUploadedImageVhd = "https://iscala.blob.core.windows.net/vhds/iscalaimage.vhd"

# Get virtual network subnet settings
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName

# Create public IP and Nic
$ipName = "iScalaPublicIp"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic

$nicName = "iScalaNic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# Enter a new user name and password to use as the local administrator account for the remotely accessing the VM
$cred = Get-Credential

#Get the storage account where the uploaded image is stored
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName

#Set the VM name and size
#Use "Get-Help New-AzureRmVMConfig" to know the available options for -VMsize
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from the image (-CreateOption fromImage), and give the URL of the uploaded image VHD for the -SourceImageUri parameter
#You set this variable when you uploaded the VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfUploadedImageVhd -Windows

#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
