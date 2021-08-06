

# exit on erro
set -e

# verify required variables are set
if [[
   -z ${SUBSCRIPTION+x} ||
   -z ${RESOURCE_GROUP_LOCATION+x} ||
   -z ${VM_NAME+x} ||
   -z ${ADMIN_USER_NAME+x} 
   
   ]];
then 
  echo "Required environment variables not set. Please run setNestedEdgeEnv.sh first."
  exit 1
fi



az group create \
  --subscription ${SUBSCRIPTION} \
  --name ${RESOURCE_GROUP_NAME} \
  --location "${RESOURCE_GROUP_LOCATION}"

az deployment group create \
  --subscription ${SUBSCRIPTION} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --template-file "simpleNetwork.json"

az deployment group create \
  --subscription ${SUBSCRIPTION} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --template-file "ubuntu.json" \
  --parameters "ubuntu.parameters.json" \
  --parameters virtualNetworkResourceGroup=${RESOURCE_GROUP_NAME} \
      vmName=${VM_NAME} \
      adminUsername=${ADMIN_USER_NAME} \
      sshKeyData="$(< ~/.ssh/id_rsa.pub)" 

