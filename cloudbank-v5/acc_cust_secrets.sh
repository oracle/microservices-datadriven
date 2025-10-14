#!/bin/bash
# Creates secrets for account and customer microservices in the obaas-dev namespace
#
# Adjust the namespace and secret values as needed

kubectl -n obaas-dev create secret generic account-db-secrets \
  --from-literal=db.name=helmdb \
  --from-literal=db.username=account \
  --from-literal=db.password=YOUR_PASSWORD \
  --from-literal=db.service=helmdb_tp \
  --from-literal=db.lb_username=admin \
  --from-literal=db.lb_password=YOUR_PASSWORD
kubectl -n obaas-dev create secret generic customer-db-secrets \
  --from-literal=db.name=helmdb \
  --from-literal=db.username=customer \
  --from-literal=db.password=YOUR_PASSWORD \
  --from-literal=db.service=helmdb_tp \
  --from-literal=db.lb_username=admin \
  --from-literal=db.lb_password=YOUR_PASSWORD
