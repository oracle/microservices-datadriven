resource "oci_core_public_ip" "jenkins_public_ip" {
  compartment_id = var.compartment_id
  display_name   = "jenkins-vm-public-ip"
  lifetime       = "RESERVED"
}