output "jenkins_public_ip" {
  value = "http://${oci_core_public_ip.Jenkins_public_ip.ip_address}"
}


output "generated_ssh_private_key" {
  value = tls_private_key.public_private_key_pair.private_key_pem
  sensitive = true
}