#Variables

## Global
$baseName = "CiscoCSR1000V"
$rgName = "CiscoCSR1000V-RG"
$locationName = "West US"
$publisherName = "cisco"
$offerName = "cisco-csr-1000v"
$sku = "csr-azure-byol"

## Storage
$storageName = "ciscocrs1000v"
$storageType = "Standard_LRS"

## Network
$interfaceName1 = $baseName + "-interface1"
$vNetName = $baseName +"-VNet"
$VNetAddressPrefix = "10.16.0.0/16"
$VNetSubnet1AddressPrefix = "10.16.0.0/24"
$VNetSubnet2AddressPrefix = "10.16.1.0/24"
$subnet1Name = "DMZ"
$subnet2Name = "FrontEnd"

## Compute
$vmName = $baseName
$computerName = $baseName
$vmSize = "Standard_D2"

# Get credentials.
$credential = Get-Credential

# Resource Group
New-AzureResourceGroup -Name $rgName -Location $locationName

# Storage
$storageAccount = New-AzureStorageAccount -ResourceGroupName $rgName -Name $storageName -Type $storageType -Location $locationName

# Network
$pIp = New-AzurePublicIpAddress -Name $interfaceName1 -ResourceGroupName $rgName -Location $locationName -AllocationMethod Dynamic
$frontendName = $baseName + '-frontend'
$frontEnd = New-AzureLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $pIp
$backendAddressPoolName = $baseName + '-backend'
$backendAddressPool = New-AzureLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
$lbName = $baseName + '-lb'

$inboundNatRule1 = New-AzureLoadBalancerInboundNatRuleConfig -Name "SSH" `
   -FrontendIpConfiguration $frontEnd `
   -Protocol TCP -FrontendPort 22 -BackendPort 22

$lbHTTPRule = New-AzureLoadBalancerRuleConfig -Name "HTTP" `
   -FrontendIpConfiguration $frontEnd -BackendAddressPool $backendAddressPool `
   -Protocol Tcp -FrontendPort 80 -BackendPort 80

$lb = New-AzureLoadBalancer -Name $lbName -ResourceGroupName $rgName -Location $locationName -FrontendIpConfiguration $frontend `
    -InboundNatRule $inboundNatRule1 `
    -BackendAddressPool $backendAddressPool `
    -LoadBalancingRule $lbHTTPRule

# VNet
$subnet1Config = New-AzureVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnet1AddressPrefix
$subnet2Config = New-AzureVirtualNetworkSubnetConfig -Name $Subnet2Name -AddressPrefix $VNetSubnet2AddressPrefix

$subnets = @($subnet1Config, $subnet2Config)

$vNet = New-AzureVirtualNetwork -Name $VNetName -ResourceGroupName $rgName -Location $locationName -AddressPrefix $VNetAddressPrefix -Subnet $subnets

$nic1 = New-AzureNetworkInterface -Name "$baseName-nic1" -ResourceGroupName $rgName -Location $locationName -Subnet $vnet.Subnets[0] `
    -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] `
    -LoadBalancerInboundNatRule $lb.InboundNatRules[0]

$nic2 = New-AzureNetworkInterface -Name "$baseName-nic2" -ResourceGroupName $rgName -Location $locationName `
    -SubnetId $vnet.Subnets[1].Id

## Setup local VM Object
$vmConfig = New-AzureVMConfig -VMName $vmName -VMSize $vmSize

$vmConfig = Set-AzureVMOperatingSystem -VM $vmConfig -Linux -ComputerName $computerName -Credential $credential
$vmConfig = Set-AzureVMSourceImage -VM $vmConfig -PublisherName "cisco" -Offer "cisco-csr-1000v" -Skus "csr-azure-byol" -Version "latest"

$vmConfig = Add-AzureVMNetworkInterface -VM $vmConfig -Id $nic1.Id -Primary
$vmConfig = Add-AzureVMNetworkInterface -VM $vmConfig -Id $nic2.Id

$OSDiskName = $vmConfig.Name + "osDisk"
$OSDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$vmConfig = Set-AzureVMOSDisk -VM $vmConfig -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption fromImage

## Create the VM in Azure
New-AzureVM -ResourceGroupName $rgName -Location $locationName -VM $vmConfig
