#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Source the state functions
source utils/state_functions.sh


# Get DB Connection Wallet


# Save Walley to Object STore
WALLET_OBJECT_DONE

# Create Authenticated Link to Wallet
WALLET_AUTH_DONE

# DB Setup DOne
state_set_done "DB_SETUP_DONE"