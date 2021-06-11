_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Local Development

This document explains how to setup your development machine to perform development where the microservices can be built and then deployed onto OKE for testing.

These tests have been tested on MacOS

## Prerequisites

1. Install OCI CLI

  https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

2. Install kubectl

  https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/

3. Install GraalVM
```
cd ~
curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-darwin-amd64-20.1.0.tar.gz | tar -xz
```

4. Install Maven

  https://maven.apache.org/install.html
```
cd ~
curl -sL https://downloads.apache.org/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz | tar xz
export PATH=~/apache-maven-3.8.1/bin:$PATH
```

  Also, add ~/apache-maven-3.8.1/bin to your /etc/paths

5. Install Docker

  https://docs.docker.com/get-docker/

6. Clone your github development branch to your machine and make a note of the location, for example _/Users/freddy/Documents/GitHub/microservices-datadriven_.

## Setup Steps
These steps are required every time you perform a new grabdish workshop setup.

1. Configure the OCI CLI to connect to your TENANCY_OCID
```
oci setup config
```

2. Create a folder to hold the grabdish workshop state
```
mkdir ~/grabdish_state
cd ~/grabdish_state
```

2. Using the download feature of cloud shell (hamburger menu about cloud shell window), download the ~/grabdish_state.tgz file to your machine.  This file is generated when the workshop setup completes.  

3. Copy the _grabdish_state.tgz_ file to the _~/grabdish_state_ folder.

4. Unpack the _grabdish_state.tgz_ file
```
cd ~/grabdish-state
rm -rf state
tar -xzf grabdish-state.tgz
```

5. Set the shell environment using the env.sh script located in the cloned code
```
source /Users/rexley/Documents/GitHub/microservices-datadriven/grabdish/env.sh
```
This step will need to be repeated whenever you start a new shell.

6. Configure kubectl
```
oci ce cluster create-kubeconfig --cluster-id "$(state_get OKE_OCID)" --file $HOME/.kube/config --region "$(state_get REGION)" --token-version 2.0.0
```

7. Generate an auth token through the OCI Console.  Copy the token.

8. Login to Docker using the OCI Registry
```
docker login -u "$(state_get NAMESPACE)/$(state_get USER_NAME)" "$(state_get REGION).ocir.io"
```
You will be prompted for a password.  Paste the auth token generated in the previous step.
