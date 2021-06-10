_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Automated Workshop Testing

Here is how to run an automated test in your free tier tenancy or with a Live Labs reserved tenancy.

1. (Free Tier Only) Clean up your existing tenancy so thet you have disk space and the docker cache is empty:
```
docker image prune -a -f
csreset -a
```

2. (Free Tier Only) From the OCI Console, make space for a new auth token.  The limit is 2.

3. (Free Tier Only) Create a directory to run the test:
```
export TEST_DIRECTORY=gd`awk 'BEGIN { srand(); print int(1 + rand() * 1000000)}'`
echo "Test directory $TEST_DIRECTORY"
mkdir $TEST_DIRECTORY
cd $TEST_DIRECTORY
```

4. (Free Tier Only) Register your user OCID:
```
export TEST_USER_OCID='ocid1.user.oc1..xxxxx'
```

5. Register which branch you wish to test and the passwords to be used:
```
export GITHUB_BRANCH='1.4'
export GITHUB_USER='oracle'
export TEST_DB_PASSWORD='Welcome12345;#!:'
export TEST_UI_PASSWORD='Welcome1;#!"'
```

6. Clone the code
```
git clone -b "$BRANCH" --single-branch "https://github.com/${GITHUB_USER}/microservices-datadriven.git"
```

7. Execute the setup.  Note in the Live Labs case, the setup will prompt for the compartment OCID and an auth token.
```
sed -i.bak '/grabdish/d' ~/.bashrc
echo "source $PWD/microservices-datadriven/grabdish/env.sh" >>~/.bashrc
source microservices-datadriven/grabdish/env.sh
source setup.sh
```

8. Execute the test
```
source test.sh
```

9. Clean up
```
source destroy.sh
```
