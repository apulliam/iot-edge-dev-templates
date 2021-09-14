# iot-edge-dev-templates Repo

## Overview
This repository contains Azure ARM templates for creating Azure VM's for testing Azure IoT Edge configurations.  The ARM templates were originally created to test the Azure IoT Nested Edge feature, but can also be used to create single Azure IoT Edge VM's and base Ubuntu VM's.  

The Azure IoT Product Group maintains a respository with an ARM template to [deploy Azure IoT Edge](https://github.com/Azure/iotedge-vm-deploy/) on a standalone VNET.  The [Azure IoT Nested Edge feature tutorial](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-nested-iot-edge) references this repository to create a simpled nested Edge configuration with 2 VM's on separate VNET's.  Since the Edge VM's connect to each other over public IP addresses, this configuration can't be used to test or validate Nested Edge support for proxying nested Edge communication through the parent Edge device on a locked-down network.  The IoT Product Team also has a [industrial IoT repository](https://github.com/Azure-Samples/iot-edge-for-iiot) with a [Purdue](https://github.com/Azure-Samples/iot-edge-for-iiot/blob/master/PurdueNetwork.md) Network Nested Edge configuration, with firewalls between network layers. However, as this configuration deploys 7 VM's, so it's not the easiest environement for developer testing.

This ARM templates in this repo were primarily developed to provide an easy way to deploy and test the Azure IoT Nested Edge feature, by providing a real Purdue style network configuration with only 2 VM's and automating the manual setup steps in the Azure IoT Nested Edge feature tutorial, including the use of the [iotedge-config tool](https://github.com/Azure-Samples/iotedge_config_cli).

## Getting Started

The Azure templates require you to already have an Azure subscription and Bash shell environment with the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed.  On Windows, [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/) is recommended.  MacOS and the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) can also be used.

The Azure IoT Edge VM's created by the template have the administrator account password disabled and must be accessed via SSH key authentication.  The templates assume you already have an [SSH key pair](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed) in your Azure CLI environment.  The template copies the public key from your SSH key pair from ~/.ssh/id_rsa.pub.

You should also have a free or Standard tier Azure IoT Hub service already created and available.  The templates allow the IoT Edge VM's to be created in the same subscription as the Azure IoT Hub or a different subscription.

## Deploying Azure IoT Nested Edge dev environment

This repo follows the same steps from the [Azure IoT Nested Edge feature tutorial](https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-nested-iot-edge), but automates the process to a single Bash script - deployNested.sh

After cloning the repo locally, you need to set some Bash environment variables first before running the script. The file env-nested-template.sh contains a template for the required and optional environment variables.  The repo is setup to ignore files starting with .env, so copy the env-nested-template.sh to a file such as .env-nested-edge. 

1. Set the following required variables:

- IOT_HUB_NAME - name of your IoT Hub in your subscription.  Don't use the FQDN name of the IoT Hub.
- IOT_HUB_SUBSCRIPTION - subscription where your IoT Hub is located.
- EDGE_VM_SUBSCRIPTION - subscription where you want the Edge VM's to be created.  This can be the same subscription as the IOT_HUB_SUBSCRIPTION.
- RESOURCE_GROUP_LOCATION - the Azure Datacenter region where you want the Edge network and VM's to be created.  Typically, you will want to deploy VM's to the same region as your IoT Hub.  However, this is not required and can be different if you want to test higher latency Edge scenarios.
- ADMIN_USER_NAME - the name you want to use as the admin account on the Edge VM's.  It's convenient to use the same username from WSL or your Azure cloud shell as SSH uses your local account by default which allows for shorter SSH command.
- UNIQUE_DNS_PREFIX - string of your choosing which will be used a prefix for the VM names on their public IP addresses.  While the template is designed to test a locked down Nested Edge environment for IoT traffic, both the parent and nested Edge VM's have a dynamic public IP address and DNS name for developer access.

2. Run *source .env-nested_edge* to load the variable into your local Bash shell.
3. Run *az login* in your local Bash shell. 
4. Make the deployNested.sh script executable with *chmod+x* run in your local Bash shell

## Understanding the template output and created results

The deployNested.sh script first creates 3 resource groups in the VM subscription - one for the Azure Virtual Network and one each for the parent and nested Azure IoT Edge VM's.  It then uses the nestedEdgeNetwork.json ARM template to create an Azure Virtual Network, edge-network, with 2 subnets - parent-edge and nested-edge.  Each subnet has a Network Security Group to restrict traffic to/from the subnet to simulate a locked down Nested Edge configuration.

