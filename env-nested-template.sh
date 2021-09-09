# Nested Edge required values
export IOT_HUB_NAME=""
export IOT_HUB_SUBSCRIPTION=""
export EDGE_VM_SUBSCRIPTION=""
export RESOURCE_GROUP_LOCATION=""
export ADMIN_USER_NAME=""
export UNIQUE_DNS_PREFIX=""

# overrride values optional
export NETWORK_RESOURCE_GROUP_NAME="edge12-network"
export PARENT_EDGE_RESOURCE_GROUP_NAME="edge12-parent"
export NESTED_EDGE_RESOURCE_GROUP_NAME="edge12-nested"
export NESTED_EDGE_VM_NAME="nested-edge"
export PARENT_EDGE_VM_NAME="parent-edge"
export NESTED_EDGE_DNS_NAME=${UNIQUE_DNS_PREFIX}"-"${NESTED_EDGE_VM_NAME}
export PARENT_EDGE_DNS_NAME=${UNIQUE_DNS_PREFIX}"-"${PARENT_EDGE_VM_NAME}
