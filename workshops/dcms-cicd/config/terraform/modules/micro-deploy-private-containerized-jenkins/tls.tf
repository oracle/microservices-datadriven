resource "tls_private_key" "tls_key_pair" {
  algorithm = "RSA"
}

resource "tls_private_key" "jenkins_lb_tls_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}