#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [[ $1 == "" ]]
then
  echo MSDATAWORKSHOP_OCIR_NAMESPACE not provided
  echo Required arguments are MSDATAWORKSHOP_OCIR_NAMESPACE and MSDATAWORKSHOP_REPOS_NAME.
  echo Usage example : ./addOCIRInfo.sh axkcsk2aiatb msdataworkshop.user1/msdataworkshop
  exit
fi

if [[ $2 == "" ]]
then
  echo MSDATAWORKSHOP_REPOS_NAME not provided
  echo Required arguments are MSDATAWORKSHOP_OCIR_NAMESPACE and MSDATAWORKSHOP_REPOS_NAME.
  echo Usage example : ./addOCIRInfo.sh axkcsk2aiatb msdataworkshop.user1/msdataworkshop
  exit
fi

export WORKINGDIR=workingdir
echo WORKINGDIR = $WORKINGDIR

export MSDATAWORKSHOP_OCIR_NAMESPACE=$1
echo $MSDATAWORKSHOP_OCIR_NAMESPACE | tr -d '"' > $WORKINGDIR/msdataworkshopocirnamespace.txt
echo MSDATAWORKSHOP_OCIR_NAMESPACE... $MSDATAWORKSHOP_OCIR_NAMESPACE

export MSDATAWORKSHOP_REPOS_NAME=$2
echo $MSDATAWORKSHOP_REPOS_NAME | tr -d '"' > $WORKINGDIR/msdataworkshopreposname.txt
echo MSDATAWORKSHOP_REPOS_NAME... $MSDATAWORKSHOP_REPOS_NAME