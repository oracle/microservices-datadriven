#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

cd ~/microservices-datadriven/travelbooking
mkdir wallet
cd wallet
oci db autonomous-database generate-wallet --autonomous-database-id "$1" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
unzip wallet.zip
cd ../
