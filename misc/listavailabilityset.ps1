(Get-AzureService).servicename | foreach {Get-AzureVM -ServiceName $_ } | 
Where-Object {$_.AvailabilitySetName –ne $null } | 
Select name,AvailabilitySetName |
Format-Table Name, AvailabilitySetName -AutoSize