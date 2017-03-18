variable "resource_group_name" {}
variable "prefix" {}
variable "location" {}

variable "workers" {
  type = "list"
}

variable "lb_id" {}
variable "backend_pool_name" {}
variable "probe_name" {}

resource "azurerm_lb_probe" "swarm" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${var.lb_id}"
  name                = "${var.probe_name}"
  protocol            = "Tcp"
  port                = 22
}

resource "azurerm_lb_rule" "http" {
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${var.lb_id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-lb-fe-ipconfig"
  probe_id                       = "${var.lb_id}/probes/${var.probe_name}"
  backend_address_pool_id        = "${var.lb_id}/backendAddressPools/${var.backend_pool_name}"
}

resource "azurerm_lb_rule" "https" {
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${var.lb_id}"
  name                           = "https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.prefix}-lb-fe-ipconfig"
  probe_id                       = "${var.lb_id}/probes/${var.probe_name}"
  backend_address_pool_id        = "${var.lb_id}/backendAddressPools/${var.backend_pool_name}"
}
