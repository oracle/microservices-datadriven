#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo undeploying frontend-helidon...
echo ________________________________________
cd frontend-helidon
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying atpaqadmin...
echo ________________________________________
cd atpaqadmin
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying order-helidon...
echo ________________________________________
cd order-helidon
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying supplier-helidon-se...
echo ________________________________________
cd supplier-helidon-se
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying inventory-helidon...
echo ________________________________________
cd inventory-helidon
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying inventory-python...
echo ________________________________________
cd inventory-python
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying inventory-nodejs...
echo ________________________________________
cd inventory-nodejs
./undeploy.sh
cd ../

echo ________________________________________
echo undeploying inventory-helidon-se...
echo ________________________________________
cd inventory-helidon-se
./undeploy.sh
cd ../


echo ________________________________________
echo ...finished
echo ________________________________________
