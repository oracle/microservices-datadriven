#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


export ENQUEUE_OR_DEQUEUE=$1
export NUMBER_TO_ENQUEUE_OR_DEQUEUE=$2
if [[ $ENQUEUE_OR_DEQUEUE == "enqueue" ]]
then
    echo "enqueueing" $NUMBER_TO_ENQUEUE_OR_DEQUEUE
    a=0
    while [ $a -lt $NUMBER_TO_ENQUEUE_OR_DEQUEUE ]
    do
       echo $a
       a=`expr $a + 1`
    sleep 1
    curl http://localhost:8080/enqueue
    done
else
    echo "dequeueing" $NUMBER_TO_ENQUEUE_OR_DEQUEUE
    a=0
    while [ $a -lt $NUMBER_TO_ENQUEUE_OR_DEQUEUE ]
    do
       echo $a
       a=`expr $a + 1`
    sleep 1
    curl http://localhost:8080/dequeue
    done
fi
