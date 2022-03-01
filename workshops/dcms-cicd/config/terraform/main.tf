
module micro-deploy-public-containerized-jenkins {
  source = "modules/micro-deploy-public-containerized-jenkins"
  compartment_id = var.compartment_ocid
  jenkins_password = var.jenkins_password
  region = var.region

  count = local.micro-deployment-public-jenkins ? 1 : 0
}