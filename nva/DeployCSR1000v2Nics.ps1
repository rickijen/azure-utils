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
$tgPublicSubnetName = "public"
$tgVNet = Get-AzureRmVirtualNetwork -Name $tgvirtualNetworkName -ResourceGroupName $tgresourceGroupName

#
# CSR environment (the resource group contains the CSR resources: VM, SA, NICs, NSG, UDR, etc.)
# #Get-AzureRmVMImageSku -Location westus -PublisherName cisco -Offer cisco-csr-1000v
#
$rgCSR = "rg-uw-network-csr-nonprod"
$location = "West US"
$rgAS = "rg-uw-network-csr-nonprod"
$avSetName = "as-uw-network-csr-nonprod"
$machineName = "UWNETCSRNP01"
$storageAccountname = "asuwvmnetcsr01nonprod"
$routeTableName = "vnet-uw-public-nonprod-CSR-RouteTable"
$routeTableCfgName = "Route-To-CSR"
$onPremPrefix = "10.200.8.0/21"
# Size and Sku
$vmSize = "Standard_D2_v2"
$imagePublisher = "cisco"
$imageOffer = "cisco-csr-1000v"
$Sku = "16_5"


# Create new resource group for CSR
New-AzureRmResourceGroup -Name $rgCSR -Location $location

# Make sure Availability set is created
$avSet=New-AzureRmAvailabilitySet -ResourceGroupName $rgAS -Name $avSetName -Location $location

# Create static public IP for CSR
$publicIpAddress = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rgCSR -AllocationMethod Static `
    -Name $machineName"-public-ip01" -Location $location `
    -DomainNameLabel $machineName.ToLower()

#
# Create 2 NICs and attach to the subnets
#
$tgSubnet = $tgVNet.Subnets | Where-Object Name -eq $tgSubnetName
$tgPublicSubnet = $tgVNet.Subnets | Where-Object Name -eq $tgPublicSubnetName

$nic0 = New-AzureRmNetworkInterface `
    -Name $machineName"-Nic0" -ResourceGroupName $rgCSR `
    -Location $location -SubnetId $tgPublicSubnet.Id `
    -EnableIPForwarding `
    -PublicIpAddressId $publicIpAddress.Id
$nic1 = New-AzureRmNetworkInterface `
    -Name $machineName"-Nic1" -ResourceGroupName $rgCSR `
    -Location $location -SubnetId $tgSubnet.Id `
    -EnableIPForwarding

# Create Storage account for CSR
$storageAccount = New-AzureRmStorageAccount `
    -ResourceGroupName $rgCSR -SkuName Standard_LRS `
    -Name $storageAccountname -Location $location

# Prepare OS Disk URI
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $machineName.ToLower() + "OSDisk" + ".vhd"

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
$NSG=New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgCSR -Location $location -Name $machineName"-SecurityGroup"

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
    -AddressPrefix $onPremPrefix `
    -NextHopType VirtualAppliance `
    -NextHopIpAddress $nic1.IpConfigurations.PrivateIpAddress `
    | Set-AzureRmRouteTable

#Associate UDR to the correct subnet
$Subnet = $tgVNet.Subnets | Where-Object Name -eq $tgSubnetName
Set-AzureRmVirtualNetworkSubnetConfig `
    -VirtualNetwork $tgVNet -Name $tgSubnetName `
    -AddressPrefix $Subnet.AddressPrefix -RouteTableId $routeTable.Id `
    | Set-AzureRmVirtualNetwork
