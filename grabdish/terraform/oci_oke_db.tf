//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
variable "ociTenancyOcid" {}
variable "ociUserOcid" {}
variable "ociCompartmentOcid" {}
variable "ociRegionIdentifier" {}
variable "runName" {}
// Set the oci provider
provider "oci" {
  region           = var.ociRegionIdentifier
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
  compartment_id = var.ociTenancyOcid
  ad_number      = 1
}
resource "oci_core_vcn" "okell_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.ociCompartmentOcid
  display_name   = "grabdish"
}
resource "oci_core_internet_gateway" "ig" {
   compartment_id = var.ociCompartmentOcid
   display_name   = "ClusterInternetGateway"
  vcn_id         = oci_core_vcn.okell_vcn.id
}
resource oci_core_private_ip prip {
  display_name = "Service VNIC for cluster"
  freeform_tags = {
  }
  hostname_label = "host-10-0-0-2"
  ip_address     = "10.0.0.2"
  #vlan_id = <<Optional value not found in discovery>>
  #vnic_id = oci_core_public_ip.puip.id
}
resource oci_core_public_ip puip {
  compartment_id = var.ociCompartmentOcid
  display_name = "Floating Public IP for cluster"
  freeform_tags = {
  }
  lifetime      = "RESERVED"
  private_ip_id = oci_core_private_ip.prip.id
  #public_ip_pool_id = <<Optional value not found in discovery>>
}
resource oci_core_nat_gateway ngw {
  block_traffic  = "false"
  compartment_id = var.ociCompartmentOcid
  display_name = "ngw"
  freeform_tags = {
  }
  public_ip_id = "oci_core_public_ip.puip.id"
  vcn_id       = oci_core_vcn.okell_vcn.id
}
#resource oci_core_service_gateway sg {
#  compartment_id = var.ociCompartmentOcid
#  display_name = "grabdish"
#  freeform_tags = {
#  }
#  #route_table_id = <<Optional value not found in discovery>>
#  services {
#    service_id = "ocid1.service.oc1.us-sanjose-1.aaaaaaaa7w72lnqlnse4zc5vubcjv6mhsooz3jlaazcbzq7hnzih26qqiw6a"
#  }
#  vcn_id = oci_core_vcn.okell_vcn.id
#}
resource oci_core_route_table private {
  compartment_id = var.ociCompartmentOcid
  display_name = "private"
  freeform_tags = {
  }
  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
#  route_rules {
#    description       = "traffic to OCI services"
#    destination       = "all-sjc-services-in-oracle-services-network"
#    destination_type  = "SERVICE_CIDR_BLOCK"
#    network_entity_id = oci_core_service_gateway.sg.id
#  }
  vcn_id = oci_core_vcn.okell_vcn.id
}
resource oci_core_default_route_table public {
  display_name = "public"
  freeform_tags = {
  }
  manage_default_resource_id = oci_core_vcn.okell_vcn.default_route_table_id
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}
resource "oci_core_subnet" "endpoint_Subnet" {
  #Required
  #availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.0.0/28"
  compartment_id      = var.ociCompartmentOcid
   vcn_id              = oci_core_vcn.okell_vcn.id
  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_security_list.endpoint.id]
  display_name      = "SubNet1ForEndpoint"
  route_table_id    = oci_core_vcn.okell_vcn.default_route_table_id
}
resource "oci_core_subnet" "nodePool_Subnet" {
  #Required
  #availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.10.0/24"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_security_list.nodePool.id]
  display_name      = "SubNet1ForNodePool"
  route_table_id    = oci_core_route_table.private.id
}
resource "oci_core_subnet" "svclb_Subnet" {
  #Required
  #availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.20.0/24"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_default_security_list.svcLB.id]
  display_name      = "SubNet1ForSvcLB"
  route_table_id    = oci_core_vcn.okell_vcn.default_route_table_id
}
resource oci_core_security_list nodePool {
  compartment_id = var.ociCompartmentOcid
  display_name = "nodepool"
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "all"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "6443"
      min = "6443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "12250"
      min = "12250"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
/*  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = "all-sjc-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
*/
 egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "all"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  freeform_tags = {
  }
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "all"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "31750"
      min = "31750"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "10.0.20.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "10256"
      min = "10256"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  vcn_id = oci_core_vcn.okell_vcn.id
}

resource oci_core_security_list endpoint {
  compartment_id = var.ociCompartmentOcid
  display_name = "endpoint"
/*  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = "all-sjc-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
*/
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  freeform_tags = {
  }
  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  vcn_id = oci_core_vcn.okell_vcn.id
}

resource oci_core_default_security_list svcLB {
  display_name = "svcLB"
  egress_security_rules {
    #description = <<Optional value not found in discovery>>
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "31750"
      min = "31750"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  egress_security_rules {
    #description = <<Optional value not found in discovery>>
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    #icmp_options = <<Optional value not found in discovery>>
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "10256"
      min = "10256"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  freeform_tags = {
  }
  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "443"
      min = "443"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  manage_default_resource_id = oci_core_vcn.okell_vcn.default_security_list_id
}

resource "oci_containerengine_cluster" "okell_cluster" {
  #Required
  compartment_id     = var.ociCompartmentOcid
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids = [
    ]
    subnet_id = oci_core_subnet.endpoint_Subnet.id
  }
  kubernetes_version = "v1.19.7"
  name               = "grabdish"
  vcn_id             = oci_core_vcn.okell_vcn.id
  #Optional
  options {
    service_lb_subnet_ids = [oci_core_subnet.svclb_Subnet.id]
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
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}
resource "oci_containerengine_node_pool" "okell_node_pool" {
  #Required
  cluster_id         = oci_containerengine_cluster.okell_cluster.id
  compartment_id     = var.ociCompartmentOcid
  kubernetes_version = "v1.19.7"
  name               = "Pool"
  node_shape         = "VM.Standard.E2.1"
  #subnet_ids         = [oci_core_subnet.nodePool_Subnet_1.id]
  #Optional
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.nodePool_Subnet.id
    }
    size = "3"
  }
  node_source_details {
    #Required
    image_id    = local.oracle_linux_images.0 # Latest
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
  all_sources = data.oci_containerengine_node_pool_option.okell_node_pool_option.sources
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
  compartment_id = var.ociTenancyOcid
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
  db_name                  = "${var.runName}X1"
  # is_free_tier = true , if there exists sufficient service limit
  is_free_tier             = false
  #Optional #db_workload = "${var.autonomous_database_db_workload}"
  db_workload                                    = var.autonomous_database_db_workload
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
  db_name                  = "${var.runName}X2" 
  is_free_tier             = false
  db_workload                                    = var.autonomous_database_db_workload
  // Autonomous Database name cannot be longer than 14 characters.
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