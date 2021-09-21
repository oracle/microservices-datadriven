locals {
  compartment_id                  = var.target_compartment_id
  vcn_id                          = var.vcn_id
  all_cidr                        = "0.0.0.0/0"
  current_time                    = formatdate("YYYYMMDDhhmmss", timestamp())
  app_name                        = "grabdish-microsvc"
  app_compute_instance1_name      = "grabdish-compute1"
  app_db_instance1_name          = "grabdish-database1"
  display_name                    = join("-", [local.app_name, local.current_time])
  compartment_name                = data.oci_identity_compartment.this.name
  grabdish_app_password   = var.grabdish_application_password
  grabdish_db_password      = var.grabdish_database_password
  dynamic_group_tenancy_level     = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in tenancy"
  dynamic_group_compartment_level = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in compartment ${local.compartment_name}"
  num_of_ads                      = length(data.oci_identity_availability_domains.ads.availability_domains)
  ads = local.num_of_ads > 1 ? flatten([
    for ad_shapes in data.oci_core_shapes.this : [
      for shape in ad_shapes.shapes : ad_shapes.availability_domain if shape.name == var.instance_shape
    ]
  ]) : [for ad in data.oci_identity_availability_domains.ads.availability_domains : ad.name]
}


resource "oci_core_network_security_group" "nsg" {
  compartment_id = local.compartment_id                   # Required
  vcn_id         = local.vcn_id                           # Required
  display_name   = "${local.display_name}-security-group" # Optional
  freeform_tags  = var.common_tags
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional         
      max = "22"                                                     # Required
      min = "22"                                                     # Required
    }
  }
  description = "ssh only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_https" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional
      max = "443"                                                     # Required
      min = "443"                                                     # Required
    }
  }
  description = "https only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional
      max = "80"                                                     # Required
      min = "80"                                                     # Required
    }
  }
  description = "http only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_sqlnet" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional
      max = "1521"                                                     # Required
      min = "1521"                                                     # Required
    }
  }
  description = "sqlnet 1521 only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3_4" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
    code = "4"                                                       # Required
  }
  description = "icmp option 1" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = "10.0.0.0/16"                          # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
  }
  description = "icmp option 2" # Optional
}

resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "EGRESS"                               # Required
  protocol                  = "6"                                    # Required
  destination               = local.all_cidr                         # Required
  destination_type          = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  description               = "connect to any network"
}

# Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "this" {
  compartment_id           = local.compartment_id # Required
  operating_system         = var.image_os         # Optional
  operating_system_version = var.image_os_version # Optional
  shape                    = var.instance_shape   # Optional
  sort_by                  = "TIMECREATED"        # Optional
  sort_order               = "DESC"               # Optional
}

data "oci_core_shapes" "this" {
  count = local.num_of_ads > 1 ? local.num_of_ads : 0
  #Required
  compartment_id = local.compartment_id

  #Optional
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index].name
  image_id            = data.oci_core_images.this.images[0].id
}

data "oci_identity_compartment" "this" {
  id = local.compartment_id
}

# Generate the private and public key pair
resource "tls_private_key" "ssh_keypair" {
  algorithm = "RSA" # Required
  rsa_bits  = 2048  # Optional
}

resource "oci_identity_dynamic_group" "for_instance" {
  compartment_id = var.tenancy_ocid
  description    = "To Access OCI CLI"
  name           = "${local.display_name}-dynamic-group"
  matching_rule  = "ANY {instance.id = '${oci_core_instance.compute_instance1.id}'}"
  freeform_tags  = var.common_tags
}

resource "oci_identity_policy" "dg_manage_all" {
  compartment_id = var.use_tenancy_level_policy ? var.tenancy_ocid : local.compartment_id
  description    = "To Access OCI CLI"
  name           = "${local.display_name}-instance-policy"
  statements     = var.use_tenancy_level_policy ? [local.dynamic_group_tenancy_level] : [local.dynamic_group_compartment_level]
  freeform_tags  = var.common_tags
}

