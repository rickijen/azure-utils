#
# New Windows VM
#

$installedPasswordFile = "C:\Users\rijen\azure-utils\startup\azpassword.txt"
$packagedPasswordFile = Join-Path (Split-Path $profile) azpassword.txt

If (Test-Path $installedPasswordFile){
    # // File exists
    $passwordFile = $installedPasswordFile
} Else {
    Write-Output "Use packaged password"
    $passwordFile = $packagedPasswordFile
}

$azUser = "coadmin@rickijengmail.onmicrosoft.com"
$azPassword = Get-Content $passwordFile | ConvertTo-SecureString
$azCredential = New-Object System.Management.Automation.PSCredential $azUser,$azPassword

$family="Windows Server 2012 R2 Datacenter"
$image=Get-AzureVMImage | where { $_.ImageFamily -eq $family } | sort PublishedDate -Descending | select -ExpandProperty ImageName -First 1
$vmname="redondmcw"
$vmsize="Basic_A2"
Set-AzureSubscription -SubscriptionId 7f3cc5e6-2fda-4486-b5c4-66de147a9f86 -CurrentStorageAccountName redondomc
$availset=Get-AzureRmAvailabilitySet -ResourceGroupName redondo
$vm1=New-AzureVMConfig -Name $vmname -InstanceSize $vmsize -ImageName $image -AvailabilitySetName $availset.Name
#$cred=Get-Credential -Message "Type the name and password of the local administrator account."
#$vm1 | Add-AzureProvisioningConfig -Windows -AdminUsername $cred.GetNetworkCredential().Username -Password $cred.GetNetworkCredential().Password
$vm1 | Add-AzureProvisioningConfig -Windows -AdminUsername "weswes" -Password $azCredential.Password
$vm1 | Set-AzureSubnet -SubnetNames "Subnet-1"
$disksize=1
$disklabel="DCData"
$lun=0
$hcaching="None"
$vm1 | Add-AzureDataDisk -CreateNew -DiskSizeInGB $disksize -DiskLabel $disklabel -LUN $lun -HostCaching $hcaching
$svcname="redondomcw"
$vnetname="redondomc"
New-AzureVM –ServiceName $svcname -VMs $vm1 -VNetName $vnetname