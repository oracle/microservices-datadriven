#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo building all images and deleting all pods to refresh...

echo building all images...
./build.sh

echo deleting all podss...
./deleteAllPods.sh

