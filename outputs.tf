output "key_vault_name" {
  value = "${azurerm_key_vault.vault.name}"
}

#output "vault_public_ip" {
#  value = "${azure_lb.vault.public_ip_address_id}"
#}
