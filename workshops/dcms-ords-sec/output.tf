
output "lb_address" {
  value       = oci_load_balancer.lb.ip_addresses[0]
  description = "The Pubic facing IP Address assigned to the Load Balancer"
}

output "ADMIN_Password" {
  value = "You must reset the ADB ADMIN password manually in the OCI console for security reasons"
}

output "forward_ssh_cmd" {
  description = "SSH tunnel to ADB-S Instance"
  value = local.bastion_tunnel
}

output "bastion_ssh_cmd" {
  description = "SSH to ORDS Server"
  value = local.bastion_ssh
}

output "dbconn" {
  description = "Database connection string"
  value = replace(element([for i, v in oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles :
                        v.value if v.consumer_group == "TP" && v.tls_authentication == "SERVER"],0),"\"","'")
}