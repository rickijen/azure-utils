#
# Azure Function
# https://azure.microsoft.com/en-us/documentation/articles/functions-create-first-azure-function/
#

Write-Output "========== PowerShell Timer trigger function executed at:$(get-date) ==========";

#
# Global variables
#
$sub="xxxxxxx"
$resourceGroup="xxxxx"
$virtualNetwork="xxxxx"
$User = "someone@somewhere.com"
$Password = "xxxxxxxxxxx"
$PrimaryPanIpAddr="10.0.0.6"

#
# Route table variables
#
$rtName="testRouteTable"
$rtCfgName="routeOne"
$AddressPrefix="0.0.0.0/0"
$NextHopType="VirtualAppliance"
# This is the backup PAN IP address
$NextHopIpAddress="10.0.0.7"

# Azure Authentication - need to login with an account does not require MFA
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$UserCred = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
Login-Azurermaccount -Credential $UserCred -SubscriptionId $sub

## NOT IN USE
## Test connection to remote server
## $GoogleContent=Invoke-RestMethod -Uri $remoteServer -Method Get

# Check the health of PAN via REST API
# https://www.paloaltonetworks.com/documentation/60/pan-os/pan-os/device-management/use-the-xml-api
# https://www.paloaltonetworks.com/content/dam/pan/en_US/assets/pdf/technical-documentation/pan-os-60/XML-API-6.0.pdf
$PanHealthContext=Invoke-RestMethod -Uri https://$PrimaryPanIpAddr/esp/restapi.esp?type=report&reporttype=dynamic&reportname=top-app-summary&period=last-hour&topn=5&key=0RgWc42Oi0vDx2WRUIUM6A= -Method Get

if (!$LASTEXITCODE)
{
    # Everything is normal!
    Write-Output "PAN is alive and well. No changes to UDR."
    exit;
}
else
{
    Write-Output "Can't reach the PAN.";

    #Get ready to change route table
    $routeTable=Get-AzureRmRouteTable -ResourceGroupName $resourceGroup -Name $rtName
    $rtCfg=Get-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName
    Set-AzureRmRouteConfig -RouteTable $routeTable -Name $rtCfgName -AddressPrefix $AddressPrefix -NextHopType $NextHopType -NextHopIpAddress $NextHopIpAddress
    Set-AzureRmRouteTable -RouteTable $routeTable
    if (!$LASTEXITCODE)
    {
        Write-Output "Route table updated.";
    }
    else
    {
        Write-Output "Failed to update Route table.";
    }

    exit;
}
