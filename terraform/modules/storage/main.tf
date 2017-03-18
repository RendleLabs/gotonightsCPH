variable "resource_group_name" {}
variable "prefix" {}
variable "location" {}

resource "azurerm_storage_account" "swarm" {
  name                = "${var.prefix}sysdatae"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"

  tags {
    environment = "production"
  }
}

resource "azurerm_storage_container" "swarm" {
  name                  = "vhds"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.swarm.name}"
  container_access_type = "private"
}

output "container" {
  value = "${azurerm_storage_account.swarm.primary_blob_endpoint}${azurerm_storage_container.swarm.name}"
}
