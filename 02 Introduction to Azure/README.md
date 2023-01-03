# IRC168976 DevOps GL BaseCamp homework 02. Introduction to Azure

## Conditions

* Get test account on Azure (if not done yet)
* Create 2 Linux VMs with webserver (Apache or nginx) installed
* Configure loadbalancer to serve data from these VMs
* Export resulting infrastructure as a ARM template and commit to your repository.
* Extra points: Web-server installation should be handled by template

## Solution

### Template description

This template is built with an assumption that it can be used to deploy a single resource group and host there all the resources that need to be created. 

This template must be used at a subscription scope.

#### Distribution contents

The distribution consists of two files in JSON with comments format and one cloud-init setup script file in yaml format:
1) `irc168976-hw02-intro-to-azure.jsonc` - This file contains the necessary descriptions of resources, actually it is the template.
2) `irc168976-hw02-intro-to-azure.parameters.jsonc` - This file contains the list of the template parameters and their values.
3) `irc168976-hw02-intro-to-azure.cloud-config.yaml` - This file contains cloud-init setup script commands to install apache2 and create custom index.html file. The base64-encoded content of this file is embedded into `irc168976-hw02-intro-to-azure.jsonc` file as a default value of a `vmCustomDataBase64EncodedContents` parameter. Plain-text representation of this file is provided for convenience.

#### The parameters of this template

The following parameters are provided for this template:
1) `templateDeploymentPurpose` - a short string to describe the specific purpose of the deployment. Default value: `IRC168976-hw02-intro-to-azure`
2) `domainNameLabelValueToAssociateWithPublicLoadBalancerIP` - a short domain name label to access deployed web resource by FQDN. Default value: toLower(`IRC168976-hw02-intro-to-azure`)
3) `operatorIPAddress` - a public IP-address of operator's (client's) PC, from which this template is deployed. Used to restrict SSH access to VMs only for that IP. Default value: `*` (allow connection from all)
4) `vmAdministratorAccountUsername` - Virtual machine Administrator account username. Default value: `adminuser`
5) `vmAdministratorAccountSSHPublicKeyContents` __*__ - Virtual machine Administrator account SSH public key contents. Must contain the type and contents of the key. For example: `SSH-RSA AAAAB3NzaC1...a_lot_of_symbols...TToQk=`. Default value is not provided. **The value of this parameter must be provided explicitly using the template parameters file**. 
6) `vmCustomDataBase64EncodedContents` - Base64-encoded Cloud-init setup script to configure VM during provisioning process. Default value: Base64-encoded Cloud-init setup script that contains apache2 installation and custom index.html file creation commands.
7) `vmInstancesCount` - The value of this parameter indicates the quantity of virtual machine instances, that will be created during deployment. Default value is `2`. 

#### The resource set

This template contains the following resource descriptions:
1) A resource group named `${templateDeploymentPurpose}-rg`
2) A nested deployment resource named `${templateDeploymentPurpose}-rg-resource-set-deployment`
3) A network security group resource named `${templateDeploymentPurpose}-nsg-allow-ssh-and-http`
   1) A rule to allow inbound HTTP-traffic on standard port 80 from all
   2) A rule to allow inbound traffic on port 22 from operator's (client's) IP or from all depending on the `operatorIPAddress` parameter value
4) A virtual network resource named `${templateDeploymentPurpose}-vnet`. The size of network is 16 IP addresses.
   1) A subnet of the same size as the virtual network.
5) A public ip address resource named `${templateDeploymentPurpose}-PubIP-for-PubLB`
6) A public load balancer resource named `${templateDeploymentPurpose}-pub-lb-for-VMs`
   1) An inbound NAT rule to allow inbound ssh connections to internal resources using port forwarding mechanism
   2) A load balancing rule to balance inbound HTTP traffic
   3) An outbound SNAT rule to allow all the outbound traffic
7) A nic resource to attach to VM named `${templateDeploymentPurpose}-vm-nic-0{0..(${vmInstancesCount}-1)}`
8) A VM compute resource named `${templateDeploymentPurpose}-vm-0{0..(${vmInstancesCount}-1)}`

