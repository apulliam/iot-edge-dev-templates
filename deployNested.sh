#!/bin/bash

# exit on error
set -e

# verify required variables are set
if [[
   -z ${IOT_HUB_NAME} ||
   -z ${IOT_HUB_SUBSCRIPTION+x} ||
   -z ${EDGE_VM_SUBSCRIPTION+x} ||
   -z ${RESOURCE_GROUP_LOCATION+x} ||
   -z ${ADMIN_USER_NAME+x} ||
   -z ${NETWORK_RESOURCE_GROUP_NAME+x} ||
   -z ${PARENT_EDGE_RESOURCE_GROUP_NAME+x} ||
   -z ${NESTED_EDGE_RESOURCE_GROUP_NAME+x} ||
   -z ${NESTED_EDGE_VM_NAME+x} ||
   -z ${PARENT_EDGE_VM_NAME+x} ||
   -z ${NESTED_EDGE_DNS_NAME+x} ||
   -z ${PARENT_EDGE_DNS_NAME+x} 
   ]];
then 
  echo "Required environment variables not set. See README.MD for instructions."
  exit 1
fi

iot_hub_host_name=$IOT_HUB_NAME".azure-devices.net"

# create vnet resource group
az group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --name "${NETWORK_RESOURCE_GROUP_NAME}" \
  --location "${RESOURCE_GROUP_LOCATION}" 

# create parent edge resource group
az group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --name "${PARENT_EDGE_RESOURCE_GROUP_NAME}" \
  --location "${RESOURCE_GROUP_LOCATION}" 

# create nested edge resource group
az group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --name "${NESTED_EDGE_RESOURCE_GROUP_NAME}" \
  --location "${RESOURCE_GROUP_LOCATION}" 

# create vnet
az deployment group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --resource-group "${NETWORK_RESOURCE_GROUP_NAME}" \
  --template-file "nestedEdgeNetwork.json" \
  --parameters "nestedEdgeNetwork.parameters.json"

# create parent edge VM and read private IP and FQDN output into string variable
output_str=$(az deployment group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --resource-group "${PARENT_EDGE_RESOURCE_GROUP_NAME}" \
  --template-file "ubuntu.json" \
  --parameters "parentEdge.parameters.json" \
  --parameters \
      virtualNetworkResourceGroup="${NETWORK_RESOURCE_GROUP_NAME}" \
      vmName="${PARENT_EDGE_VM_NAME}" \
      adminUsername="${ADMIN_USER_NAME}" \
      sshKeyData="$(< ~/.ssh/id_rsa.pub)" \
      dnsNameForPublicIP="${PARENT_EDGE_DNS_NAME}" \
  --query "properties.outputs.[privateIp.value, fqdn.value]" \
  --output tsv | tee /dev/tty)

# convert string output to array
readarray -t parent_edge_output <<<"${output_str}"

# initialize individual private IP and FQDN variables
parent_edge_private_IP=${parent_edge_output[0]}
parent_edge_FQDN=${parent_edge_output[1]}

# create nested edge VM and read private IP and FQDN output into string variable
output_str=$(az deployment group create \
  --subscription "${EDGE_VM_SUBSCRIPTION}" \
  --resource-group "${NESTED_EDGE_RESOURCE_GROUP_NAME}" \
  --template-file "ubuntu.json" \
  --parameters "nestedEdge.parameters.json" \
  --parameters \
      virtualNetworkResourceGroup="${NETWORK_RESOURCE_GROUP_NAME}" \
      vmName="${NESTED_EDGE_VM_NAME}" \
      adminUsername="${ADMIN_USER_NAME}" \
      sshKeyData="$(< ~/.ssh/id_rsa.pub)" \
      dnsNameForPublicIP="${NESTED_EDGE_DNS_NAME}" \
  --query "properties.outputs.[privateIp.value, fqdn.value]" \
  --output tsv | tee /dev/tty)

# convert string output to array
readarray -t nested_edge_output <<<"${output_str}"

# initialize individual private IP and FQDN variables
nested_edge_private_IP=${nested_edge_output[0]}
nested_edge_FQDN=${nested_edge_output[1]}

