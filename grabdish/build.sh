#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo building and pushing frontend-helidon...
echo ________________________________________
cd frontend-helidon
./build.sh
cd ../

echo maven install soda jar...
cd lib
mvn install:install-file -Dfile=orajsoda-1.1.0.jar -DgroupId=com.oracle \
    -DartifactId=orajsoda -Dversion=1.1.0 -Dpackaging=jar
cd ../

echo ________________________________________
echo building and pushing admin-helidon...
echo ________________________________________
cd admin-helidon
./build.sh
cd ../

echo ________________________________________
echo building and pushing order-helidon...
echo ________________________________________
cd order-helidon
./build.sh
cd ../

echo ________________________________________
echo building and pushing supplier-helidon-se...
echo ________________________________________
cd supplier-helidon-se
./build.sh
cd ../

echo ________________________________________
echo building and pushing inventory-helidon...
echo ________________________________________
cd inventory-helidon
./build.sh
cd ../

echo ________________________________________
echo building and pushing inventory-python...
echo ________________________________________
cd inventory-python
./build.sh
cd ../

echo ________________________________________
echo building and pushing inventory-nodejs...
echo ________________________________________
cd inventory-nodejs
./build.sh
cd ../

echo ________________________________________
echo building and pushing inventory-helidon-se...
echo ________________________________________
cd inventory-helidon-se
./build.sh
cd ../

echo ________________________________________
echo ...finished
echo ________________________________________
