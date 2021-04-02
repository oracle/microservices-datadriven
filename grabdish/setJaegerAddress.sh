#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#It should not be necessary to run this file unless it took an extended period of time for the jaeger query service's loadbalancer to be provisisioned.

export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

echo setting jaeger address...
kubectl get services jaeger-query -n msdataworkshop --output jsonpath='{.status.loadBalancer.ingress[0].ip}' > $WORKINGDIR/msdataworkshopjaegeraddress.txt

export MSDATAWORKSHOP_JAEGER_IP=$(cat $WORKINGDIR/msdataworkshopjaegeraddress.txt)
echo MSDATAWORKSHOP_JAEGER_IP... $MSDATAWORKSHOP_JAEGER_IP

if [[ $MSDATAWORKSHOP_JAEGER_IP == "" ]]
then
  echo "MSDATAWORKSHOP_JAEGER_IP does not exist. Loadbalancer provisioning may still be pending. Try running ./setJaegerAddress.sh again or check the OCI console for progress."
fi
#443
export JAEGER_QUERY_ADDRESS=https://$MSDATAWORKSHOP_JAEGER_IP
echo JAEGER_QUERY_ADDRESS = $JAEGER_QUERY_ADDRESS
echo $JAEGER_QUERY_ADDRESS > $WORKINGDIR/msdataworkshopjaegeraddress.txt
echo Creating configmap with JAEGER_QUERY_ADDRESS for use by FrontEnd service
kubectl create -n msdataworkshop -f - <<!
{
   "apiVersion": "v1",
   "kind": "ConfigMap",
   "metadata": {
      "name": "jaegerqueryaddress"
   },
   "data": {
      "address": "${JAEGER_QUERY_ADDRESS}"
   }
}
!
