#!/usr/bin/env bash
curl -k -0 --user $CLIENT_ID:$CLIENT_SECRET --data "grant_type=authorization_code&code=$1" https://${api_gw_base_url}/ords/ordstest/oauth/token
