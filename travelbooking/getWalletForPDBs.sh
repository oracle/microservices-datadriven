#!/bin/bash
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


if [ -z "$1" ]; then
    echo "Error: ocid of either osagadb1 or osagadb2 21c database must be provided as argument."
    echo "For example: ./getWalletForPDBs.sh ocid1.autonomousdatabase.oc1.phx.anyxxxxxxxxxxxx"
    exit 1
fi

cd ~/microservices-datadriven/travelbooking
mkdir wallet
cd wallet
oci db autonomous-database generate-wallet --autonomous-database-id "$1" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
unzip wallet.zip
cd ../
