data "template_file" "setup" {
  template = "${file("${path.module}/setup.tpl")}"

  vars = {
    resource_group_name = "${var.environment}-vault-rg"
    vm_name             = var.vm_name
    vault_download_url  = var.vault_download_url
    tenant_id           = var.tenant_id
    subscription_id     = var.subscription_id
    client_id           = var.client_id
    client_secret       = var.client_secret
    vault_name          = "${azurerm_key_vault.vault.name}"
    key_name            = var.key_name
  }
}
