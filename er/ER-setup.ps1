###  ExpressRouteFridays
###  Sample Code ONLY.
###  Authors: Ron Abellera & Ganesh Srinivasan
###  Public documentation at https://azure.microsoft.com/en-us/documentation/articles/expressroute-howto-circuit-arm/


##  Clean up registry - Optional
Get-PSRepository | Where –FilterScript {!$_.Name.Contains(“PSGallery”)} | Unregister-PSRepository


#Install the right modules for ER
Install-Module AzureRM -Force
Install-AzureRM


#Import Steps

Import-Module AzureRM
Import-Module AzureRM.Network

Login-AzureRmAccount

#Check versions
Get-Module
Get-InstalledModule

#Pick subscription to work with
Select-AzureRmSubscription -SubscriptionId "InsertYourSubscriptionIDhere123"

#Who What Where
Get-AzureRmExpressRouteServiceProvider

$provider = "AT&T"
$peeringlocation = "Silicon Valley"
$bandwidth = 50
$rg = “ExpressRouteResourceGroup”
$Location = "West US"

New-AzureRmResourceGroup -Name $rg -Location $Location

#Create ExpressRoute Circuit
New-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup" -Location "West US" -SkuTier Standard -SkuFamily MeteredData -ServiceProviderName "AT&T" -PeeringLocation "Silicon Valley" -BandwidthInMbps 50

$ckt = Get-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup"


$ckt.Sku.Tier = "Premium"
$ckt.sku.Name = "Premium_MeteredData"

Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

$ckt.Sku.Tier = "Standard"
$ckt.sku.Name = "Standard_MeteredData"

Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt


$ckt.Sku.Family = "MeteredData"
$ckt.sku.Name = "Premium_MeteredData"

Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

$ckt.Sku.Tier = "Standard"
$ckt.sku.Name = "Standard_MeteredData"

$ckt.ServiceProviderProperties.BandwidthInMbps = 1000
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

### BGP Fun

# Azure Private Peering (IaaS)

Add-AzureRmExpressRouteCircuitPeeringConfig -Name "AzurePrivatePeering" -Circuit $ckt -PeeringType AzurePrivatePeering -PeerASN 100 -PrimaryPeerAddressPrefix "10.0.0.0/30" -SecondaryPeerAddressPrefix "10.0.0.4/30" -VlanId 200
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

$ckt = Get-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup"
Get-AzureRmExpressRouteCircuitPeeringConfig -Name "AzurePrivatePeering" -Circuit $ckt

# Azure Public Peering (PaaS)

Add-AzureRmExpressRouteCircuitPeeringConfig -Name "AzurePublicPeering" -Circuit $ckt -PeeringType AzurePublicPeering -PeerASN 100 -PrimaryPeerAddressPrefix "12.0.0.0/30" -SecondaryPeerAddressPrefix "12.0.0.4/30" -VlanId 100
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

$ckt = Get-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup"
Get-AzureRmExpressRouteCircuitPeeringConfig -Name "AzurePublicPeering" -Circuit $ckt

# Microsoft Peering (O365 and CRMOL)

Add-AzureRmExpressRouteCircuitPeeringConfig -Name "MicrosoftPeering" -Circuit $ckt -PeeringType MicrosoftPeering -PeerASN 100 -PrimaryPeerAddressPrefix "123.0.0.0/30" -SecondaryPeerAddressPrefix "123.0.0.4/30" -VlanId 300 -MircosoftConfigAdvertisedPublicPrefixes "123.1.0.0/24" -MircosoftConfigCustomerAsn 23 -MircosoftConfigRoutingRegistryName "ARIN"
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt

$ckt = Get-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup"
Get-AzureRmExpressRouteCircuitPeeringConfig -Name "MicrosoftPeering" -Circuit $ckt

# Virtual Networks

$s1 = New-AzureRmVirtualNetworkSubnetConfig -Name "s1" -AddressPrefix "192.168.0.0/24"
$s2 = New-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix "192.168.1.0/28"
$vnet = New-AzureRmVirtualNetwork -Name "ERVnet" -ResourceGroupName "ExpressRouteResourceGroup" -Location "West US" -AddressPrefix "192.168.0.0/16" -Subnet $s1, $s2

# Gateway

#Create ExpressRoute gateway
$pip = New-AzureRmPublicIpAddress -Name "GwPIP" -ResourceGroupName "ExpressRouteResourceGroup" -Location "West US" -AllocationMethod Dynamic
$subnet = $vnet.Subnets[1].Id
$ipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name "Ipconfig" -PublicIpAddressId $pip.Id -SubnetId $subnet
New-AzureRmVirtualNetworkGateway -Name "ERGw" -ResourceGroupName "ExpressRouteResourceGroup" -Location "West US" -GatewayType ExpressRoute -IpConfigurations $ipconfig

#Link gateway to ExpressRoute circuit
$gw = Get-AzureRmVirtualNetworkGateway -Name "ERGw" -ResourceGroupName "ExpressRouteResourceGroup"
$conn = New-AzureRmVirtualNetworkGatewayConnection -Name "ERConnection" -ResourceGroupName "ExpressRouteResourceGroup" -Location "West US" -VirtualNetworkGateway1 $gw -PeerId $ckt.Id -ConnectionType ExpressRoute



#Creating an authorization

Add-AzureRmExpressRouteCircuitAuthorization -Circuit $circuit -Name "MyAuthorization1"
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $circuit
$circuit = Get-AzureRmExpressRouteCircuit -Name "MyCircuit" -ResourceGroupName "MyRG"

$auth1 = Get-AzureRmExpressRouteCircuitAuthorization -Circuit $circuit -Name "MyAuthorization1"


#Reviewing authorizations
$circuit = Get-AzureRmExpressRouteCircuit -Name "MyCircuit" -ResourceGroupName "MyRG"
$authorizations = Get-AzureRmExpressRouteCircuitAuthorization -Circuit $circuit


#Adding authorizations

$circuit = Get-AzureRmExpressRouteCircuit -Name "MyCircuit" -ResourceGroupName "MyRG"
Add-AzureRmExpressRouteCircuitAuthorization -Circuit $circuit -Name "MyAuthorization2"
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $circuit

$circuit = Get-AzureRmExpressRouteCircuit -Name "MyCircuit" -ResourceGroupName "MyRG"
$authorizations = Get-AzureRmExpressRouteCircuitAuthorization -Circuit $circuit
