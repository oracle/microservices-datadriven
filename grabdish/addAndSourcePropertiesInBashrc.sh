#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# we put a placeholder msdataworkshopjaegeraddress.txt as we wont have the Jaeger LB address until later/setJaegerAddress.sh step
touch workingdir/msdataworkshopjaegeraddress.txt
echo "export MSDATAWORKSHOP_LOCATION=~/datadriven-master/grabdish/" >> ~/.bashrc
echo "source ~/msdataworkshop-master/msdataworkshop.properties" >> ~/.bashrc
source ~/.bashrc

