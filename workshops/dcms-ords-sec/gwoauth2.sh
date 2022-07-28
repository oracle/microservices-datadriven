#!/usr/bin/env bash
# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

curl -k -0 -i -H"Authorization: Bearer $1" https://${api_gw_base_url}/ords/ordstest/examples/employees/
