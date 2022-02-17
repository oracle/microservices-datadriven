 #!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# set classpath for mkstore - align this to your local SQLcl installation
SQLCL=/opt/oracle/sqlcl/lib
CLASSPATH=${SQLCL}/oraclepki.jar:${SQLCL}/osdt_core.jar:${SQLCL}/osdt_cert.jar


# simulate mkstore command
# Debug  -Doracle.pki.debug=true
$JAVA_HOME/bin/java -Doracle.pki.debug=true -classpath "${CLASSPATH}" oracle.security.pki.OracleSecretStoreTextUI  "$@"
