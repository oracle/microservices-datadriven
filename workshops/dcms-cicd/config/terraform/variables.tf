variable region {
  description = "Tenancy region to provision resources in"
}
variable compartment_ocid {
  description = "OCID of compartment to provision resources in"
}
variable jenkins_password {
  description = "Password for Jenkins admin user"
  type = string
  sensitive = true
}
variable deployment {
  description = "Type of Deployment deploying different Jenkins infrastrcuture configuration"
}
locals {
  micro-deployment-public-jenkins : var.deployment == "MDPJ"
}