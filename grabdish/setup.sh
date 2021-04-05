# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
function source_check()
{
    if [[ ${FUNCNAME[-1]} != "source" ]]
    then
        printf "Failure.  Usage: source %s\n" "$0"
        exit 1
    fi
}
source_check

# Set GRABDISH_HOME
export GRABDISH_HOME=`dirname "$(readlink -f "$0")"`
echo "GRABDISH_HOME: $GRABDISH_HOME"

$GRABDISH_HOME/utils/main-setup.sh