#!/usr/bin/env bash
curl -k -0 -i -H"Authorization: Bearer $1" https://${api_gw_base_url}/ords/ordstest/examples/employees/
