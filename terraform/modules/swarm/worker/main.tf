variable "private_ip_address" {}

variable "fqdns" {
  type = "list"
}

variable "vm_ids" {
  type = "list"
}

variable "quantity" {}
variable "token" {}

resource "null_resource" "worker" {
  count = "${var.quantity}"

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${element(var.fqdns, count.index)}"
    }

    inline = [
      "sudo docker swarm init --advertise-addr ${var.private_ip_address}",
    ]
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${element(var.fqdns, count.index)}"
    }

    inline = [
      "sudo docker swarm join --token ${var.token} ${var.private_ip_address}:2377",
    ]
  }
}
