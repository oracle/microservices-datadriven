#!/bin/bash

echo ''
echo 'Oracle Backend for Spring Boot and Microservices'
echo '------------------------------------------------'
echo ''
echo 'This script will collect information that could help Oracle'
echo 'diagnose and fix issues with your environment.  You should'
echo 'generally only run this script if you have been asked to'
echo 'by Oracle.'
echo ''
echo 'WARNING'
echo ''
echo 'This script generates two files named `all-resources.yaml`'
echo 'and `cluster-info-dump`.  It is possible, and likely, that'
echo 'these files may contain private or sensitive information.'
echo 'You MUST review the contents of the generated files BEFORE'
echo 'providing those files to Oracle or anyone else.'
echo ''

read -p "Do you want to continue? (y/n) " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 
fi

echo ''
echo 'Collecting data, this may take a few minutes...'

kubectl get all -o custom-columns="KIND:.kind,NAME:.metadata.name" --no-headers=true > all-resources.yaml
kubectl get crd -o custom-columns="KIND:.kind,NAME:.metadata.name" --no-headers=true | while read kind name; do
  kubectl get crd "$name" -o yaml >> all-resources.yaml
done

kubectl cluster-info dump > cluster-info-dump

echo ''
echo 'Data collection complete.  Please review the output before sharing'
