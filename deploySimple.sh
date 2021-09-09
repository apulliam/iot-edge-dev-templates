set -e

# verify required variables are set
if [[
   -z ${SUBSCRIPTION+x} ||
   -z ${RESOURCE_GROUP_NAME} ||
   -z ${RESOURCE_GROUP_LOCATION+x} ||
   -z ${VM_NAME+x} ||
   -z ${ADMIN_USER_NAME+x} ||
   -z ${DNS_FOR_PUBLIC_IP} 
   ]];
then 
  echo "Required environment variables not set. See README.MD for instructions."
  exit 1
fi

az group create \
  --subscription "${SUBSCRIPTION}" \
  --name $RESOURCE_GROUP_NAME \
  --location "${RESOURCE_GROUP_LOCATION}"

az deployment group create \
  --subscription "${SUBSCRIPTION}" \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file "simpleNetwork.json"

az deployment group create \
  --subscription "${SUBSCRIPTION}" \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file "ubuntu.json" \
  --parameters "simpleEdge.parameters.json" \
  --parameters \
    virtualNetworkResourceGroup=${RESOURCE_GROUP_NAME} \
    vmName=${VM_NAME} \
    dnsNameForPublicIP=${DNS_FOR_PUBLIC_IP} \
    adminUsername=${ADMIN_USER_NAME} \
    customData=@${CLOUD_INIT} \
    sshKeyData="$(< ~/.ssh/id_rsa.pub)" \
  --query properties.outputs.fqdn.value \
  --output tsv