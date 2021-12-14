#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#MS="frontend-helidon travelagency-helidon supplier-helidon-se participant-helidon participant-springboot"
MS="frontend-helidon travelagency-helidon supplier-helidon-se participant-helidon"
for s in $MS; do 
    echo ________________________________________
    echo "Deploying $s..."
    echo ________________________________________
    cd $TRAVELBOOKING_HOME/$s
    ./deploy.sh
    cd $TRAVELBOOKING_HOME
done

echo ________________________________________
echo ...finished
echo ________________________________________
