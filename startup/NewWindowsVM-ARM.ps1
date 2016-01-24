#
# New Centos VM in ARM
#



# New Storage account
<#
$rgName="redondo"
$locName="South Central US"
$saName="redondostorage"
$saType="Standard_LRS"
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName
#>

$domName="redondomc2"
$loc="southcentralus"
Test-AzureRmDnsAvailability -DomainQualifiedName $domName -Location $loc

# New Availability set
<#
$avName="<availability set name>"
$rgName="<resource group name>"
$locName="<location name, such as West US>"
New-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName -Location $locName
#>

# Create new Load Balancer set
<#
#>

#Virtual Network with 2 subnets
<#
$rgName="redondo"
$locName="SouthCentralUS"
$frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24
$backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24
New-AzureRmVirtualNetwork -Name redondovnet -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $frontendSubnet,$backendSubnet
#>

$rgName="redondo"
$locName="southcentralus"
$saName="redondostorage"
$vnetName="redondovnet"
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName | Select Subnets

# NIC & DNS name
$nicName="mc-nic0"
$domName="redondomc"
$subnetIndex=0
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id

# Get VM Size
<#
$locName="southcentralus"
Get-AzureRmVMSize -Location $locName | Select Name
#>

$vmName="redondomc2"
$vmSize="Basic_A2"
$avName="mc-availability-set"
$avSet=Get-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName

#Start VM config
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id

# Additional Disk
$diskSize=1
$diskLabel="mcDataDisk01"
$diskName="20160123-DISK01"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
Add-AzureRmVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI  -CreateOption empty

#$image=Get-AzureRmVMImage -Location "south central US" -Offer "centos" -PublisherName "openlogic" -Skus "6.7"

$pubName="openlogic"
$offerName="centos"
$skuName="6.7"

$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $vhdURI -CreateOption fromImage

# Go!
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm
