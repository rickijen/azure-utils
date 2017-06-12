#
# Create a new Cisco CSR1000v with 2 NICs in a new resource group and attach NICs to target resource group
#

#

#
# Target environment (prod or non-prod resource groups)
#
$tgresourceGroupName = "ASM-POC"
$tglocation = "West US"
$tgvirtualNetworkName = "VNet-NonProd"

# Target VNet (prod or non-prod vnet)
$tgVNet = Get-AzureRmVirtualNetwork -Name $tgvirtualNetworkName -ResourceGroupName $tgresourceGroupName

#
# CSR environment (the resource group contains the CSR resources: VM, SA, NICs, NSG, UDR, etc.)
# #Get-AzureRmVMImageSku -Location westus -PublisherName cisco -Offer cisco-csr-1000v
#
$rgCSR="csrv05"
$location="West US"
$avSetName="as-uw-network-csr-prod"
$machineName = "UWNETCSRP01"
$storageAccountname = "sacsrv05"
$storageAccounSkuName = "Standard_LRS"
$vmSize = "Standard_D2_v2"
$imagePublisher = "cisco"
$imageOffer = "cisco-csr-1000v"
$Sku = "16_5"
$NSGName="DefaultNSG"
$routeTableName="Frontend-Route-Table"
$routeTableCfgName="Route-To-DMVPN"

# Create new resource group for CSR
New-AzureRmResourceGroup -Name $rgCSR -Location $location

# Make sure Availability set is created
$avSet=New-AzureRmAvailabilitySet -ResourceGroupName $rgCSR -Name $avSetName -Location $location

# Create static public IP for CSR
$publicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $rgCSR -AllocationMethod Static -Name $machineName -Location $location -DomainNameLabel $machineName

# Create 2 NICs
# Confirm the Subnet Index (by printing $tgVNet) first before executing the following
$nic0 = New-AzureRmNetworkInterface -Name "Nic-0" -ResourceGroupName $rgCSR -Location $location -SubnetId $tgVNet.Subnets[2].Id -EnableIPForwarding -PublicIpAddressId $publicIpAddress.Id
$nic1 = New-AzureRmNetworkInterface -Name "Nic-1" -ResourceGroupName $rgCSR -Location $location -SubnetId $tgVNet.Subnets[0].Id -EnableIPForwarding

# Create Storage account for CSR
$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $rgCSR -SkuName Standard_LRS -Name $storageAccountname -Location $location

# Prepare OS Disk
$diskName="OSDisk"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $machineName + $diskName + ".vhd"

# New CSR VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize -AvailabilitySetId $avSet.Id
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $nic0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $nic1.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption fromImage

# Set the VM plan since CSR is a marketplace image
Set-AzureRmVMPlan -VM $virtualMachineConfig -Name $Sku -Product $imageOffer -Publisher $imagePublisher

#Enter a new user name and password in the pop-up for the following
$cred = Get-Credential -Message "Type the user name and password of $machineName"

#Set the operating system configuration
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName -Credential $cred

#
# Create the CSR VM
#
Write-Output "Creating $machineName ......"
New-AzureRmVM -ResourceGroupName $rgCSR -Location $location -VM $virtualMachineConfig

#
# Create NSG
# This is a standalone NSG, we will update with additional rules and associate to the CSR NIC
Write-Output "Creating NSG ......"
$NSG=New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgCSR -Location $location -Name $NSGName

$NSG | Add-AzureRmNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22 `
    | Set-AzureRmNetworkSecurityGroup
$NSG | Add-AzureRmNetworkSecurityRuleConfig -Name udp500-rule -Description "Allow UDP 500" `
    -Access Allow -Protocol Udp -Direction Inbound -Priority 101 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 500 `
    | Set-AzureRmNetworkSecurityGroup
$NSG | Add-AzureRmNetworkSecurityRuleConfig -Name udp4500-rule -Description "Allow UDP 4500" `
    -Access Allow -Protocol Udp -Direction Inbound -Priority 111 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 4500 `
    | Set-AzureRmNetworkSecurityGroup

#
# Create Route Table
# This is a standalone UDR route table, we will update with additional routes and associate to the correct subnet
$routeTable = New-AzureRmRouteTable -ResourceGroupName $rgCSR -Name $routeTableName -Location $location
$routeTable | Add-AzureRmRouteConfig `
    -Name $routeTableCfgName `
    -AddressPrefix "10.0.0.0/8" `
    -NextHopType VirtualAppliance `
    -NextHopIpAddress "192.168.0.101" `
    | Set-AzureRmRouteTable
