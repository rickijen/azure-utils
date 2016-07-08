$pipName = "newubuntupip"
$rgName = "newrg"
$location = "westus"
$subnet1Name = "newubuntusubnet01"
$vnetSubnetAddressPrefix = "10.2.0.0/24"
$vnetName = "newvnet01"
$vnetAddressPrefix = "10.2.0.0/16"


$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id


#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential

#Get the storage account where the captured image is stored
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName newrg09376

#Set the VM name and size
$vmConfig = New-AzureRmVMConfig -Name newubuntu01 -VMSize "Standard_DS1_v2"

#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -ComputerName newubuntu01 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskName = "newubuntuOsDisk"
$vmName = "newubuntu01"

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

$urlOfCapturedImageVhd = "https://newrg09376.blob.core.windows.net/vhds/generalizedubuntu-osDisk.401d8e43-ec18-4da7-825e-66a6147a97a5.vhd"

#Configure the OS disk to be created from image (-CreateOption fromImage) and give the URL of the captured image VHD for the -SourceImageUri parameter.
#We found this URL in the local JSON template in the previous sections.
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $urlOfCapturedImageVhd -Linux

#Create the new VM