#### The outputs

The following outputs are provided in this template:
1) `providedPublicIPAddress` - a public IP address to access deployed http resource or command-line interfaces of virtual machines.
2) `actualFQDN` - a fully qualified domain name that associated with the public IP address.
3) `vmInstancesSSHAccessCommandsList` - a list of CLI commands to access deployed virtual machines using SSH. The list corresponds to the number of virtual machines and the NAT port forwarding rule settings of the load balancer.
4) `webAddressToAccessTheResultWithABrowser` - a URL that consists of the pattern http:// and the resulting public IP address and can be used directly in the browser to access the deployed web resource
5) `azureCLIResourcesCleanUpCommandToRunInPowerShell` - a command that can be used to clean up resources when they are no longer needed. The command options are specific to the deployment settings

### How to use this template

#### Prerequisites

The following conditions must be met to deploy this template:
1) Got an Azure subscription.
2) The Azure CLI installed and authenticated.
3) The files `irc168976-hw02-intro-to-azure.jsonc` and `irc168976-hw02-intro-to-azure.parameters.jsonc` are downloaded in the same directory on a local PC
3) A SSH key pair created or choosed to use with this template.
4) The contents of the SSH public key file placed into the `irc168976-hw02-intro-to-azure.parameters.jsonc` file as the `vmAdministratorAccountSSHPublicKeyContents` parameter value.

#### Deploy resources

To deploy resources the following command can be used:

```
az deployment sub create --location westeurope --handle-extended-json-format --template-file .\irc168976-hw02-intro-to-azure.jsonc --parameters '@irc168976-hw02-intro-to-azure.parameters.jsonc'
```

#### Access deployed web resource

It is possible to use the `webAddressToAccessTheResultWithABrowser` output attribute value as a location URL of deployed web resource to visit it with a web browser.

#### Access any of deployed VMs

All the VMs are accessible with SSH on the same public IP but using different ports in range that starts from `2201`. So the combination `${providedPublicIPAddress}:2201` corresponds to the first virtual machine, `${providedPublicIPAddress}:2202` - to the second one and so on. The sequence `${providedPublicIPAddress}` means the value of actual public IP address that is provided during template deployment process.
Actual port range size depends on the `vmInstancesCount` input parameter value and can be in range from `2201` to `2212`.
By default this range consists of two ports: `2201`, 22`02.

To connect to the first VM the following commands can be used:
1) Get VM public keys and save them to the `known_hosts` file on the local PC. This command should be run only once.
```
ssh-keyscan -p 2201 ${providedPublicIPAddress} >> ~/.ssh/known_hosts
```
2) Access the first VM CLI with SSH:
```
ssh -v -p 2201 -l adminuser -i identity_file ${providedPublicIPAddress}
```

Here the `identity_file` sequence means the path to private SSH key from the pair that is created or chosen to use with the template.

The `vmInstancesSSHAccessCommandsList` output attribute contains SSH connection command for every provided VM.

#### Clean up resources

To clean the Azure resources up when they are no longer needed it is convenient to use a command that is displayed as the value of the `azureCLIResourcesCleanUpCommandToRunInPowerShell` output attribute.

If some deployments are failed and any outputs aren't displayed it is possible to use the following commands:
```
az group delete --yes --name ${templateDeploymentPurpose}-rg ; az deployment sub delete --name irc168976-hw02-intro-to-azure
```

The expression `${templateDeploymentPurpose}` is a placeholder for the actual value of the `templateDeploymentPurpose` parameter.

The expression `${templateDeploymentPurpose}-rg` is a resource group name where all the resources are placed.

By default `${templateDeploymentPurpose}=IRC168976-hw02-intro-to-azure`, so the clean-up command will look like this:
```
az group delete --yes --name IRC168976-hw02-intro-to-azure-rg ; az deployment sub delete --name irc168976-hw02-intro-to-azure
```
