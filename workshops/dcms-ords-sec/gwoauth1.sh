#!/usr/bin/env bash
# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

curl -k -0 --user $CLIENT_ID:$CLIENT_SECRET --data "grant_type=authorization_code&code=$1" https://${api_gw_base_url}/ords/ordstest/oauth/token
