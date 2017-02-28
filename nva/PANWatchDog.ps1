"========== PowerShell PAN Watch Dog function executed at:$(get-date) ==========";

#
# Global variables
#
#$sub="7f4k99e6-2fda-4486-b5c4-66yw728a9f86"
$resourceGroup="rb09"
$virtualNetwork="rb09-vnet"
#$User="ApplicationID@somedomain.onmicrosoft.com"
#$Password="xxxxxxxxxx"
$Pan1NicPrivateIP="192.168.0.4"
$Pan1NicPort=80
$Pan2NicPrivateIP="192.168.0.5"
$Pan2NicPort=80
$rtName="TestUDR"
$rtCfgName="RouteToPAN"
$AddressPrefix="0.0.0.0/0"
$NextHopType="VirtualAppliance"

#
# Azure Authentication methods:
# 1. login with a user account without Multi-Factor Authentication
# 2. login with an AAD Service Principal: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal
#
# $app = New-AzureRmADApplication -DisplayName "PANWatchDog" -IdentifierUris "http://redondoazurefunctions2.azurewebsites.net/" -Password SomePassWord
# New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
# Start-Sleep 15
# New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId
#

$pass = ConvertTo-SecureString "xxxxxxxxxxxxx" -AsPlainText –Force
$cred = New-Object -TypeName pscredential –ArgumentList xxxxxxxx-ac93-4014-a595-f62503f99db5,$pass
Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId xxxxxxxx-86f1-41af-91ab-2d7cd011db47

#
# Test TCP connection to the Private NIC of PAN and update UDR if necessary
#
Try
{
    "Test TCP connection to PAN at $Pan1NicPrivateIP port $Pan1NicPort started:$(get-date)"
    $t = New-Object Net.Sockets.TcpClient
    $t.Connect($Pan1NicPrivateIP,$Pan1NicPort)
}
Catch
{
    "Can't reach PAN at $Pan1NicPrivateIP port $Pan1NicPort"

    #Change Route traffic to the other PAN
    $routeTable=Get-AzureRmRouteTable -ResourceGroupName $resourceGroup -Name $rtName
    $rtCfg=Get-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName
    Set-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName -AddressPrefix $AddressPrefix -NextHopType $NextHopType -NextHopIpAddress $Pan2NicPrivateIP
    Set-AzureRmRouteTable -RouteTable $routeTable
    "Route table updated"
}
Finally
{
    $t.Close()
    "Test TCP connection to PAN at $Pan1NicPrivateIP port $Pan1NicPort completed: $(get-date)"
}
