k6 run -e MY_HOSTNAME=${api_gw_base_url}/ords/ordstest/examples/employees/ -e TOKEN=$1 ./apigw-stress-script.js --insecure-skip-tls-verify
