#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

MS="order-helidon supplier-helidon-se inventory-helidon"
for s in $MS; do
    echo ________________________________________
    echo "Deploying $s..."
    echo ________________________________________
    cd $GRABDISH_HOME/$s
    ./deploy.sh
    cd $GRABDISH_HOME
done

echo ________________________________________
echo "Deploying frontend-helidon with NodePort instead of Ingress..."
echo ________________________________________
cd $GRABDISH_HOME/frontend-helidon
./deploy-noLB.sh
cd $GRABDISH_HOME

echo ________________________________________
echo ...finished
echo ________________________________________
