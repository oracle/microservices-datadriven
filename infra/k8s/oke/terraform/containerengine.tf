//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_containerengine_cluster" "oke" {
  #Required
  compartment_id = var.ociCompartmentOcid
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids = [
    ]
    subnet_id = oci_core_subnet.endpoint.id
  }
  kubernetes_version = var.kubernetes_version
  name               = "grabdish"
  vcn_id             = data.oci_core_vcn.vcn.id
  #Optional
  options {
    service_lb_subnet_ids = [oci_core_subnet.svclb.id]
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
  cluster_id         = oci_containerengine_cluster.oke.id
  compartment_id     = var.ociCompartmentOcid
  kubernetes_version = var.kubernetes_version
  name               = "Pool"
  node_shape         = "VM.Standard.E2.1"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.nodepool.id
    }
    size = "3"
  }
  node_source_details {
    image_id    = local.oracle_linux_images.0 # Latest
    source_type = "IMAGE"
  }
}

data "oci_containerengine_node_pool_option" "okell_node_pool_option" {
  node_pool_option_id = "all"
}

locals {
  all_sources         = data.oci_containerengine_node_pool_option.okell_node_pool_option.sources
  oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*", source.source_name)) > 0]
}

output "oke_ocid" {
  value = oci_containerengine_cluster.oke.id
}
