Skip to content
Search or jump to…
Pull requests
Issues
Marketplace
Explore
 
@praveennhiremath 
oracle
/
microservices-datadriven
Public
8
18
14
Code
Issues
103
Pull requests
Discussions
Actions
Projects
1
Wiki
Security
Insights
Settings
microservices-datadriven/grabdish/utils/non-java-builds.sh
@paulparkinson
paulparkinson update versions of a jdk, helidon, and oracle jdbc, and add inventory…
…
Latest commit c2a8892 4 days ago
 History
 4 contributors
@RichardExley@paulparkinson@renagranat@matayal
Executable File  50 lines (40 sloc)  1.72 KB
   
#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

BUILDS="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se order-mongodb-kafka inventory-postgres-kafka inventory-springboot inventory-micronaut inventory-quarkus"
# we provision a repos for db-log-exporter but it's in nested observability/db-log-exporter dir so not reusing BUILDS list to build (see DB_LOG_EXPORTER_BUILD below)
REPOS="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se order-mongodb-kafka inventory-postgres-kafka inventory-springboot inventory-micronaut inventory-micronaut-native-image inventory-quarkus db-log-exporter"

# Provision Repos
while ! state_done NON_JAVA_REPOS; do
  for b in $REPOS; do
    oci artifacts container repository create --compartment-id "$(state_get COMPARTMENT_OCID)" --display-name "$(state_get RUN_NAME)/$b" --is-public true
  done
  state_set_done NON_JAVA_REPOS
done


# Wait for docker login
while ! state_done DOCKER_REGISTRY; do
  echo "Waiting for Docker Registry"
  sleep 5
done


# Wait for java builds
while ! state_done JAVA_BUILDS; do
  echo "Waiting for Java Builds"
  sleep 10
done


# Build  the images
while ! state_done NON_JAVA_BUILDS; do
  for b in $BUILDS; do
    cd $GRABDISH_HOME/$b
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log &
  done
  wait
  state_set_done NON_JAVA_BUILDS
done

# Build the db-log-exporter image
while ! state_done DB_LOG_EXPORTER_BUILD; do
  cd $GRABDISH_HOME/observability/db-log-exporter
  time ./build.sh &>> $GRABDISH_LOG/build-db-log-exporter.log &
  state_set_done DB_LOG_EXPORTER_BUILD
done
© 2021 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
Loading complete