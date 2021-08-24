#/bin/bash


# Fail on error
set -e

# Install Jaeger
#while ! state_done JAEGER; do
  if kubectl apply -f https://tinyurl.com/yc52x6q5 -n msdataworkshop 2>$GRABDISH_LOG/jaeger_err; then
    state_set_done JAEGER
  else
    echo "Jaeger installation failed.  Retrying..."
    cat "$GRABDISH_LOG"/jaeger_err
    sleep 10
  fi
#done
