#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo TESTING inventory-helidon
mvn clean test
$GRABDISH_HOME/inventory-helidon/undeploy.sh

$GRABDISH_HOME/inventory-dotnet/deploy.sh
inventory-dotnet
echo TESTING inventory-dotnet
mvn clean test
$GRABDISH_HOME/inventory-dotnet/undeploy.sh

$GRABDISH_HOME/inventory-go/deploy.sh
inventory-go
echo TESTING inventory-go
mvn clean test
$GRABDISH_HOME/inventory-go/undeploy.sh

$GRABDISH_HOME/inventory-helidon-se/deploy.sh
inventory-helidon-se
echo TESTING inventory-helidon-se
mvn clean test
$GRABDISH_HOME/inventory-helidon-se/undeploy.sh

$GRABDISH_HOME/inventory-micronaut/deploy.sh
inventory-micronaut
echo TESTING inventory-micronaut
mvn clean test
$GRABDISH_HOME/inventory-micronaut/undeploy.sh

$GRABDISH_HOME/inventory-nodejs/deploy.sh
inventory-nodejs
echo TESTING inventory-nodejs
mvn clean test
$GRABDISH_HOME/inventory-nodejs/undeploy.sh

$GRABDISH_HOME/inventory-plsql/deploy.sh
inventory-plsql
echo TESTING inventory-plsql
mvn clean test
$GRABDISH_HOME/inventory-plsql/undeploy.sh

$GRABDISH_HOME/inventory-python/deploy.sh
inventory-python
echo TESTING inventory-python
mvn clean test
$GRABDISH_HOME/inventory-python/undeploy.sh

$GRABDISH_HOME/inventory-quarkus/deploy.sh
inventory-quarkus
echo TESTING inventory-quarkus
mvn clean test
$GRABDISH_HOME/inventory-quarkus/undeploy.sh

$GRABDISH_HOME/inventory-springboot/deploy.sh
inventory-springboot
echo TESTING inventory-springboot
mvn clean test
$GRABDISH_HOME/inventory-springboot/undeploy.sh

echo TESTING complete, redeploying inventory-helidon
$GRABDISH_HOME/inventory-helidon/deploy.sh