# download and unpack nested edge config tool
rm -rf ./output
mkdir ./output
cd ./output
wget "https://github.com/Azure-Samples/iotedge_config_cli/releases/download/latest/iotedge_config_cli.tar.gz"
tar -xvf iotedge_config_cli.tar.gz

# copy template files for tutorial
cd iotedge_config_cli_release
cp ./templates/tutorial/*.json .
cp ./templates/tutorial/*.toml .

# use VM name as the device ID's in IoT Hub
PARENT_EDGE_DEVICE_ID=${PARENT_EDGE_VM_NAME}
NESTED_EDGE_DEVICE_ID=${NESTED_EDGE_VM_NAME}

# write out nested edge config tool YAML file, inserting values for IoT Hub, device ID, and private IP addresses 
file="./iotedge_config.yaml"

cat << EOT > $file
config_version: "1.0"
iothub:
  iothub_hostname: "${iot_hub_host_name}"
  iothub_name: "${IOT_HUB_NAME}"
  ## Authentication method used by IoT Edge devices: symmetric_key or x509_certificate
  authentication_method: symmetric_key 

## Root certificate used to generate device CA certificates. Optional. If not provided a self-signed CA will be generated
# certificates:
#   root_ca_cert_path: ""
#   root_ca_cert_key_path: ""

## IoT Edge configuration template to use
configuration:
  template_config_path: "./device_config.toml"
  default_edge_agent: "\$upstream:8000/azureiotedge-agent:1.2"

## Hierarchy of IoT Edge devices to create
edgedevices:
  device_id: ${PARENT_EDGE_DEVICE_ID}
  edge_agent: "mcr.microsoft.com/azureiotedge-agent:1.2" ## Optional. If not provided, default_edge_agent will be used
  deployment: "./deploymentTopLayer.json" ## Optional. If provided, the given deployment file will be applied to the newly created device
  hostname: "${parent_edge_private_IP}"
  child:
    - device_id: ${NESTED_EDGE_DEVICE_ID}
      deployment: "./deploymentLowerLayer.json" ## Optional. If provided, the given deployment file will be applied to the newly created device
      hostname: "${nested_edge_private_IP}"
EOT

# iotedge config tool issues azure cli commands which assume current account has access to IoT Hub
az account set --subscription ${IOT_HUB_SUBSCRIPTION}
./iotedge_config --config ./iotedge_config.yaml --output ./ -f

# copy iot edge config tool generated packages to VM's
scp -o StrictHostKeyChecking=accept-new ./${PARENT_EDGE_DEVICE_ID}.zip ${ADMIN_USER_NAME}@${parent_edge_FQDN}:~
scp -o StrictHostKeyChecking=accept-new ./${NESTED_EDGE_DEVICE_ID}.zip ${ADMIN_USER_NAME}@${nested_edge_FQDN}:~

# run script to install docker, Azure IoT Edge, generated package configurations
cd ../..
az vm run-command invoke --command-id RunShellScript --parameters  "ADMIN_USER_NAME=${ADMIN_USER_NAME}" "DEVICE_ID=${PARENT_EDGE_DEVICE_ID}" --scripts @install-edge.sh --name "${PARENT_EDGE_VM_NAME}" --resource-group "${PARENT_EDGE_RESOURCE_GROUP_NAME}" --subscription "${EDGE_VM_SUBSCRIPTION}"
az vm run-command invoke --command-id RunShellScript --parameters  "ADMIN_USER_NAME=${ADMIN_USER_NAME}" "DEVICE_ID=${NESTED_EDGE_DEVICE_ID}" --scripts @install-edge.sh --name "${NESTED_EDGE_VM_NAME}" --resource-group "${NESTED_EDGE_RESOURCE_GROUP_NAME}" --subscription "${EDGE_VM_SUBSCRIPTION}"

# finally delete temporary rule for software installation on nested edge to lock it down
az network nsg rule delete  --name "ToRemove_Allow_Machine_Build" --nsg-name "${NESTED_EDGE_VM_NAME}-nsg" --resource-group "${NETWORK_RESOURCE_GROUP_NAME}" --subscription "${EDGE_VM_SUBSCRIPTION}"