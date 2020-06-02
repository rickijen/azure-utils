# Source VM NIC
$SOURCE_NIC_ID="/subscriptions/XXXX/resourceGroups/RICK/providers/Microsoft.Network/networkInterfaces/mc001398"

# Destination VM NIC
$DEST_NIC_ID="/subscriptions/XXXX/resourceGroups/RICK/providers/Microsoft.Network/networkInterfaces/Luis-NIC"
$DEST_SUBNET_ID="/subscriptions/XXXX/resourceGroups/RICK/providers/Microsoft.Network/virtualNetworks/LUIS-VNet/subnets/mysubnet"

# Get the Source VM NIC's IP Configurations and save into a JSON object $SOURCE_JSON
$SNIC = Get-AzNetworkInterface -ResourceId $SOURCE_NIC_ID
$SOURCE_JSON =  ConvertFrom-Json -InputObject $SNIC.IpConfigurationsText

# Create a hash table for IP config names and values
$IpconfigNames=$SOURCE_JSON.Name
$PrivateIpAddresses=$SOURCE_JSON.PrivateIpAddress
$table = @{}
for ($i = 0; $i -lt $SOURCE_JSON.Name.Count; $i++)
{
    $table[$IpconfigNames[$i]] = $PrivateIpAddresses[$i]
}

# Add each IP address from source NIC to destination NIC IP Configurations
$DNIC = Get-AzNetworkInterface -ResourceId $DEST_NIC_ID
$table.GetEnumerator() | ForEach-Object {
    # We will skip the Primary IP config
    if ("$($_.Key)" -eq "ipconfig1") { return }
    $DNIC | Add-AzNetworkInterfaceIpConfig -Name "$($_.Key)" -PrivateIpAddress "$($_.Value)" -PrivateIpAddressVersion IPv4 -SubnetId $DEST_SUBNET_ID
}

# Make it so!
$DNIC | Set-AzNetworkInterface
