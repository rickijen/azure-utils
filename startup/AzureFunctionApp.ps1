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
$remoteServer="www.google.com"
#
# Route table variables
#
$rtName="testRouteTable"
$rtCfgName="routeOne"
$AddressPrefix="0.0.0.0/0"
$NextHopType="VirtualAppliance"
$NextHopIpAddress="10.0.0.7"

# Azure Authentication - need to login with an account does not require MFA
$SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
$UserCred = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
Login-Azurermaccount -Credential $UserCred -SubscriptionId $sub

# Test connection to remote server
$GoogleContent=Invoke-RestMethod -Uri $remoteServer -Method Get
if (!$LASTEXITCODE)
{
    # Everything is normal!
    Write-Output "www.google.com is alive. No changes to UDR"
    exit;
}
else
{
    Write-Output "Can't reach $remoteServer";

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
