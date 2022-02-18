output "lb_address" {
  value       = oci_load_balancer.lb.ip_addresses
  description = "The Public facing IP Address assigned to the instance"
}
