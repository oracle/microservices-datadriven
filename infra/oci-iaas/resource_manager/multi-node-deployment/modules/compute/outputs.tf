output "instance" {
  value = oci_core_instance.compute_instance1
}

output "instance_keys" {
  value = tls_private_key.ssh_keypair
}

output "dbaas_public_ip" {
  value = oci_core_instance.dbaas_instance1.public_ip
}

output "dbaas_private_ip" {
  value = oci_core_instance.dbaas_instance1.private_ip
}

output "dbaas_compute_id" {
  value = oci_core_instance.dbaas_instance1.id
}

output "dbaas_display_name" {
  value = oci_core_instance.dbaas_instance1.display_name
}

