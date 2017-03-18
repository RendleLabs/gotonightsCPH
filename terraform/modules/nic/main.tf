variable "resource_group_name" {}
variable "domain_prefix" {}
variable "label" {}
variable "location" {}
variable "subnet_id" {}
variable "nsg_id" {}
variable "lb_id" {}
variable "lb_backend_pool_name" {}
variable "allocation" {}

variable "quantity" {
  default = 1
}

resource "azurerm_public_ip" "ip" {
  count                        = "${var.quantity}"
  name                         = "ip-manager"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  domain_name_label            = "${var.domain_prefix}-${var.label}${var.quantity > 1 ? format("-%d", count.index) : ""}"
  public_ip_address_allocation = "${var.allocation}"
}

resource "azurerm_network_interface" "nic" {
  count                     = "${var.quantity}"
  name                      = "${var.label}-ni"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.nsg_id}"

  ip_configuration {
    name                                    = "swarm-${var.label}-${count.index}-configuration1"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.ip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${var.lb_id}/backendAddressPools/${var.lb_backend_pool_name}"]
  }
}

output "ids" {
  value = ["${azurerm_network_interface.nic.*.id}"]
}

output "fqdns" {
  value = ["${azurerm_public_ip.ip.*.fqdn}"]
}

output "private_ip_addresses" {
  value = ["${azurerm_network_interface.nic.*.private_ip_address}"]
}

output "public_ip_addresses" {
  value = ["${azurerm_public_ip.ip.*.ip_address}"]
}
