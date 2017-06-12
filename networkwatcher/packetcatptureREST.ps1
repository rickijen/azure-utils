$subscriptionId = 'c65cf1c8-ceb7-4e78-95db-a45259984db7'
$resourceGroupName = "DemoNetworkWatcher"
$networkWatcherName = "nw1"
$packetCaptureName = "TestPacketCapture5"
$storageaccountname = "rb09diagnostics"
$vmName = "dockerHost01"
$bytestoCaptureperPacket = "0"
$bytesPerSession = "1073741824"
$captureTimeinSeconds = "60"
$localIP = ""
$localPort = "" # Examples are: 80, or 80-120
$remoteIP = ""
$remotePort = "" # Examples are: 80, or 80-120
$protocol = "" # Valid values are TCP, UDP and Any.
$targetUri = "/subscriptions/c65cf1c8-ceb7-4e78-95db-a45259984db7/resourceGroups/DemoNetworkWatcher/providers/Microsoft.Compute/virtualMachines/nginxondocker"
$storageId = "/subscriptions/c65cf1c8-ceb7-4e78-95db-a45259984db7/resourceGroups/DemoNetworkWatcher/providers/Microsoft.Storage/storageAccounts/demonetworkwatcher558/capture/mycaptures.cap" # Example: "https://mytestaccountname.blob.core.windows.net/capture/vm1Capture.cap"
$storagePath = ""
$localFilePath = "c:\\packetcapture.cap" # Example: "d:\capture\vm1Capture.cap"

$requestBody = @"
{
    'properties':  {
                       'target':  '/${targetUri}',
                       'bytesToCapturePerPacket':  '${bytestoCaptureperPacket}',
                       'totalBytesPerSession':  '${bytesPerSession}',
                       'timeLimitinSeconds':  '${captureTimeinSeconds}',
                       'storageLocation':  {
                                               'storageId':  '${storageId}',
                                               'storagePath':  '${storagePath}',
                                               'filePath':  '${localFilePath}'
                                           },
                       'filters':  [
                                       {
                                           'protocol':  '${protocol}',
                                           'localIPAddress':  '${localIP}',
                                           'localPort':  '${localPort}',
                                           'remoteIPAddress':  '${remoteIP}',
                                           'remotePort':  '${remotePort}'
                                       }
                                   ]
                   }
}
"@

armclient PUT "https://management.azure.com/subscriptions/${subscriptionId}/ResourceGroups/${resourceGroupName}/providers/Microsoft.Network/networkWatchers/${networkWatcherName}/packetCaptures/${packetCaptureName}?api-version=2016-07-01" $requestbody

