_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Automated Workshop Testing

Here is how to run an automated test in your free tier tenancy or with a Live Labs reserved tenancy.

1. (Free Tier Only) Clean up your existing tenancy so that you have disk space and the docker cache is empty:
```
docker image prune -a -f
csreset -a <<< 'y'
```

2. (Free Tier Only) From the OCI Console, make space for a new auth token.  The limit is 2.

3. (Free Tier Only) Create a directory to run the test and name your compartment:
```
export TEST_DIRECTORY=gd`awk 'BEGIN { srand(); print int(1 + rand() * 1000000)}'`
echo "Test directory $TEST_DIRECTORY"
mkdir $TEST_DIRECTORY
cd $TEST_DIRECTORY
export TEST_COMPARTMENT="$TEST_DIRECTORY"
export TEST_PARENT_COMPARTMENT_OCID='$OCI_TENANCY'
```

4. (Free Tier Only) Register your user OCID:
```
export TEST_USER_OCID='ocid1.user.oc1..xxxxx'
```

5. Export the fork/GITHUB_USER (and branch/GITHUB_BRANCH if necessary) you wish to test and the passwords to be used:
```
export GITHUB_BRANCH='main'
export GITHUB_USER='myghuser'
export TEST_DB_PASSWORD='Welcome12345;#!:'
export TEST_UI_PASSWORD='Welcome1;#!:"'
```

6. Clone the code
```
git clone -b "$GITHUB_BRANCH" --single-branch "https://github.com/${GITHUB_USER}/microservices-datadriven.git"
```

7. Execute the setup.  Note in the Live Labs case, the setup will prompt for the compartment OCID and an auth token.
```
source microservices-datadriven/workshops/dcms-oci/source.env
time setup
```

8. Execute the test
```
source test.sh

```

9. Clean up
```
time teardown

```
