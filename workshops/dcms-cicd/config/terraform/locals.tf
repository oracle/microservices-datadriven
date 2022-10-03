locals {
  micro-deployment-public-jenkins    = var.deployment == "MDPUBJ" ? true : false
  micro-deployment-private-jenkins   = var.deployment == "MDPRVJ" ? true : false
  distributed-builds-private-jenkins = var.deployment == "DBPRVJ" ? true : false
}