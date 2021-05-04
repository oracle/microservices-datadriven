#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo ________________________________________
echo deleting pod frontend-helidon...
echo ________________________________________
deletepod frontend

echo ________________________________________
echo deleting pod order-helidon...
echo ________________________________________
deletepod order

echo ________________________________________
echo deleting pod supplier-helidon-se...
echo ________________________________________
deletepod supplier

echo ________________________________________
echo deleting pod inventory-helidon...
echo ________________________________________
deletepod inventory-helidon

echo ________________________________________
echo deleting pod inventory-python...
echo ________________________________________
deletepod inventory-python

echo ________________________________________
echo deleting pod inventory-nodejs...
echo ________________________________________
deletepod inventory-nodejs

echo ________________________________________
echo deleting pod inventory-helidon-se...
echo ________________________________________
deletepod inventory-helidon-se


echo ________________________________________
echo ...finished
echo ________________________________________
