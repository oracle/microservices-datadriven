output "lb_address" {
  value       = oci_load_balancer.lb.ip_addresses
  description = "The Pubic facing IP Address assigned to the Load Balancer"
}