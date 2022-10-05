module "micro-deploy-public-containerized-jenkins" {
  source                 = "./modules/micro-deploy-public-containerized-jenkins"
  compartment_id         = var.compartment_ocid
  jenkins_password       = var.jenkins_password
  region                 = var.region
  autonomous_database_id = var.autonomous_database_id

  count = local.micro-deployment-public-jenkins ? 1 : 0
}

module "micro-deploy-private-containerized-jenkins" {
  source           = "./modules/micro-deploy-private-containerized-jenkins"
  compartment_id   = var.compartment_ocid
  jenkins_password = var.jenkins_password
  region           = var.region

  count = local.micro-deployment-private-jenkins ? 1 : 0
}

module "distributed-builds-private-jenkins" {
  source             = "./modules/controller-agent-private-containerized-jenkins"
  compartment_id     = var.compartment_ocid
  jenkins_password   = var.jenkins_password
  region             = var.region
  unique_agent_names = split(" ", var.agents)

  count = local.distributed-builds-private-jenkins ? 1 : 0
}