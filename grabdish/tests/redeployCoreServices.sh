#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

$GRABDISH_HOME/frontend-helidon/undeploy.sh
$GRABDISH_HOME/order-helidon/undeploy.sh
$GRABDISH_HOME/inventory-helidon/undeploy.sh
$GRABDISH_HOME/supplier-helidon-se/undeploy.sh

$GRABDISH_HOME/frontend-helidon/deploy.sh
$GRABDISH_HOME/order-helidon/deploy.sh
$GRABDISH_HOME/inventory-helidon/deploy.sh
$GRABDISH_HOME/supplier-helidon-se/deploy.sh