variable "private_ip_address" {}
variable "fqdn" {}
variable "vm_id" {}
variable "label" {}

resource "null_resource" "manager" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "swarmadmin"
      password = "S3cr3tSqu1rr3l"
      host     = "${var.fqdn}"
    }

    inline = [
      "echo Initializing ${var.label}...",
      "sudo docker swarm init --advertise-addr ${var.private_ip_address}",
    ]
  }

  provisioner "local-exec" {
    command = "bash ./get-token.sh ${var.fqdn}"
  }
}

output "token" {
  depends_on = ["null_resource.manager"]
  value      = "${file("./swarm.token")}"
}