resource "oci_core_instance" "dbaas_instance1" {
  availability_domain = local.ads[0]
  compartment_id = local.compartment_id
  shape = var.instance_shape
  preserve_boot_volume = false
  freeform_tags = var.common_tags
  display_name = local.app_db_instance1_name

  create_vnic_details {
    subnet_id = var.subnet_id
    assign_public_ip = true
    nsg_ids = [
      oci_core_network_security_group.nsg.id]
  }

  source_details {
    source_type = "image"
    #source_id   = data.oci_core_images.this.images[0].id
    #source_id = "ocid1.image.oc1.iad.aaaaaaaaudkqtvbfo4mm3qyhqdrpqcatijjmml2z7ddal7hojhb2gcv34kaq" # Custom Compute
    #source_id = "ocid1.image.oc1..aaaaaaaa7cr4xiwx6mbdrgfbppdypdtzyxothft2sjqftygtpxnulqmk6tla" # Platform Image
    #source_id = "ocid1.appcataloglisting.oc1..aaaaaaaan5rb524w7axx36ukn42l7fwzyzm3kodad7x5hxyeyz4nyy3yefgq" # Marketplace Image
    #source_id ="ocid1.image.oc1..aaaaaaaamotrq5ou4qjsnzw5sv7w2nbwvhhp4kjmazlxf23ozcsd66t3pw5q" #LiveLabs Converged DB
    source_id ="ocid1.image.oc1.iad.aaaaaaaajv4k3wrfdrxwapmewcw37oxsroms3f7hmrk2mc7hepweiy3cbtja" #docker-db-21c-prega

    # DB-Base Image
  }

  metadata = {
    ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
    user_data           = base64encode(file("./modules/compute/scripts/bootstrap_database_docker.sh"))
    tenancy_id = var.tenancy_ocid
    grabdish_application_password = var.grabdish_application_password
    grabdish_database_password = var.grabdish_database_password
    app_public_repo = var.app_public_repo
    iaas_public_repo = var.iaas_public_repo
    #dbaas_FQDN =  var.dbaas_FQDN
    target_compartment_id =var.target_compartment_id
    vcn_id = var.vcn_id
    subnet_id = var.subnet_id
    image_os = var.image_os
    image_os_version = var.image_os_version
    instance_shape = var.instance_shape

  }
}

resource "oci_core_instance" "compute_instance1" {
  availability_domain  = local.ads[0]
  compartment_id       = local.compartment_id
  shape                = var.instance_shape
  preserve_boot_volume = false
  freeform_tags        = var.common_tags
  display_name        = local.app_compute_instance1_name


  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.nsg.id]
  }

  source_details {
    source_type = "image"
    #source_id   = data.oci_core_images.this.images[0].id
    #source_id = "ocid1.image.oc1.iad.aaaaaaaaudkqtvbfo4mm3qyhqdrpqcatijjmml2z7ddal7hojhb2gcv34kaq" # Custom Compute
    #source_id = "ocid1.image.oc1..aaaaaaaa7cr4xiwx6mbdrgfbppdypdtzyxothft2sjqftygtpxnulqmk6tla" # DB-Base Image
    #source_id ="ocid1.image.oc1.iad.aaaaaaaad5tynmdcvyyt7idrox2ciuq6jlgjmivfgud6rs76dubivyufe6wq" # microservices-2-cm
    #source_id="ocid1.image.oc1.phx.aaaaaaaaw6pi7tnx2pvqgzi2lgpsicjj5cl46a3llrk6nghgbthve7f72v6a"  #microservices-phx-1

    #source_id="ocid1.image.oc1.iad.aaaaaaaa643d766gxmmzk7gul6557hnp53ul3wieu4al3qjpaiklk3mom2ba" #microservices-ash-1-cm
    #source_id="ocid1.image.oc1.iad.aaaaaaaad5tynmdcvyyt7idrox2ciuq6jlgjmivfgud6rs76dubivyufe6wq" #microservices-2-cm
    #source_id="ocid1.image.oc1.iad.aaaaaaaafwnzt3vu4ebfvrhsilrqv7i2ykv2osdmf42rjtq72nxi5qldt6ua" #microservices-ash-2-cm
    #source_id="ocid1.image.oc1.iad.aaaaaaaad5tynmdcvyyt7idrox2ciuq6jlgjmivfgud6rs76dubivyufe6wq" #microservices-2-cm
    source_id = "ocid1.image.oc1.iad.aaaaaaaaobsqoqegphdipcwrmt4ji6r4ukjirxvzlc7dzvto66beijmo4exa"


  }
  metadata = {
    ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
    user_data           = base64encode(file("./modules/compute/scripts/bootstrap_compute.sh"))
    tenancy_id = var.tenancy_ocid
    grabdish_application_password = var.grabdish_application_password
    grabdish_database_password = var.grabdish_database_password
    app_public_repo = var.app_public_repo
    iaas_public_repo = var.iaas_public_repo
    dbaas_FQDN =  var.dbaas_FQDN
    target_compartment_id =var.target_compartment_id
    vcn_id = var.vcn_id
    subnet_id = var.subnet_id
    image_os = var.image_os
    image_os_version = var.image_os_version
    instance_shape = var.instance_shape
  }
}



