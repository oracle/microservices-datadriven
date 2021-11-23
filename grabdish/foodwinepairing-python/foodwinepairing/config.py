
##
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
from os import environ as env

# Gunicorn Configuration
bind = ":" + env.get("PORT", "8080")
workers = int(env.get("WORKERS", 1))
threads = int(env.get("HTTP_THREADS", 1))

