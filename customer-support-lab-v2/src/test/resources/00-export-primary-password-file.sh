#!/usr/bin/env bash
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/.

# True Cache authenticates to the primary with the primary database password
# file. The Compose topology shares this file through a named volume instead of
# copying it to the host filesystem.
set -euo pipefail

install -m 0444 \
  /opt/oracle/product/26ai/dbhomeFree/dbs/orapwFREE \
  /var/tmp/orapwFREE
