#!/bin/bash
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

./build.sh
./testHelidonAndTransactional.sh
./testPolyglot.sh
REQ_UTILS="touch rm mkdir"
REQ_INPUT_PARAMS=""
REQ_OUTPUT_PARAMS="LB_ADDRESS ORDS_ADDRESS TNS_ADMIN"
