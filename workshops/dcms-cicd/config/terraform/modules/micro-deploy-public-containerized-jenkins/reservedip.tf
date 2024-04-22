

resource "oci_core_public_ip" "jenkins_public_ip" {
  compartment_id = var.compartment_id
  display_name   = "jenkins-vm-public-ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.jenkins_private_ip.private_ips[0]["id"]
}