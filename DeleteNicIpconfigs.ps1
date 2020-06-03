# Any VM NIC
$NIC_ID="/subscriptions/XXXX/resourceGroups/RICK/providers/Microsoft.Network/networkInterfaces/Luis-NIC"

# Export the NIC's IP Configurations
$NIC = Get-AzNetworkInterface -ResourceId $NIC_ID
$SOURCE_JSON =  ConvertFrom-Json -InputObject $NIC.IpConfigurationsText

# Delete the IP Configurations from NIC
$SOURCE_JSON.Name | ForEach-Object {
    # We will skip the Primary IP config
    if ($_ -eq "ipconfig1" -or $_ -eq "ConfigSync-01") { return }
    Remove-AzNetworkInterfaceIpConfig -Name $_ -NetworkInterface $NIC
}

# Make it so!
$NIC | Set-AzNetworkInterface
