All tests can be run using ./testAll.sh which in turn calls the following...

./build.sh
./undeployAll.sh
./deployCoreServices.sh
./testHelidonAndTransactional.sh
./testPolyglot.sh

The only preq is the completion of setup (ie lab 1).

Test setup does not require any environment variables or state_get, etc. type scripts (*todo: aside from perhaps PL/SQL polyglot test which requires sqlplus etc.)
and is secure as the java k8s client is used from within the tests to get the frontend ingress/LB and password.  

Therefore, it can be run as-is in any environment against any k8s cluster that was used for setup (OKE other otherwise/vendor)
simply by running microservices-datadriven/tests/test.sh or testIncludingPolyglot.sh. 
