#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

$GRABDISH_HOME/order-helidon/deploy.sh
$GRABDISH_HOME/inventory-helidon/deploy.sh
$GRABDISH_HOME/supplier-helidon-se/deploy.sh
echo TESTING inventory-helidon
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-helidon/undeploy.sh

$GRABDISH_HOME/inventory-dotnet/deploy.sh
echo TESTING inventory-dotnet
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-dotnet/undeploy.sh

$GRABDISH_HOME/inventory-go/deploy.sh
echo TESTING inventory-go
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-go/undeploy.sh

$GRABDISH_HOME/inventory-helidon-se/deploy.sh
echo TESTING inventory-helidon-se
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-helidon-se/undeploy.sh

$GRABDISH_HOME/inventory-micronaut/deploy.sh
echo TESTING inventory-micronaut
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-micronaut/undeploy.sh

$GRABDISH_HOME/inventory-nodejs/deploy.sh
echo TESTING inventory-nodejs
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-nodejs/undeploy.sh

$GRABDISH_HOME/inventory-python/deploy.sh
echo TESTING inventory-python
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-python/undeploy.sh

$GRABDISH_HOME/inventory-quarkus/deploy.sh
echo TESTING inventory-quarkus
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-quarkus/undeploy.sh

$GRABDISH_HOME/inventory-springboot/deploy.sh
echo TESTING inventory-springboot
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-springboot/undeploy.sh

$GRABDISH_HOME/inventory-plsql/deploy.sh
echo TESTING inventory-plsql
mvn surefire:test -Dtest=oracle.modernappdev.WalkThroughTest
$GRABDISH_HOME/inventory-plsql/undeploy.sh

echo TESTING complete, redeploying inventory-helidon
$GRABDISH_HOME/inventory-helidon/deploy.sh