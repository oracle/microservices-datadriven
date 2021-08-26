#/bin/bash


# Fail on error
set -e


# Create SSL Certs
while ! state_done SSL; do
  mkdir -p $GRABDISH_HOME/tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $GRABDISH_HOME/tls/tls.key -out $GRABDISH_HOME/tls/tls.crt -subj "/CN=grabdish/O=grabdish"
  state_set_done SSL
done



# Create SSL Secret
while ! state_done SSL_SECRET; do
  if kubectl create secret tls ssl-certificate-secret --key $GRABDISH_HOME/tls/tls.key --cert $GRABDISH_HOME/tls/tls.crt -n msdataworkshop; then
    state_set_done SSL_SECRET
  else
    echo "SSL Secret creation failed.  Retrying..."
    sleep 10
  fi
done
