variable "resource_group_name" {}
variable "prefix" {}
variable "location" {}
variable "ip_address_id" {}
variable "backend_pool_name" {}

resource "azurerm_lb" "swarm" {
  name                = "loadbalancer"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-fe-ipconfig"
    public_ip_address_id = "${var.ip_address_id}"
  }
}

resource "azurerm_lb_backend_address_pool" "swarm" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.swarm.id}"
  name                = "${var.backend_pool_name}"
}

output "id" {
  value = "${azurerm_lb.swarm.id}"
}

output "backend_pool_name" {
  depends_on = ["azurerm_lb_backend_address_pool.swarm"]
  value      = "${var.backend_pool_name}"
}
