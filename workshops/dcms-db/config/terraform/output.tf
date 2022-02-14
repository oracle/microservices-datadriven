output "lb_address" {
  value       = oci_core_instance.instance.public_ip
  description = "The Pubic facing IP Address assigned to the instance"
}
