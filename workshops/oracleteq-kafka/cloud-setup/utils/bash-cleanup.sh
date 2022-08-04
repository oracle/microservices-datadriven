#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

sed '/LiveLab Setup -- BEGIN/,/LiveLab Setup -- END/d'  "${HOME}"/.bashrc > "${HOME}"/.bashrc.tmp
mv "${HOME}"/.bashrc.tmp "${HOME}"/.bashrc
