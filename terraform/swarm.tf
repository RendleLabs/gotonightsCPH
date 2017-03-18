variable "resource_name_prefix" {}

variable "subscription_id" {}

variable "client_id" {}

variable "client_secret" {}

variable "tenant_id" {}

variable "csr_password" {}

variable "location" {
  default = "northeurope"
}

variable "vm_size" {
  default = "Standard_D1_v2"
}

variable "lb_backend_pool_name" {
  default = "backendPool1"
}

variable "lb_probe_name" {
  default = "tcpProbe"
}

variable "weave_token" {}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "cloudflare_domain" {}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "swarm" {
  name     = "${var.resource_name_prefix}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "swarm" {
  name                = "${var.resource_name_prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
}

resource "azurerm_subnet" "swarm" {
  name                 = "${var.resource_name_prefix}-sn"
  resource_group_name  = "${azurerm_resource_group.swarm.name}"
  virtual_network_name = "${azurerm_virtual_network.swarm.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "swarm-manager" {
  name                         = "${var.resource_name_prefix}-ip-manager"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-manager"
  public_ip_address_allocation = "static"
}

resource "azurerm_public_ip" "swarm-worker" {
  count                        = "2"
  name                         = "${var.resource_name_prefix}-ip-worker-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-worker-${count.index}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_public_ip" "swarm-lb" {
  name                         = "${var.resource_name_prefix}-ip-lb"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-lb"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "swarm" {
  name                = "${var.resource_name_prefix}-lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  frontend_ip_configuration {
    name                 = "${var.resource_name_prefix}-lb-fe-ipconfig"
    public_ip_address_id = "${azurerm_public_ip.swarm-lb.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "swarm" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarm.id}"
  name                = "${var.lb_backend_pool_name}"
}

resource "azurerm_network_interface" "swarm-manager" {
  depends_on                = ["azurerm_lb_backend_address_pool.swarm"]
  name                      = "${var.resource_name_prefix}-manager-ni"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.swarm.name}"
  network_security_group_id = "${module.nsg.id}"

  ip_configuration {
    name                                    = "${var.resource_name_prefix}-manager-ipconfig"
    subnet_id                               = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.swarm-manager.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"]
  }
}

resource "azurerm_network_interface" "swarm-worker" {
  depends_on                = ["azurerm_lb_backend_address_pool.swarm"]
  count                     = "2"
  name                      = "${var.resource_name_prefix}-worker-ni-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.swarm.name}"
  network_security_group_id = "${module.nsg.id}"

  ip_configuration {
    name                                    = "${var.resource_name_prefix}-worker-ipconfig-${count.index}"
    subnet_id                               = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.swarm-worker.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"]
  }
}

module "nsg" {
  source              = "./modules/nsg"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${var.location}"
}

module "storage" {
  source = "./modules/storage"

  prefix              = "${var.resource_name_prefix}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${var.location}"
}

resource "azurerm_availability_set" "swarm" {
  name                = "${var.resource_name_prefix}-availability-set"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${var.location}"
}

module "manager-vm" {
  source = "./modules/vm"

  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  location              = "${var.location}"
  network_interface_ids = ["${azurerm_network_interface.swarm-manager.id}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.swarm.id}"
  container             = "${module.storage.container}"
  fqdns                 = ["${azurerm_public_ip.swarm-manager.fqdn}"]
  csr_password          = "${var.csr_password}"
  weave_token           = "${var.weave_token}"
  label                 = "manager"
}

module "worker-vm" {
  source = "./modules/vm"

  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  location              = "${var.location}"
  network_interface_ids = ["${azurerm_network_interface.swarm-worker.*.id}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.swarm.id}"
  container             = "${module.storage.container}"
  fqdns                 = ["${azurerm_public_ip.swarm-worker.*.fqdn}"]
  csr_password          = "${var.csr_password}"
  weave_token           = "${var.weave_token}"
  label                 = "worker"
  quantity              = 2
}

resource "null_resource" "manager-config" {
  depends_on = ["module.manager-vm"]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${azurerm_public_ip.swarm-manager.fqdn}"
    }

    inline = [
      "sudo docker swarm init --advertise-addr ${azurerm_network_interface.swarm-manager.private_ip_address}:2377",
    ]
  }

  provisioner "local-exec" {
    command = "bash ./get-token.sh ${azurerm_public_ip.swarm-manager.fqdn}"
  }
}

resource "null_resource" "worker-config" {
  depends_on = ["module.worker-vm", "null_resource.manager-config"]
  count      = "2"

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${element(azurerm_public_ip.swarm-worker.*.fqdn, count.index)}"
    }

    inline = [
      "sudo docker swarm join --token ${trimspace(file("./swarm.token"))} ${azurerm_network_interface.swarm-manager.private_ip_address}:2377",
    ]
  }
}

resource "azurerm_lb_probe" "swarm" {
  depends_on          = ["module.worker-vm", "module.worker-vm"]
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarm.id}"
  name                = "${var.lb_probe_name}"
  protocol            = "tcp"
  port                = 22
}

resource "azurerm_lb_rule" "swarm-lb-http" {
  depends_on                     = ["azurerm_lb_probe.swarm"]
  resource_group_name            = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id                = "${azurerm_lb.swarm.id}"
  name                           = "http"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.resource_name_prefix}-lb-fe-ipconfig"
  probe_id                       = "${azurerm_lb.swarm.id}/probes/${var.lb_probe_name}"
  backend_address_pool_id        = "${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"
}

resource "azurerm_lb_rule" "swarm-lb-https" {
  depends_on                     = ["azurerm_lb_probe.swarm"]
  resource_group_name            = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id                = "${azurerm_lb.swarm.id}"
  name                           = "https"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.resource_name_prefix}-lb-fe-ipconfig"
  probe_id                       = "${azurerm_lb.swarm.id}/probes/${var.lb_probe_name}"
  backend_address_pool_id        = "${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"
}

resource "cloudflare_record" "swarm-wildcard" {
  domain = "${var.cloudflare_domain}"
  name   = "*"
  value  = "${azurerm_public_ip.swarm-lb.ip_address}"
  type   = "A"
  ttl    = 120
}

resource "cloudflare_record" "swarm-root" {
  domain  = "${var.cloudflare_domain}"
  name    = "@"
  value   = "${azurerm_public_ip.swarm-lb.ip_address}"
  type    = "A"
  proxied = false
  ttl     = 120
}

output "manager_fqdn" {
  value = "${azurerm_public_ip.swarm-manager.fqdn}"
}

output "manager_ip" {
  value = "${azurerm_public_ip.swarm-manager.ip_address}"
}
