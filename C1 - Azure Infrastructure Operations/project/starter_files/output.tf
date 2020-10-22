########################################################################################################################
##  Output of deployment-dependent parameters  #########################################################################

output "frontend_public_ip" {
  value = azurerm_public_ip.rg_frontend_pip.ip_address
}