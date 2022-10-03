output "jenkins_public_ip" {
  value = "http://${oci_core_public_ip.jenkins_public_ip.ip_address}/login"
}

output "generated_ssh_private_key" {
  value     = tls_private_key.tls_key_pair.private_key_pem
  sensitive = true
}