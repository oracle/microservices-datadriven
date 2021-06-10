#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

echo install kafka...
./install-kafka.sh

echo install mongodb...
./install-mongodb.sh

echo install postgres
./install-postgres.sh