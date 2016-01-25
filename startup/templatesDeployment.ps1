New-AzureRmResourceGroupDeployment -Name ubuntuwithoms -ResourceGroupName redondo3 -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/201-oms-extension-ubuntu-vm/azuredeploy.json

New-AzureRmResourceGroupDeployment -Name minecraftonubuntu -ResourceGroupName redondo3 -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/minecraft-on-ubuntu/azuredeploy.json
