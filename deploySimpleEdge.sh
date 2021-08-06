set -e

az group create \
  --name $resourceGroupName \
  --location "${resourceGroupLocation}"

az deployment group create \
  --resource-group $resourceGroupName \
  --template-file "simpleNetwork.json"

az deployment group create \
  --resource-group $resourceGroupName \
  --template-file "ubuntu.json" \
  --parameters "simpleEdge.parameters.json" \
  --parameters \
    virtualNetworkResourceGroup="${resourceGroupName}" \
    vmName="${vmName}" \
    dnsNameForPublicIP="${dnsNameForPublicIP}" \
    adminUsername="${adminUsername}" \
    customData=@cloud-init.txt \
    sshKeyData="$(< ~/.ssh/id_rsa.pub)" \
  --query properties.outputs.fqdn.value \
  --output tsv