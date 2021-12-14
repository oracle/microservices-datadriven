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
resource "oci_artifacts_container_repository" "travelagency-helidon_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/travelagency-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "supplier-helidon-se_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/supplier-helidon-se"
  is_public = true
}
resource "oci_artifacts_container_repository" "participant-helidon_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/participant-helidon"
  is_public = true
}
resource "oci_artifacts_container_repository" "participant-python_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/participant-python"
  is_public = true
}
resource "oci_artifacts_container_repository" "nodejs_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/participant-nodejs"
  is_public = true
}
resource "oci_artifacts_container_repository" "participant-helidon-se_container_repository" {
  #Required
  compartment_id = "${var.ociCompartmentOcid}"
  display_name = "${var.runName}/participant-helidon-se"
  is_public = true
}
*/