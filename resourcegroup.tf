resource "azurerm_resource_group" "vault" {
  name     = "${var.environment}-vault-rg"
  location = var.location

  tags = {
    environment = var.environment
  }
}
