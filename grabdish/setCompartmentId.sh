#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [[ $1 == "" ]]
then
  echo Required argument MSDATAWORKSHOP_COMPARTMENT_ID not provided. The compartmentid can be copied from the OCI Console.
  echo Usage example : ./setCompartmentId.sh ocid1.compartment.oc1..aaaaaaaaxbvaatfz6dyfqbxhmasxfyui4rjek5dnzgcbivfwvsho77myfnqq us-ashburn-1
  exit
fi

if [[ $2 == "" ]]
then
  echo Required argument $MSDATAWORKSHOP_REGION not provided. The region id can be copied from the OCI Console.
  echo Usage example : ./setCompartmentId.sh ocid1.compartment.oc1..aaaaaaaaxbvaatfz6dyfqbxhmasxfyui4rjek5dnzgcbivfwvsho77myfnqq us-ashburn-1
  exit
fi

echo ________________________________________
echo setting compartmentid and region ...
echo ________________________________________

export WORKINGDIR=workingdir
echo creating working directory $WORKINGDIR to store values...
mkdir $WORKINGDIR

export MSDATAWORKSHOP_REGION=$2
echo $MSDATAWORKSHOP_REGION | tr -d '"' > $WORKINGDIR/msdataworkshopregion.txt
echo MSDATAWORKSHOP_REGION... $MSDATAWORKSHOP_REGION

export MSDATAWORKSHOP_COMPARTMENT_ID=$1
echo $MSDATAWORKSHOP_COMPARTMENT_ID | tr -d '"' > $WORKINGDIR/msdataworkshopcompartmentid.txt
echo MSDATAWORKSHOP_COMPARTMENT_ID... $MSDATAWORKSHOP_COMPARTMENT_ID
