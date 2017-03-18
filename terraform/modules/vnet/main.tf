variable "resource_group_name" {}
variable "location" {}

resource "azurerm_virtual_network" "swarm" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "swarm" {
  name                 = "subnet"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.swarm.name}"
  address_prefix       = "10.0.2.0/24"
}

output "subnet_id" {
  value = "${azurerm_subnet.swarm.id}"
}
