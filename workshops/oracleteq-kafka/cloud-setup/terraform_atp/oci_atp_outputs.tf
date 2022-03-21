// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

//========= Outputs ===========================
output "ns_objectstorage_namespace" {
    value =  [ data.oci_objectstorage_namespace.lab8022_objstore_namespace.namespace ]
}

output "autonomous_database_admin_password" {
    value =  [ "Welcome12345" ]
}