##Setting Global Paramaters##
$date = Get-Date -UFormat “%Y-%m-%d-%H-%M”

#Connecting as AzureRunas Principle account
$connectionName = “AzureRunAsConnection”
$resourceGroupName = "rg-uw-network-csr-nonprod"
$vmName="UWNETCSRNP01"


#Select-AzureRmSubscription -SubscriptionName $SubscriptionName | Out-Null
$ResourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

$VM = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName #getting the virtual machine object
$StrAccName =([System.Uri]$VM.StorageProfile.OsDisk.Vhd.uri).Host.Split(‘.’)[0] #getting SA of VHD.
$RGName = Get-AzureRmStorageAccount | where {$_.StorageAccountName -eq $StrAccName} | Select-Object -ExpandProperty ResourceGroupName #getting RG of VHD.
$VHDName = $VM.StorageProfile.OsDisk.vhd.Uri.Split(‘/’)[-1] #getting VHD name.
$SrcCntName = $VM.StorageProfile.OsDisk.vhd.Uri.Split(‘/’)[-2] #Source container name.
$StrAcc = Get-AzureRmStorageAccount -AccountName $StrAccName -ResourceGroupName $RGName

Write-Verbose -Verbose $VM.Name
Write-Verbose -Verbose $StrAcc.StorageAccountName

Start-Sleep 2
Write-Verbose -Verbose “Creating snapshot for OS disk $VHDName ….”
$VMblob = Get-AzureRMStorageAccount -Name $StrAccName -ResourceGroupName $RGName |`
Get-AzureStorageContainer | where {$_.Name -eq $SrcCntName} | Get-AzureStorageBlob | where {$_.Name -eq $VHDName -and $_.ICloudBlob.IsSnapshot -ne $true}
$VMsnap = $VMblob.ICloudBlob.CreateSnapshot() #Creating snapshot
Start-Sleep 2

Write-Host “OS disk $VHDName Snapshot created….!!!!”
Start-Sleep 2

$VMSnapshots = Get-AzureStorageBlob –Context $strAcc.Context -Container $SrcCntName | Where-Object {$_.ICloudBlob.IsSnapshot -and $_.Name -eq $VHDName -and $_.SnapshotTime -lt (Get-Date).AddDays(-14) }
if($VMSnapshots -ne $null)
{
    Write-Host “Deleting snapshots prior to 14 days for OS Disk $VHDName ….”
    foreach($VMSnapshot in $VMSnapshots)
    {
        $VMSnapshot.ICloudBlob.Delete()
        Write-Host ” OS Disk $VHDName snapshots deleted…!!!”
    }
}
