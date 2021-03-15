#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo download and extract GraalVM...
curl -sLO https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz
gunzip graalvm-ce-java11-linux-amd64-20.1.0.tar.gz
tar xvf graalvm-ce-java11-linux-amd64-20.1.0.tar
rm graalvm-ce-java11-linux-amd64-20.1.0.tar
mv graalvm-ce-java11-20.1.0 ~/

echo ~/graalvm-ce-java11-20.1.0 > $WORKINGDIR/msdataworkshopgraalvmhome.txt

echo install GraalVM native-image...
~/graalvm-ce-java11-20.1.0/bin/gu install native-image

umask 077

if [ ! -d tls ]; then
  umask 077
  echo "Creating ssl certificate secret"
  mkdir tls
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls/tls.key -out tls/tls.crt -subj "/CN=convergeddb/O=convergeddb"
  kubectl create secret tls ssl-certificate-secret --key tls/tls.key --cert tls/tls.crt -n msdataworkshop
fi

echo install jaeger...
kubectl create -f https://tinyurl.com/yc52x6q5 -n msdataworkshop

echo creating frontend loadbalancer service...
kubectl create -f frontend-helidon/frontend-service.yaml -n msdataworkshop
