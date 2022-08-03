# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_load_balancer" "lb" {
  compartment_id = local.compartment_ocid
  display_name   = format("%s-lb", upper(var.proj_abrv))
  shape          = "flexible"
  is_private     = false
  shape_details {
      minimum_bandwidth_in_mbps = var.flex_lb_min_shape[local.sizing]
      maximum_bandwidth_in_mbps = var.flex_lb_max_shape[local.sizing]
  }
  subnet_ids = [
    oci_core_subnet.subnet_public.id
  ]
  network_security_group_ids = [oci_core_network_security_group.security_group_lb.id]
}

resource "oci_load_balancer_backend_set" "lb_backend_set" {
  load_balancer_id = oci_load_balancer.lb.id
  name             = format("%s-lb-backend-set", upper(var.proj_abrv))
  policy           = "LEAST_CONNECTIONS"
  session_persistence_configuration {
    cookie_name = "*"
  }
  health_checker {
    interval_ms         = "10000"
    port                = "8080"
    protocol            = "HTTP"
    response_body_regex = ""
    retries             = "3"
    return_code         = "200"
    timeout_in_millis   = "3000"
    url_path            = "/favicon.ico"
  }
}

resource "oci_load_balancer_backend" "lb_backend" {
  load_balancer_id = oci_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.lb_backend_set.name
  ip_address       = oci_core_instance.instance.private_ip
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_listener" "lb_listener_80" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = format("%s-lb-listener-80", upper(var.proj_abrv))
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
}

// Ignore changes to avoid overwriting valid certs loaded in later
resource "oci_load_balancer_listener" "lb_listener_443" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = format("%s-lb-listener-443", upper(var.proj_abrv))
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  port                     = 443
  protocol                 = "HTTP"
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_certificate.certificate_name
    verify_peer_certificate = false
  }
  lifecycle {
    ignore_changes = [ssl_configuration[0].certificate_name]
  }
}

resource "oci_load_balancer_certificate" "lb_certificate" {
  certificate_name = "get_a_real_cert"
  load_balancer_id = oci_load_balancer.lb.id

  ca_certificate     = tls_self_signed_cert.acme_ca.cert_pem
  public_certificate = tls_locally_signed_cert.example_com.cert_pem
  private_key        = tls_private_key.example_com.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}
