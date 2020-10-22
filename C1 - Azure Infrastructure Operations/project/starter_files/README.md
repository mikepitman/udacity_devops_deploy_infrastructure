# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Dependencies
You will need to following resources in order to develop, build and run the various components for this project.
You can create and use a free Azure account for this project, or a pay-as-you-go/paid account that you may have access and permission to use. 

1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Instructions
#####1. Clone this repository to a folder on your machine.
You can fork it to your own github account, or...
The Packer image is configured in ..\C1 - Azure Infrastructure Operations\project\starter_files\server.json

#####2. Azure Authentication
If you execute the following commands from Azure Cloud Shell, you will be automatically authenticated. However if you
run the commands locally, you will need to authenticate with your Azure account.
See [here](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli) for your best option.
This implementation assumes Azure login via `az login` from the CLI, and authentication via the opened web browser.

#####3. Build the Packer OS image to use.
Two packer images are provided - each identical except for the web server installed (busybox vs apache).
Create a resource group in Azure to hold the built Packer images, prior to building. You will need to provide the 
subscription ID and image resource group name in the build script.

To build the image from the command line, navigate to the containing folder and execute the following:  
`$ packer build -var 'subscription_id=<your subscription ID>' -var 'image_rg=<image resource group>' server_busybox.json` and/or  
`$ packer build -var 'subscription_id=<your subscription ID>' -var 'image_rg=<image resource group>' server_apache.json` 

After the build completes, view and check the built images using  
`$ az image list`  
or delete the image using  
`$ az image delete -g <image-rg-name> -n <image-name>`
 
#####4. Update and build the Terraform config
######The Azure configuration deploys:
- A resource group
- A virtual network, with a subnet
- A network security group
- A network interface (NIC)
- A public IP address
- A load balancer with backend address pool and pool association for the NIC and load balancer.
- A virtual machine scale set (availability set)
- A configurable number of virtual machines in the scale set. 
- A managed disk for each virtual machine 

######Modifications to the configuration can be made in vars.tf:
"scaleset_instances" : set the number of scale-set instances to deploy  
"location" : set the Azure location in which to deploy the configuration  
"managed_packer_image_rg" : specify the resource group containing packer images to use  
"packer_image" : specify the packer image to use 9n deployments  
"public_key_path" : specify the path of the (local) public key to deploy for the Admin user  
"admin_username" : specify the name to use for the admin account  
 
Initialise the working directory containing the terraform files, and create an execution plan to implement.  
```
terraform init
terraform plan -out=solution.plan
```
Apply the named execution plan using the command below:   
`terraform apply "solution.plan"`  

To tear down the deployed configuration after use, use the following command:  
`terraform destroy`
 
### Output
Terraform `apply` will output the public IP address in front of the load balancer, in the format  
`frontend_public_ip = x.x.x.x`.  
Pointing your browser to `<<frontend_public_ip>>/index.html` will load the page hosted by the scale-set VM(s).

