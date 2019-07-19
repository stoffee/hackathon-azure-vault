output "principal_id" {
  value = "${lookup(azurerm_virtual_machine_scale_set.vault.identity[0], "principal_id")}"
}


output "key_vault_name" {
  value = "${azurerm_key_vault.vault.name}"
}

output "vault_public_ip" {
  value = "${azurerm_public_ip.vault.id}"
}
