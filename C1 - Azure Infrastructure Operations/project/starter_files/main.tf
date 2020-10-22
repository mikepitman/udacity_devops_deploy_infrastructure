/* Code examples leveraged from
-> My existing terraform config(s) for rg, vnet, subnet, vm, appGateway, publicIP etc, built up from Terraform documentation, docs.microsoft.com/.../azure/developer/terraform/*, etc
-> Other (explicit) code sources will be referenced at the relevant locations
# Variables are defined in vars.tf
*/

provider "azurerm" {
  version = "~> 2.27.0"
  features {}
}

########################################################################################################################
##  Resource Group  ####################################################################################################

resource "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}-rg"
  location = var.location
  tags = var.tags
}

########################################################################################################################
##  Virtual Network ####################################################################################################

resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name = "${var.prefix}Vnet"
  address_space = ["10.0.0.0/16"]
  location = var.location
  tags = var.tags
}

########################################################################################################################
##  Vnet Subnet  #######################################################################################################

# Back-end subnet for Load balancer
resource "azurerm_subnet" "backend" {
  resource_group_name = azurerm_resource_group.rg.name
  name = "${var.prefix}backendSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.backend_ip_addresses]
}

########################################################################################################################
##  Public IP Address ##################################################################################################

resource "azurerm_public_ip" "rg_frontend_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name = "${var.prefix}PublicIP"
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
  tags = var.tags
}

########################################################################################################################
##  Security Group, NIC-SG linking  ####################################################################################

# Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${var.prefix}NSG"
  location            = var.location
  tags = var.tags

  security_rule {
    name                       = "allow_inbound_http"
    description                = "Allow inbound HTTP traffic on port 80"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = var.backend_ip_addresses
  }

  security_rule {
    name                       = "allow_inbound_subnets"
    description                = "Allow traffic within subnets"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "block_all_internet"
    description                = "Block all other traffic incoming from Internet"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Linking of backend subnet with Network Security Group
# https://www.terraform.io/docs/providers/azurerm/r/subnet_network_security_group_association.html
resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
  subnet_id = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

########################################################################################################################
##  Load Balancer  #####################################################################################################
##  ref: https://docs.microsoft.com/en-us/azure/developer/terraform/create-vm-scaleset-network-disks-using-packer-hcl

resource "azurerm_lb" "rg" {
  name                = "rg-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags

  frontend_ip_configuration {
    name                 = var.public_ip_address_name
    public_ip_address_id = azurerm_public_ip.rg_frontend_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.rg.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "rg" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.rg.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.rg.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = var.public_ip_address_name
  probe_id                       = azurerm_lb_probe.rg.id
}

########################################################################################################################
##  Packer Image Config  ###############################################################################################

data "azurerm_resource_group" "image" {
  name = var.managed_packer_image_rg
}

data "azurerm_image" "image" {
  name = var.packer_image
  resource_group_name = data.azurerm_resource_group.image.name
}

########################################################################################################################
##  VMSS Config  #######################################################################################################
# https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine_scale_set.html

resource "azurerm_linux_virtual_machine_scale_set" "lvmss" {
  name                = "linux-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Standard_F2"
  instances           = var.scaleset_instances
  admin_username      = var.admin_username
  // computer_name_prefix cannot contain special characters
  computer_name_prefix = var.prefix
  disable_password_authentication = true

  source_image_id = data.azurerm_image.image.id
  tags = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_path)
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vnet"
    primary = true

    ip_configuration {
      name      = "backend"
      primary   = true
      subnet_id = azurerm_subnet.backend.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }
}