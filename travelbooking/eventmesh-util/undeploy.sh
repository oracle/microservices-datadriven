#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo delete atpaqadmin deployment and service...

kubectl delete deployment atpaqadmin -n msdataworkshop

kubectl delete service atpaqadmin -n msdataworkshop

