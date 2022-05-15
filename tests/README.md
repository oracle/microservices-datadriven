Tests can be run with either `./test.sh` or `./testIncludingPolyglot.sh`
The only assumption is that the core microservices have been deployed (eg by running grabdish/deploy.sh)

Does not require any environment variables or state_get, etc. type scripts 
and is secure as I use java k8s client from within the tests to get the frontend ingress/LB and password.  

Therefore, it can be run as-is in any environment against any k8s cluster 
simply by running microservices-datadriven/tests/test.sh or testIncludingPolyglot.sh. 

The only assumption being that the core microservices (frontend, order, inventory, and supplier) are deployed (eg by running grabdish/deploy.sh as usual).

 