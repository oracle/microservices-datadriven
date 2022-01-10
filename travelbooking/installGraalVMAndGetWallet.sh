#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz | tar xz
mv graalvm-ce-java11-20.1.0 ~/

#mkdir wallet
#cd wallet
#oci db autonomous-database generate-wallet --autonomous-database-id "$1" --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
#unzip wallet.zip
#cd ../
