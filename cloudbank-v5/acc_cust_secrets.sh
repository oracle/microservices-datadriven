#!/bin/bash
# Creates secrets for account and customer microservices in the obaas-dev namespace
#
# Adjust the namespace and secret values as needed

kubectl -n obaas-dev create secret generic account-db-secrets \ 
    --from-literal=db.name=<database_name> \
    --from-literal=db.username=account \
    --from-literal=db.password=<your_password_from_sqljob.yaml> \
    --from-literal=db.service=<database_service> \
    --from-literal=db.lb_username=admin \
    --from-literal=db.lb_password=<admin_password>
kubectl -n obaas-dev create secret generic customer-db-secrets \ 
    --from-literal=db.name=<database_name> \ 
    --from-literal=db.username=customer \ 
    --from-literal=db.password=<your_password_froms_qljob.yaml> \ 
    --from-literal=db.service=<database_service> \ 
    --from-literal=db.lb_username=admin \ 
    --from-literal=db.lb_password=<admin_password>