#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo deleting ATP PDBs...
echo ________________________________________


echo delete cluster and vcn... to delete the compartment use the console...
export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

export MSDATAWORKSHOP_CLUSTER_ID=$(cat $WORKINGDIR/msdataworkshopclusterid.txt)
echo MSDATAWORKSHOP_CLUSTER_ID... $MSDATAWORKSHOP_CLUSTER_ID
oci ce cluster delete --cluster-id $MSDATAWORKSHOP_CLUSTER_ID
