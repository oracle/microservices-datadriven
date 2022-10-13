# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

k6 run -e MY_HOSTNAME=${api_gw_base_url}/ords/ordstest/examples/employees/ -e TOKEN=$1 ./apigw-stress-script.js --insecure-skip-tls-verify
