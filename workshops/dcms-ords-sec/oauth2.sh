#!/usr/bin/env bash
curl -k -0 -i -H"Authorization: Bearer $1" https://${LB}/ords/ordstest/examples/employees/
