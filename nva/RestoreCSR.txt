 #
 # The script to update corresponding routes to a specific CSR
 #
 param (
     [Parameter(Mandatory=$true)][string]$RestoreCSR = $(Read-Host)
 )

$ServicePrincipalName = "asm8273445"
$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$SubscriptionId = "c65cf1c8-ceb7-4e78-95db-a45259984db7"

$ResourceGroupProd = "rg-prod"
$ResourceGroupNonProd = "rg-nonprod"

$RouteTableProdFront = "rtpfront"
$RouteTableProdBack = "rtpback"
$RouteTableNonProdfront = "rtnpfront"
$RouteTableNonProdBack = "rtnpback"

$CSRProdFrontIp = "10.0.0.4"
$CSRProdBackIp = "10.1.0.4"
$CSRNonProdfrontIp = "10.2.0.4"
$CSRNonProdBackIp = "10.3.0.4"

$RouteName="RouteToCSR"
$AddressPrefix="0.0.0.0/0"
$NextHopType="VirtualAppliance"

# Login
$sp=Get-AzureRmADServicePrincipal -SearchString $ServicePrincipalName
$cred=Get-Credential -UserName $sp.ApplicationId -Message "Enter Password:"
Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId $TenantId -SubscriptionId $SubscriptionId

$rtpfront=Get-AzureRmRouteTable -Name $RouteTableProdFront -ResourceGroupName $ResourceGroupProd
$rtpback=Get-AzureRmRouteTable -Name $RouteTableProdBack -ResourceGroupName $ResourceGroupProd
$rtnpfront=Get-AzureRmRouteTable -Name $RouteTableNonProdFront -ResourceGroupName $ResourceGroupNonProd
$rtnpback=Get-AzureRmRouteTable -Name $RouteTableNonProdBack -ResourceGroupName $ResourceGroupNonProd

switch ($RestoreCSR)
{
    “csr1” {
                Set-AzureRmRouteConfig -RouteTable $rtpfront -Name $RouteName -AddressPrefix $AddressPrefix `
                -NextHopType $NextHopType -NextHopIpAddress $CSRProdFrontIp
                Set-AzureRmRouteTable -RouteTable $rtpfront
                "Routes point to $RestoreCSR"
            }
    “csr2” {
                Set-AzureRmRouteConfig -RouteTable $rtpback -Name $RouteName -AddressPrefix $AddressPrefix `
                -NextHopType $NextHopType -NextHopIpAddress $CSRProdBackIp
                Set-AzureRmRouteTable -RouteTable $rtpback
                "Routes point to $RestoreCSR"
            }
    “csr3” {
                Set-AzureRmRouteConfig -RouteTable $rtnpfront -Name $RouteName -AddressPrefix $AddressPrefix `
                -NextHopType $NextHopType -NextHopIpAddress $CSRNonProdFrontIp
                Set-AzureRmRouteTable -RouteTable $rtnpfront
                "Routes point to $RestoreCSR"
            }
    “csr4” {
                Set-AzureRmRouteConfig -RouteTable $rtnpback -Name $RouteName -AddressPrefix $AddressPrefix `
                -NextHopType $NextHopType -NextHopIpAddress $CSRNonProdBackIp
                Set-AzureRmRouteTable -RouteTable $rtnpback
                "Routes point to $RestoreCSR"
            }
    Default {Write-Host "Unknown CSR"}
}

