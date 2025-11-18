#!/bin/bash
# Creates secrets for account and customer microservices in the obaas-dev namespace
#
# Adjust the namespace and secret values as needed

kubectl -n obaas-dev create secret generic account-db-secrets \
  --from-literal=db.name=helmtest \
  --from-literal=db.username=account \
  --from-literal=db.password=Welcome-12345 \
  --from-literal=db.service=helmtest_tp \
  --from-literal=db.lb_username=admin \
  --from-literal=db.lb_password=Welcome-12345
kubectl -n obaas-dev create secret generic customer-db-secrets \
  --from-literal=db.name=helmtest \
  --from-literal=db.username=customer \
  --from-literal=db.password=Welcome-12345 \
  --from-literal=db.service=helmtest_tp \
  --from-literal=db.lb_username=admin \
  --from-literal=db.lb_password=Welcome-12345
