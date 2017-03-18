variable "resource_group_name" {}
variable "location" {}
variable "label" {}

variable "network_interface_ids" {
  type = "list"
}

variable "vm_size" {}
variable "availability_set_id" {}
variable "container" {}

variable "fqdns" {
  type = "list"
}

variable "csr_password" {}
variable "weave_token" {}

variable "quantity" {
  default = 1
}

resource "azurerm_virtual_machine" "vm" {
  count                         = "${var.quantity}"
  name                          = "vm-${var.label}-${count.index}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  network_interface_ids         = ["${element(var.network_interface_ids, count.index)}"]
  vm_size                       = "${var.vm_size}"
  availability_set_id           = "${var.availability_set_id}"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.label}${count.index}osdisk1"
    vhd_uri       = "${var.container}/${var.label}${count.index}osdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "swarm${var.label}${count.index}"
    admin_username = "swarmadmin"
    admin_password = "S3cr3tSqu1rr3l"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/swarmadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  tags {
    environment = "production"
  }

  provisioner "local-exec" {
    command = "bash ./generate_cert.sh ${var.label}-${count.index} ${element(var.fqdns, count.index)} ${var.csr_password}"
  }

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${element(var.fqdns, count.index)}"
    }

    source      = "./docker-config/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${element(var.fqdns, count.index)}"
    }

    inline = [
      "curl -fsSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker swarmadmin",
      "sudo bash /tmp/configure_docker.sh ${var.label}-${count.index}",
      "sudo bash /tmp/install_weave.sh ${var.weave_token}",
    ]
  }
}
