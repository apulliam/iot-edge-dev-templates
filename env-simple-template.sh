# simple edge environment
export SUBSCRIPTION=""
export RESOURCE_GROUP_NAME=""
export RESOURCE_GROUP_LOCATION=""
export VM_NAME=""
export ADMIN_USER_NAME=""
export UNIQUE_DNS_PREFIX=""
export DNS_FOR_PUBLIC_IP=${UNIQUE_DNS_PREFIX}"-"${VM_NAME}
# optional software to install with cloud init
# set to empty or just remove varialbe for no software installed 
export CLOUD_INIT="" 
# Azure IoT Edge 1.2 installed
export CLOUD_INIT=./edge-init/cloud-init.txt 
# Azure IoT Edge 1.2  and ADU agent installed
# similar to official IoT edge template, but does not support setting connection string
export CLOUD_INIT=./edge-adu-init/cloud-init.txt 