# Source VM NIC
$SOURCE_NIC_ID="/subscriptions/XXXX/resourceGroups/RICK/providers/Microsoft.Network/networkInterfaces/mc001398"

# Get the Source VM NIC's IP Configurations and save the output to a JSON file
$SNIC = Get-AzNetworkInterface -ResourceId $SOURCE_NIC_ID
$OutputFileName = $SNIC.Name
$SNIC.IpConfigurationsText | Out-File -FilePath "$OutputFileName.json"
