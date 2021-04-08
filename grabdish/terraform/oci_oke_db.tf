variable "ociTenancyOcid" {}
variable "ociUserOcid" {}
variable "ociCompartmentOcid" {}
variable "ociRegionIdentifier" {}
variable "runName" {}
// Set the oci provider
provider "oci" {
  region           = "${var.ociRegionIdentifier}"
}
//------- Create repos End  ------------------------------------------
/*
resource "oci_artifacts_container_repository" "frontend_helidon_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/frontend-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "helidonatp_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/admin-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "order-helidon_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/order-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "supplier-helidon-se_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/supplier-helidon-se"
  is_public = true
}
resource "oci_artifacts_container_repository" "inventory-helidon_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/inventory-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "inventory-python_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/inventory-python"
  is_public = true
}
resource "oci_artifacts_container_repository" "nodejs_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/inventory-nodejs"
  is_public = true
}
resource "oci_artifacts_container_repository" "inventory-helidon-se_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/inventory-helidon-se"
  is_public = true
}
*/

data "oci_identity_availability_domain" "ad1" {
  compartment_id = "${var.ociTenancyOcid}"
  ad_number      = 1
}
resource "oci_core_vcn" "okell_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.ociCompartmentOcid
  display_name   = "VcnForClusters"
}
resource "oci_core_internet_gateway" "okell_ig" {
   compartment_id = var.ociCompartmentOcid
   display_name   = "ClusterInternetGateway"
  vcn_id         = oci_core_vcn.okell_vcn.id
}
resource "oci_core_route_table" "okell_route_table" {
  compartment_id = var.ociCompartmentOcid
  vcn_id         = oci_core_vcn.okell_vcn.id
  display_name   = "ClustersRouteTable"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.okell_ig.id
  }
}
resource "oci_core_subnet" "clusterSubnet_1" {
  #Required
  #availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.20.0/24"
  compartment_id      = var.ociCompartmentOcid
   vcn_id              = oci_core_vcn.okell_vcn.id
  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.okell_vcn.default_security_list_id]
  display_name      = "SubNet1ForClusters"
  route_table_id    = oci_core_route_table.okell_route_table.id
}
resource "oci_core_subnet" "nodePool_Subnet_1" {
  #Required
  #availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.22.0/24"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.okell_vcn.default_security_list_id]
  display_name      = "SubNet1ForNodePool"
  route_table_id    = oci_core_route_table.okell_route_table.id
}
resource "oci_containerengine_cluster" "okell_cluster" {
  #Required
  compartment_id     = var.ociCompartmentOcid
  kubernetes_version = "v1.19.7"
  name               = "grabdish"
  vcn_id             = oci_core_vcn.okell_vcn.id
  #Optional
  options {
    service_lb_subnet_ids = [oci_core_subnet.clusterSubnet_1.id]
    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "false"
      is_tiller_enabled               = "false"
    }
    admission_controller_options {
      #Optional
      is_pod_security_policy_enabled = "false"
    }
    kubernetes_network_config {
      #Optional
      pods_cidr     = "10.1.0.0/16"
      services_cidr = "10.2.0.0/16"
    }
  }
}
resource "oci_containerengine_node_pool" "okell_node_pool" {
  #Required
  cluster_id         = oci_containerengine_cluster.okell_cluster.id
  compartment_id     = var.ociCompartmentOcid
  kubernetes_version = "v1.19.7"
  name               = "Pool"
  node_shape         = "VM.Standard2.1"
  #subnet_ids         = [oci_core_subnet.nodePool_Subnet_1.id]
  #Optional
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.nodePool_Subnet_1.id
    }
    size = "3"
  }
  node_source_details {
    #Required
    image_id    = local.oracle_linux_images.0
    source_type = "IMAGE"
    #Optional
    #boot_volume_size_in_gbs = "60"
  }
  //quantity_per_subnet = 1
  //ssh_public_key      = var.node_pool_ssh_public_key
  //ssh_public_key =  var.resUserPublicKey
}
data "oci_containerengine_cluster_option" "okell_cluster_option" {
  cluster_option_id = "all"
}
data "oci_containerengine_node_pool_option" "okell_node_pool_option" {
  node_pool_option_id = "all"
}
locals {
  all_sources = "${data.oci_containerengine_node_pool_option.okell_node_pool_option.sources}"
  oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",source.source_name)) > 0]
}
output "cluster_kubernetes_versions" {
  value = [data.oci_containerengine_cluster_option.okell_cluster_option.kubernetes_versions]
}
output "node_pool_kubernetes_version" {
  value = [data.oci_containerengine_node_pool_option.okell_node_pool_option.kubernetes_versions]
}
data "oci_containerengine_cluster_kube_config" "okell_cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.okell_cluster.id
  #Optional
  token_version = "2.0.0"
}
resource "local_file" "okell_cluster_kube_config_file" {
  content  = data.oci_containerengine_cluster_kube_config.okell_cluster_kube_config.content
  filename = "${path.module}/okell_cluster_kubeconfig"
}
data "oci_identity_availability_domains" "okell_availability_domains" {
  //compartment_id = var.tenancy_ocid
  compartment_id = "${var.ociTenancyOcid}"
}
variable "InstanceImageOCID" {
  type = map(string)
  default = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    // Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaadjnj3da72bztpxinmqpih62c2woscbp6l3wjn36by2cvmdhjub6a"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaawufnve5jxze4xf7orejupw5iq3pms6cuadzjc7klojix6vmk42va"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaagbrvhganmn7awcr7plaaf5vhabmzhx763z5afiitswjwmzh7upna"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaajwtut4l7fo3cvyraate6erdkyf2wdk5vpk6fp6ycng3dv2y3ymvq"
  }
}
//================= create ATP Instance =======================================
variable "autonomous_database_db_workload" { default = "OLTP" }
variable "autonomous_database_defined_tags_value" { default = "value" }
variable "autonomous_database_license_model" { default = "BRING_YOUR_OWN_LICENSE" }
variable "autonomous_database_is_dedicated" { default = false }
resource "random_string" "autonomous_database_wallet_password" {
  length  = 16
  special = true
}
resource "random_password" "database_admin_password" {
  length  = 12
  upper   = true
  lower   = true
  number  = true
  special = false
}
resource "oci_database_autonomous_database" "autonomous_database_atp" {
  #Required
  admin_password           = random_password.database_admin_password.result
  compartment_id           = var.ociCompartmentOcid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  //db_name = "ORDERDB${random_string.upper.result}"
  db_name = "ORDERDB"
  # is_free_tier = true , if there exists sufficient service limit
  is_free_tier             = false
  #Optional #db_workload = "${var.autonomous_database_db_workload}"
  db_workload                                    = var.autonomous_database_db_workload
  //display_name                                   = "ORDERDB${random_string.upper.result}"
  display_name ="ORDERDB"
  is_auto_scaling_enabled                        = "false"
  is_preview_version_with_service_terms_accepted = "false"
}
//================= create ATP Instance 2 =======================================
resource "oci_database_autonomous_database" "autonomous_database_atp2" {
  #Required
  admin_password           = random_password.database_admin_password.result
  compartment_id           = var.ociCompartmentOcid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  //db_name = "INVENTORYDB${random_string.upper.result}"
  db_name = "INVENTORYDB"
  is_free_tier             = false
  db_workload                                    = var.autonomous_database_db_workload
  // Autonomous Database name cannot be longer than 14 characters.
  //display_name                                   = "INVENTORYDB${random_string.upper.result}"
  display_name = "INVENTORYDB"
  is_auto_scaling_enabled                        = "false"
  is_preview_version_with_service_terms_accepted = "false"
}
data "oci_database_autonomous_databases" "autonomous_databases_atp" {
  #Required
  compartment_id = var.ociCompartmentOcid
  #Optional
  display_name =  "ORDERDB"
  db_workload  = var.autonomous_database_db_workload
}
data "oci_database_autonomous_databases" "autonomous_databases_atp2" {
  #Required
  compartment_id = var.ociCompartmentOcid
  #Optional
  // display_name = "INVENTORYDB${random_string.upper.result}"
  display_name = "INVENTORYDB"
  db_workload  = var.autonomous_database_db_workload
}
//======= Name space details ------------------------------------------------------
data "oci_objectstorage_namespace" "test_namespace" {
  #Optional
  compartment_id = var.ociCompartmentOcid
}
//========= Outputs ===========================
output "ns_objectstorage_namespace" { 
  value =  [ data.oci_objectstorage_namespace.test_namespace.namespace ]
}
output "autonomous_database_admin_password" {
  value =  [ "Welcome12345" ]
}
