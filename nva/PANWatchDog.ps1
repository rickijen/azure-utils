"========== PowerShell PAN Watch Dog function executed at:$(get-date) ==========";

#
# Global variables
#
$sub="7f4k99e6-2fda-4486-b5c4-66yw728a9f86"
$resourceGroup="redondo2"
$virtualNetwork="redondo2"
$User="ApplicationID@somedomain.onmicrosoft.com"
$Password="xxxxxxxxxx"
$Pan1NicPrivateIP="10.0.0.4"
$Pan1NicPort=80
$Pan2NicPrivateIP="10.0.0.5"
$Pan2NicPort=80
$rtName="TestRouteTable"
$rtCfgName="RouteToPAN"
$AddressPrefix="0.0.0.0/0"
$NextHopType="VirtualAppliance"

#
# Azure Authentication methods:
# 1. login with a user account without Multi-Factor Authentication
# 2. login with an AAD Service Principal: https://blogs.endjin.com/2016/01/azure-resource-manager-authentication-from-a-powershell-script/
#
# $app = New-AzureRmADApplication -DisplayName "PANWatchDog" -IdentifierUris "http://redondoazurefunctions2.azurewebsites.net/" -Password SomePassWord
# New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
# Start-Sleep 15
# New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId
#
# $pass = ConvertTo-SecureString "<Your Password>" -AsPlainText –Force
# $cred = New-Object -TypeName pscredential –ArgumentList 45ac0315-8e43-48d4-b235-cd11ec9c3305@rickijengmail.onmicrosoft.com, $pass
# Login-AzureRmAccount -Credential $cred -ServicePrincipal –TenantId 4f813308-71b6-4e90-b5db-fa6070c6de3e
#

$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$UserCred = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
Login-Azurermaccount -Credential $UserCred -SubscriptionId $sub

#
# Test TCP connection to the Private NIC of PAN and update UDR if necessary
#
$t = New-Object Net.Sockets.TcpClient
$t.Connect($Pan1NicPrivateIP,$Pan1NicPort)
if($t.Connected)
{
    $t.Close()
    "PAN at $Pan1NicPrivateIP port $Pan1NicPort is operational"
    exit;
}
else
{
    "Can't reach PAN at $Pan1NicPrivateIP port $Pan1NicPort"

    #Change Route traffic to the other PAN
    $routeTable=Get-AzureRmRouteTable -ResourceGroupName $resourceGroup -Name $rtName
    $rtCfg=Get-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName
    Set-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName -AddressPrefix $AddressPrefix -NextHopType $NextHopType -NextHopIpAddress $Pan2NicPrivateIP
    Set-AzureRmRouteTable -RouteTable $routeTable
    if (!$LASTEXITCODE)
    {
        "Route table updated.";
    }
    else
    {
        "Failed to update Route table.";
    }

    exit;
}
