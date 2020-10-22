##  vars.tf  -  declare variables ######################################################################################
##  The variables in this section can be changed as required.  #########################################################

# Configures the number of scale-set VM instances to create
variable "scaleset_instances" {
  description = "Number of scaleset instances to deploy at initiation"
  default = 2
}

# Configures the Azure location in which to create resources. southafricanorth is my closest location
variable "location" {
  description = "Azure region"
  default = "southafricanorth"
}

# Name of Resource group containing the packer images to use
variable "managed_packer_image_rg" {
  type = string
  default = "mike-udacity-image-rg"
}

# Name of packer image to use - uncomment the desired image, and comment out the undesired image.
# The image will need to have been created prior to Terraform deployment
variable "packer_image" {
  description = "Packer image with installed web server to use - busybox or apache"
  default = "ubuntuLtsBusybox"
//  default = "ubuntuLtsApache"
}

# Public key path for the SSH key to deploy for the admin user
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/azurePublicKey"
}

# Name of the admin user to configure
variable "admin_username" {
  description = "Admin username"
  default = "mike"
}

########################################################################################################################
########################################################################################################################
##  It should not be necessary to change these variables  ##############################################################

variable "resource_group_name" {
  description = ""
  # usage appends '-rg' to variable
  default = "mike-udacity"
}

variable "environment" {
  default = "dev"
}
variable "tags" {
  type = map

  default = {
    Environment = "Sandbox for Udacity config"
    Team = "DevOps"
  }
}

variable "prefix" {
  type = string
  default = "udacity"
}

variable "application_port" {
  description = "Externally exposed port for load balancer"
  default = 80
}

variable "backend_ip_addresses" {
  description = "Backend subnet IP address range"
  default = "10.0.1.0/24"
}

variable "public_ip_address_name" {
  description = "Public IP address name"
  default = "PublicIPAddress"
}