#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo Ensure MSDATAWORKSHOP_OCIR_AUTHKEY argument is in quotes.
echo Usage example 1: ./dockerLogin.sh foo@bar.com "8nO[BKNU5iwasdf2xeefU;yl"
echo Usage example 2: ./dockerLogin.sh oracleidentitycloudservice/foo@bar.com "8nO[BKNU5iwasdf2xeefU;yl"

export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

if [[ $1 == "" ]]
then
  echo MSDATAWORKSHOP_OCIR_USER not provided
  echo Required arguments are MSDATAWORKSHOP_OCIR_USER and MSDATAWORKSHOP_OCIR_AUTHKEY.
  echo Usage example : ./dockerLogin.sh foo@bar.com "8nO[BKNU5iwasdf2xeefU;yl"
  exit
fi

if [[ $2 == "" ]]
then
  echo MSDATAWORKSHOP_OCIR_AUTHKEY not provided
  echo Required arguments are MSDATAWORKSHOP_OCIR_USER and MSDATAWORKSHOP_OCIR_AUTHKEY.
  echo Usage example : ./dockerLogin.sh foo@bar.com "8nO[BKNU5iwasdf2xeefU;yl"
  exit
fi

export MSDATAWORKSHOP_OCIR_USER=$1
echo $MSDATAWORKSHOP_OCIR_USER | tr -d '"' > $WORKINGDIR/msdataworkshopociruser.txt
echo MSDATAWORKSHOP_OCIR_USER... $MSDATAWORKSHOP_OCIR_USER

export MSDATAWORKSHOP_OCIR_AUTHKEY=$2
echo $MSDATAWORKSHOP_OCIR_AUTHKEY | tr -d '"' > $WORKINGDIR/msdataworkshopocirauthkey.txt
echo MSDATAWORKSHOP_OCIR_AUTHKEY... $MSDATAWORKSHOP_OCIR_AUTHKEY

export MSDATAWORKSHOP_REGION=$(cat $WORKINGDIR/msdataworkshopregion.txt)
echo MSDATAWORKSHOP_REGION... $MSDATAWORKSHOP_REGION

export MSDATAWORKSHOP_OCIR_NAMESPACE=$(cat $WORKINGDIR/msdataworkshopocirnamespace.txt)
echo MSDATAWORKSHOP_OCIR_NAMESPACE... $MSDATAWORKSHOP_OCIR_NAMESPACE

export MSDATAWORKSHOP_REPOS_NAME=$(cat $WORKINGDIR/msdataworkshopreposname.txt)
echo MSDATAWORKSHOP_REPOS_NAME... $MSDATAWORKSHOP_REPOS_NAME


#export DOCKER_REGISTRY="<region-key>.ocir.io/<object-storage-namespace>/<firstname.lastname>/<repo-name>"
# example... export DOCKER_REGISTRY=us-ashburn-1.ocir.io/aqsghou34ag/paul.parkinson/myreponame
export DOCKER_REGISTRY=$MSDATAWORKSHOP_REGION.ocir.io/$MSDATAWORKSHOP_OCIR_NAMESPACE/$MSDATAWORKSHOP_REPOS_NAME
echo $DOCKER_REGISTRY | tr -d '"' > $WORKINGDIR/msdataworkshopdockerregistry.txt
echo DOCKER_REGISTRY... $DOCKER_REGISTRY

# example... docker login REGION-ID.ocir.io -u <tenant name>/<username>
# example... docker login REGION-ID.ocir.io -u OBJECT-STORAGE-NAMESPACE/USERNAME
echo docker login $MSDATAWORKSHOP_REGION.ocir.io -u $MSDATAWORKSHOP_OCIR_NAMESPACE/$MSDATAWORKSHOP_OCIR_USER -p $MSDATAWORKSHOP_OCIR_AUTHKEY
docker login $MSDATAWORKSHOP_REGION.ocir.io -u $MSDATAWORKSHOP_OCIR_NAMESPACE/$MSDATAWORKSHOP_OCIR_USER -p $MSDATAWORKSHOP_OCIR_AUTHKEY

