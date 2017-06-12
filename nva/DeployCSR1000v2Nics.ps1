#
# Create a new Cisco CSR1000v with 2 NICs in a new resource group and attach NICs to target resource group
#

# Login to Azure
Login-AzureRmAccount

#
# Target VNet & Subnet where we will attach the CSR NICs (in prod or non-prod resource groups)
#
$tgresourceGroupName = "ASM-POC"
$tgvirtualNetworkName = "VNet-NonProd"
$tgSubnetName = "frontend"
$tgVNet = Get-AzureRmVirtualNetwork -Name $tgvirtualNetworkName -ResourceGroupName $tgresourceGroupName

#
# CSR environment (the resource group contains the CSR resources: VM, SA, NICs, NSG, UDR, etc.)
# #Get-AzureRmVMImageSku -Location westus -PublisherName cisco -Offer cisco-csr-1000v
#
$rgCSR="csrv05"
$location="West US"
$avSetName="as-uw-network-csr-prod"
$machineName = "UWNETCSRP01"
$nic0name = "Nic-0"
$nic1name = "Nic-1"
$storageAccountname = "sacsrv05"
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
$publicIpAddress = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rgCSR `
    -AllocationMethod Static `
    -Name $machineName `
    -Location $location `
    -DomainNameLabel $machineName

# Create 2 NICs
# Confirm the Subnet Index (by printing $tgVNet) first before executing the following
$nic0 = New-AzureRmNetworkInterface `
    -Name $nic0name `
    -ResourceGroupName $rgCSR `
    -Location $location `
    -SubnetId $tgVNet.Subnets[2].Id `
    -EnableIPForwarding `
    -PublicIpAddressId $publicIpAddress.Id
$nic1 = New-AzureRmNetworkInterface `
    -Name $nic1name `
    -ResourceGroupName $rgCSR `
    -Location $location `
    -SubnetId $tgVNet.Subnets[0].Id `
    -EnableIPForwarding

# Create Storage account for CSR
$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $rgCSR -SkuName Standard_LRS -Name $storageAccountname -Location $location

# Prepare OS Disk URI
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $machineName + "OSDisk" + ".vhd"

# Construct CSR VM config
$virtualMachineConfig = New-AzureRmVMConfig -VMName $machineName -VMSize $vmSize -AvailabilitySetId $avSet.Id
$virtualMachineConfig = Set-AzureRmVMSourceImage -VM $virtualMachineConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $Sku -Version "latest"
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $nic0.Id -Primary
$virtualMachineConfig = Add-AzureRmVMNetworkInterface -VM $virtualMachineConfig -Id $nic1.Id
$virtualMachineConfig = Set-AzureRmVMOSDisk -VM $virtualMachineConfig -Name $machineName -VhdUri $osDiskUri -CreateOption FromImage

# Set the VM plan since CSR is a marketplace image
Set-AzureRmVMPlan -VM $virtualMachineConfig -Name $Sku -Product $imageOffer -Publisher $imagePublisher

# Enter user name and password in the pop-up window
$cred = Get-Credential -Message "user name and password of $machineName"

# Set operating system configuration
$virtualMachineConfig = Set-AzureRmVMOperatingSystem -VM $virtualMachineConfig -Linux -ComputerName $machineName -Credential $cred

#
# Create the CSR VM
#
Write-Output "Creating $machineName ......"
New-AzureRmVM -ResourceGroupName $rgCSR -Location $location -VM $virtualMachineConfig

#
# Create NSG
#
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

# Associate NSG to the first/primary NIC of CSR
$nic0.NetworkSecurityGroup = $NSG
Set-AzureRmNetworkInterface -NetworkInterface $nic0

#
# Create Route Table (UDR)
#
$routeTable = New-AzureRmRouteTable -ResourceGroupName $rgCSR -Name $routeTableName -Location $location
$routeTable | Add-AzureRmRouteConfig `
    -Name $routeTableCfgName `
    -AddressPrefix "10.0.0.0/8" `
    -NextHopType VirtualAppliance `
    -NextHopIpAddress "192.168.0.101" `
    | Set-AzureRmRouteTable

#Associate UDR to the correct subnet
$Subnet = $vnet.Subnets | Where-Object Name -eq $tgSubnetName
Set-AzureRmVirtualNetworkSubnetConfig `
    -VirtualNetwork $tgVNet `
    -Name $tgSubnetName `
    -AddressPrefix $Subnet.AddressPrefix `
    -RouteTableId $routeTable.Id `
    | Set-AzureRmVirtualNetwork
