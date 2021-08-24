#/bin/bash


# Fail on error
set -e

CERTS_DIR=$INFRA_HOME/oci-iaas/grabdish-adapter/infrastructure/

# Create SSL Certs
while ! state_done DOCKER_REG_CERTS; do
  mkdir -p $CERTS_DIR/certs
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERTS_DIR/certs/domain.key -out $CERTS_DIR/certs/domain.crt -subj "/CN=grabdish/O=grabdish"
  state_set_done DOCKER_REG_CERTS
done

docker_reg_command="docker run -d \
  --restart=always \
  --name registry \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 443:443 \
  registry:2"

# Create DOCKER_REGISTRY
while ! state_done DOCKER_REGISTRY_IN; do
  if $($docker_reg_command)
  state_set_done DOCKER_REGISTRY_IN
  else
    echo "Docker Registry Creation Failed.  Retrying..."
    sleep 10
  fi
done
