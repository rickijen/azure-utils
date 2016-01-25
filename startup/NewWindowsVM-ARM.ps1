#
# New Windows Server 2012 R2 Datacenter in ARM
#

# Global variables
$vmName="redondomcw"
$rgName="redondo2"
$locName="westus"
$saName="redondostoragewest"
$vnetName="redondo2-vnet"
$saName="redondostoragewest"
$saType="Standard_LRS"
$vmSize="Basic_A2"
$avName="mc-availability-set"

$testResult = Test-AzureRmDnsAvailability -DomainQualifiedName $vmName -Location $locName
if (!$testResult) {
    Write-Output "`n$vmName.$locName.cloudapp.azure.com is already in use.`n"
}

# Create new Load Balancer set
<#
#>

# Virtual Network
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
if ($vnet -eq $null) {
    # Create a VNET with 2 Subnets
    $frontendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix 10.0.1.0/24
    $backendSubnet=New-AzureRmVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix 10.0.2.0/24
    New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $frontendSubnet,$backendSubnet
}

# NIC & DNS name
$nicName=$vmName
$domName=$vmName
$subnetIndex=1 # backendSubnet
$pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id

# Availability Set
$avSet=Get-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName
if ($avSet -eq $null) {
    Write-Output "Create new Availability Set."
    New-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName -Location $locName
}

# Storage Account
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
if ($storageAcc -eq $null) {
    Write-Output "Create new Storage Account."
    New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName
}

# 
# Start VM config
#
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id

# Additional Data Disk
$diskSize=10
$diskName="DataDisk"
$diskLabel="mcDataDisk02"
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
Add-AzureRmVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI  -CreateOption empty

# Prepare OS Disk
$diskName="OSDisk"
$diskLabel="mcOSDisk02"
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskLabel -VhdUri $osDiskUri -CreateOption fromImage

# Prepare OS image
$pubName="MicrosoftWindowsServer"
$offerName="WindowsServer"
$skuName="2012-R2-Datacenter"
#$image=Get-AzureRmVMImage -Location $locName -Offer $offerName -PublisherName $pubName -Skus $skuName

# Specify the image and local administrator account, and then add the NIC
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Go!
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm



<#

# Set values for existing resource group and storage account names
$rgName="LOBServers"
$locName="West US"
$saName="contosolobserverssa"

# Set the existing virtual network and subnet index
$vnetName="AZDatacenter"
$subnetIndex=0
$vnet=Get-AzureRMVirtualNetwork -Name $vnetName -ResourceGroupName $rgName

# Create the NIC
$nicName="LOB07-NIC"
$domName="contoso-vm-lob07"
$pip=New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id

# Specify the name, size, and existing availability set
$vmName="LOB07"
$vmSize="Standard_A3"
$avName="WEB_AS"
$avSet=Get-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName
$vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avset.Id

# Add a 200 GB additional data disk
$diskSize=200
$diskLabel="APPStorage"
$diskName="21050529-DISK02"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
Add-AzureRmVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI -CreateOption empty

# Specify the image and local administrator account, and then add the NIC
$pubName="MicrosoftWindowsServer"
$offerName="WindowsServer"
$skuName="2012-R2-Datacenter"
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm

#>