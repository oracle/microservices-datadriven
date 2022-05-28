## Running tests

All tests can be run using ./testAll.sh which in turn calls the following...

./build.sh
./undeployAll.sh
./redeployCoreServices.sh
./testHelidonAndTransactional.sh
./testPolyglot.sh

The only preq is the completion of setup (ie lab 1). Ie it will use $KUBECONFIG and default is ~/.kube/config

Test setup does not require any environment variables or state_get, etc. type scripts (see *TODO)
and is secure as the java k8s client is used from within the tests to get the frontend ingress/LB and password.  

Therefore, it can be run as-is in any environment against any k8s cluster that was used for setup (OKE other otherwise/vendor)
simply by running microservices-datadriven/tests/test.sh or testIncludingPolyglot.sh. 

## View test results

You can see a quick summary of the test results by running the following... 

cat  target/surefire-reports/*.txt

cat  target/surefire-reports/polyglot/inventory-*/*.txt




## TODO...

The surefire reports get overridden for WalkThroughTest as it's reused by 

PL/SQL polyglot without using sqlplus binary

Currently no foodwinepairing tests nor foodwinepairing deploy/undeploy

Currently no scaling/load tests see testScaling.sh

Currently no observability tests 
- probably only test metrics/logs/tracing, and alerts, etc. not dashboard (needs to be manual as selenium is not feasible)

