output "key_vault_name" {
  value = "${azurerm_key_vault.vault.name}"
}

output "vault_public_ip" {
  value = "${azurerm_public_ip.vault.id}"
}
