variable compartment_ocid {}
variable region {}

variable deployment {
  description = "Type of Deployment"
  default = "MDPJ"
}

variable jenkins_password {
  description = "Jenkins password to login with"
  sensitive = true
}

locals {
  micro-deployment-public-jenkins : var.deployment == "MDPJ"
}