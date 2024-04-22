variable "region" {
  description = "Tenancy region to provision resources in"
}
variable "compartment_ocid" {
  description = "OCID of compartment to provision resources in"
}
variable "jenkins_password" {
  description = "Password for Jenkins admin user"
  type        = string
  sensitive   = true
}

variable "agents" {
  description = "Agents"
  type        = string
  default     = ""
}

variable "autonomous_database_id" {}

variable "deployment" {
  description = "Type of Deployment deploying different Jenkins infrastructure configuration"
}
