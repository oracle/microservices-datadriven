output "lb_address" {
  value       = oci_load_balancer.lb.ip_addresses[0]
  description = "The Public facing IP Address assigned to the instance"
}

output "ords_address" {
  value       = oci_core_instance.instance.public_ip
  description = "The Public facing IP Address assigned to the ORDS instance"
}

output "db_ocid" {
  value       = oci_database_autonomous_database.autonomous_database.id
  description = "The OCID of the ATP database"
}
