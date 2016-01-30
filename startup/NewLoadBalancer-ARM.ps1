#
# Create a new Internet facing load balancer in ARM
#

# Global variables
$rgName="redondo2"
$locName="westus"
$lbName="lbredondomc"
$lbPublicIp="LB-PublicIP"
$lbFrontendIp="LB-Frontend"
$lbBackendAddrPl="LB-Backend"
$vnetName="redondo2-vnet"

#$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name LB-Subnet-BE -AddressPrefix 10.0.2.0/24
#New-AzureRmvirtualNetwork -Name NRPVNet -ResourceGroupName NRP-RG -Location 'West US' -AddressPrefix 10.0.0.0/16 -Subnet $backendSubnet

$publicIP = New-AzureRmPublicIpAddress -Name $lbPublicIp -ResourceGroupName $rgName -Location $locName –AllocationMethod Dynamic -DomainNameLabel $lbName

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $lbFrontendIp -PublicIpAddress $publicIP

$beAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $lbBackendAddrPl

$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name SSH -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 22 -BackendPort 22
$inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP1 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3441 -BackendPort 3389
$inboundNATRule3= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP2 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -Protocol TCP -Port 25565 -IntervalInSeconds 15 -ProbeCount 2

$lbrule1 = New-AzureRmLoadBalancerRuleConfig -Name TCP -FrontendIpConfiguration $frontendIP -BackendAddressPool  $beAddressPool -Probe $healthProbe -Protocol TCP -FrontendPort 25565 -BackendPort 25565

$lb = New-AzureRmLoadBalancer -ResourceGroupName $rgName -Name $lbName -Location 'West US' -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNatRule2,$inboundNATRule3 -LoadBalancingRule $lbrule1 -BackendAddressPool $beAddressPool -Probe $healthProbe


# 2 subnets
$feSubnet='frontendSubnet'
$beSubnet='backendSubnet'


$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
$frontendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $feSubnet -VirtualNetwork $vnet
$backendSubnet =  Get-AzureRmVirtualNetworkSubnetConfig -Name $beSubnet -VirtualNetwork $vnet


$nicName='redondomc'
$subnetIndex=0 # backendSubnet
$pip = get-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName
# Need to re-visit and check whether multiple inbound NAT rules allowed
#$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0],$lb.InboundNatRules[1],$lb.InboundNatRules[2]
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0],$lb.InboundNatRules[1],$lb.InboundNatRules[2]



#$redondomcNic | Set-AzureRmNetworkInterface -NetworkInterface $redondomcNic -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0],$lb.InboundNatRules[1],$lb.InboundNatRules[2]
#$redondomcwNic | Set-AzureRmNetworkInterface -NetworkInterface $redondomcwNic -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0],$lb.InboundNatRules[1],$lb.InboundNatRules[2]


