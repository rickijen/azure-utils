#
# New Azure website in ASM
#

$wsLocation = "West US"
$wsName = "redondomc"
$wsQASlot = "QA"

New-AzureWebsite -Location $ wsLocation -Name $ wsName

New-AzureWebsite -Location $ wsLocation -Name $ wsName -Slot $ wsQASlot


