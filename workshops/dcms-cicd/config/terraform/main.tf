
module micro-deployment-public-jenkins {
  source = "modules/micro-deployment-public-dockerized-jenkins"

  compartment_ocid = var.compartment_ocid
  jenkins_password = var.jenkins_password
  region = var.region

  count = local.micro-deployment-public-jenkins ? 1 : 0
}