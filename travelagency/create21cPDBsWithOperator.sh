#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml

kubectl apply -f https://raw.githubusercontent.com/oracle/oracle-database-operator/main/oracle-database-operator.yaml

kubectl create secret generic admin-password --from-literal=admin-password='Welcome12345'

kubectl apply -f config/samples/adb/autonomousdatabase_create.yaml


ERROR	controllers.database.AutonomousDatabase	Fail to get OCI provider	{"Namespaced/Name": "default/autonomousdatabase-sample", "error": "ConfigMap \"oci-cred\" not found"}
