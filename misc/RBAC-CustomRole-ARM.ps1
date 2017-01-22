$Role = Get-AzureRmRoleDefinition -Name "Website Contributor KKK"
$Role.Actions.Add("Microsoft.ResourceHealth/availabilityStatuses/read")
$Role.AssignableScopes.Remove("/") | Out-Null
$Role.AssignableScopes.Add("/subscriptions/7f3cc5e6-2fda-4486-b5c4-66de147a9f86")
New-AzureRmRoleDefinition -Role $Role