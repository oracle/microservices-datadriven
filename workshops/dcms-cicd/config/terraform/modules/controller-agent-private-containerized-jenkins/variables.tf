variable "region" {
  description = "Tenancy region to provision resources in"
}
variable "compartment_id" {
  description = "OCID of compartment to provision resources in"
}
variable "unique_agent_names" {
  type        = list(string)
  description = ""
}
variable "jenkins_password" {
  description = "Password for Jenkins admin user"
  type        = string
  sensitive   = true
}

variable "availability_domain_name" {
  description = "Availability Domain to provision the compute instance in"
  default     = null
}
variable "vcn_name" {
  default = "jenkins-vcn"
}
variable "vcn_cidr" {
  description = "VCN CIDR IP Block"
  default     = "10.0.0.0/16"
}
variable "vcn_dns" {
  description = "VCN subnet DNS record"
  default     = "jnknsvcn"
}

variable "load_balancer_shape" {
  description = "A template that determines the total pre-provisioned bandwidth"
  default     = "flexible"
}
variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  description = "Bandwidth in Mbps that determines the maximum bandwidth (ingress plus egress) that the load balancer can achieve"
  default     = "100"
}
variable "load_balancer_shape_details_minimum_bandwidth_in_mbps" {
  description = "Bandwidth in Mbps that determines the total pre-provisioned bandwidth (ingress plus egress)"
  default     = "10"
}
variable "backend_set_name" {
  description = "Name of Load Balancer backend set"
  default     = "jnkns-backend-set"
}
variable "backend_set_health_checker_port" {
  description = "The backend server port against which to run the health check"
  default     = 80
}
variable "bastion_name" {
  description = "Bastion name"
  default     = "jenkinsbastion"
}
variable "bastion_agent_name" {
  description = "Bastion name"
  default     = "jenkinsagentbastion"
}

variable "instance_shape" {
  description = "Shape of Jenkins VM compute instance to provision and install Jenkins in"
  default     = "VM.Standard.E3.Flex"
}
variable "instance_ocpus" {
  description = "Number of OCPUs the Jenkins VM compute instance will have"
  default     = 1
}
variable "instance_shape_config_memory_in_gbs" {
  description = ""
  default     = 16
}
variable "instance_os" {
  description = "Operating system of Jenkins VM compute instance"
  default     = "Oracle Linux"
}
variable "linux_os_version" {
  description = "Operating system version"
  default     = "7.9"
}
variable "jenkins_user" {
  description = "The username for Jenkins admin user"
  type        = string
  default     = "admin"
}
variable "session_display_name" {
  description = "Bastion session name connecting to Jenkins"
  type        = string
  default     = "jenkins-bastion-session"
}
variable "session_agent_display_name" {
  description = "Bastion session name connecting to Jenkins Agent"
  type        = string
  default     = "jenkins-agent-bastion-session"
}
variable "session_ttl_in_seconds" {
  description = "The amount of time the session can remain active"
  default     = 1800
}
variable "generate_public_ssh_key" {
  default = true
}
variable "public_ssh_key" {
  default = ""
}


locals {
  availability_domain_name   = var.availability_domain_name != null ? var.availability_domain_name : data.oci_identity_availability_domains.ADs.availability_domains[0].name
  instance_shape             = var.instance_shape
  compute_flexible_shapes    = ["VM.Standard.E3.Flex", "VM.Standard.E4.Flex"]
  is_flexible_instance_shape = contains(local.compute_flexible_shapes, local.instance_shape)
}