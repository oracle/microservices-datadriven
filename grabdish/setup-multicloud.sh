#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The following setup and install of Verrazzano is taken directly from https://verrazzano.io/docs/setup/quickstart/

echo Setting up Verrazzano...
echo Deploying the Verrazzano platform operator...
kubectl apply -f https://github.com/verrazzano/verrazzano/releases/latest/download/operator.yaml
echo Waiting for the deployment to complete...
kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
echo Confirming that the operator pod is correctly defined and running...
kubectl -n verrazzano-install get pods

echo Installing Verrazzano with its dev profile... this will take approximately 20 minutes...
kubectl apply -f - <<EOF
apiVersion: install.verrazzano.io/v1alpha1
kind: Verrazzano
metadata:
  name: example-verrazzano
spec:
  profile: dev
  components:
    dns:
      wildcard:
        domain: nip.io
EOF

echo Waiting for the installation to complete...
kubectl wait \
    --timeout=20m \
    --for=condition=InstallComplete \
    verrazzano/example-verrazzano

#(Optional) View the installation logs...
#kubectl logs -f \
#    $( \
#      kubectl get pod  \
#          -l job-name=verrazzano-install-example-verrazzano \
#          -o jsonpath="{.items[0].metadata.name}" \
#    )

echo Adding labels identifying the msdataworkshop namespace as managed by Verrazzano and enabled for Istio...
kubectl label namespace msdataworkshop verrazzano-managed=true istio-injection=enabled

echo Adding VerrazzanoProject
#export CLUSTERS_NAME="$(state_get OCI_REGION)"
export CLUSTERS_NAME="$(state_get CLUSTER_NAME)" # eg cluster-cyxypetwerq, also notice the plural/CLUSTERS_NAME and singular/CLUSTER_NAME
export CURRENTTIME=$( date '+%F_%H:%M:%S' )
echo CURRENTTIME is $CURRENTTIME  ...this will be appended to generated verrazzano-project yaml for CLUSTERS_NAME ${CLUSTERS_NAME}
cp verrazzano-project.yaml verrazzano-project-$CURRENTTIME.yaml
sed -i "s|%CLUSTERS_NAME%|${CLUSTERS_NAME}|g" verrazzano-project-$CURRENTTIME.yaml
kubectl apply -f verrazzano-project-$CURRENTTIME.yaml

# without the above it is necessary to
#kubectl edit authorizationpolicy supplier-helidon-se-appconf -n msdataworkshop
#and
#kubectl edit authorizationpolicy order-helidon-appconf -n msdataworkshop
#adding the following under rules: from: source: principals:
#- cluster.local/ns/msdataworkshop/sa/frontend-helidon-appconf

#echo undeploy any previously deployed microservices... this is not needed unless another workshop using graddish/msdataworkshop was previously deployed
#./undeploy.sh

echo deploy microservices using Verrazzano Open Application Model...
./deploy-multicloud.sh

echo Wait for the application to be ready... # msdataworkshop-frontend-helidon-appconf-gw and msdataworkshop-order-helidon-appconf-gw
kubectl wait --for=condition=Ready pods --all -n msdataworkshop --timeout=300s

echo Display istio resources in msdataworkshop...
getistio

echo Saving the host name of the load balancer exposing the Frontend service endpoints...
HOST=$(kubectl get gateway msdataworkshop-frontend-helidon-appconf-gw -n msdataworkshop -o jsonpath='{.spec.servers[0].hosts[0]}') # convention is namespace + appconf name + gw
echo HOST is ${HOST}

ingresses
