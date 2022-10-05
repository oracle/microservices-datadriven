
resource "oci_load_balancer_load_balancer" "load_balancer" {
  #Required
  compartment_id = var.compartment_id
  display_name   = "jenkins-load-balancer"
  shape          = var.load_balancer_shape
  subnet_ids     = [oci_core_subnet.pub_jenkins_lb_subnet.id]

  reserved_ips {
    id = oci_core_public_ip.jenkins_public_ip.id
  }
  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }

  defined_tags  = {}
  freeform_tags = {}
}

resource "oci_load_balancer_backend_set" "backend_set" {
  #Required
  health_checker {
    #Required
    protocol = "TCP"
    port     = var.backend_set_health_checker_port
  }

  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  name             = var.backend_set_name
  policy           = "ROUND_ROBIN"

}

resource "oci_load_balancer_backend" "backend" {
  backendset_name  = oci_load_balancer_backend_set.backend_set.name
  ip_address       = oci_core_instance.jenkins_vm.private_ip
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  port             = 80
}


resource "oci_load_balancer_listener" "jenkins_lb_listener_with_ssl" {
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.backend_set.name
  port                     = 80
  protocol                 = "HTTP"
}