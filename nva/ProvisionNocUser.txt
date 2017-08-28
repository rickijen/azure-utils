#
# Create Service Principal for ASM Network team to update route table
#
$ServicePrincipalName = "asm8273445"
$ServicePrincipalPassword = "u9Hsudf3JT252"

$ResourceGroupProd = "rg-prod"
$ResourceGroupNonProd = "rg-nonprod"

$RouteTableProdFront = "rtpfront"
$RouteTableProdBack = "rtpback"
$RouteTableNonProdfront = "rtnpfront"
$RouteTableNonProdBack = "rtnpback"

$rtpfront=(Get-AzureRmRouteTable -Name $RouteTableProdFront -ResourceGroupName $ResourceGroupProd -ErrorAction Stop).Id
$rtpback=(Get-AzureRmRouteTable -Name $RouteTableProdBack -ResourceGroupName $ResourceGroupProd -ErrorAction Stop).Id
$rtnpfront=(Get-AzureRmRouteTable -Name $RouteTableNonProdFront -ResourceGroupName $ResourceGroupNonProd -ErrorAction Stop).Id
$rtnpback=(Get-AzureRmRouteTable -Name $RouteTableNonProdBack -ResourceGroupName $ResourceGroupNonProd -ErrorAction Stop).Id

$sp = New-AzureRmADServicePrincipal -DisplayName $ServicePrincipalName -Password $ServicePrincipalPassword
Sleep 20

New-AzureRmRoleAssignment -RoleDefinitionName "Network Contributor" -ServicePrincipalName $sp.ApplicationId -Scope $rtpfront
New-AzureRmRoleAssignment -RoleDefinitionName "Network Contributor" -ServicePrincipalName $sp.ApplicationId -Scope $rtpback
New-AzureRmRoleAssignment -RoleDefinitionName "Network Contributor" -ServicePrincipalName $sp.ApplicationId -Scope $rtnpfront
New-AzureRmRoleAssignment -RoleDefinitionName "Network Contributor" -ServicePrincipalName $sp.ApplicationId -Scope $rtnpback

Write-Host "DONE"