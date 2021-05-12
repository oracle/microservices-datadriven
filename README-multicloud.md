# Mutli-cloud, Verrazzano version of workshop 
#Simplify microservices architecture with Oracle Converged Database

0. Starting from http://bit.ly/simplifymicroservices

1. Do `Lab 1: Setup` (takes ~20 to 25 minutes)
    - This will clone the workshop src from https://github.com/oracle/microservices-datadriven,  
      provision and configure the following, and build and push the workshop microservice docker images
        - OKE cluster
        - 2 ATP databases (with secrets, AQ propagation, etc.)
        - OCIR
        - Object Storage 
        - Jaeger 
        
2. Run `./setup-multicloud.sh` (takes ~20 minutes)
    - Step 1 will have put you in the appropriate `.../microservices-datadriven/grabdish` dir.
    - This will install verrazzano, deploy workshop microservices, and provide URLs for 
        - Grafana
        - Prometheus
        - Kibana
        - Elasticsearch
        - Rancher
        - KeyCloak
    - Example output...
    
    `    NAMESPACE         NAME                       CLASS    HOSTS                                                    ADDRESS          PORTS     AGE`

        cattle-system       rancher                    <none>   rancher.default.158.101.26.111.nip.io                    158.101.26.111   80, 443   37h
        keycloak            keycloak                   <none>   keycloak.default.158.101.26.111.nip.io                   158.101.26.111   80, 443   37h
        verrazzano-system   verrazzano-ingress         <none>   verrazzano.default.158.101.26.111.nip.io                 158.101.26.111   80, 443   37h
        verrazzano-system   vmi-system-es-ingest       <none>   elasticsearch.vmi.system.default.158.101.26.111.nip.io   158.101.26.111   80, 443   37h
        verrazzano-system   vmi-system-grafana         <none>   grafana.vmi.system.default.158.101.26.111.nip.io         158.101.26.111   80, 443   37h
        verrazzano-system   vmi-system-kibana          <none>   kibana.vmi.system.default.158.101.26.111.nip.io          158.101.26.111   80, 443   37h
        verrazzano-system   vmi-system-prometheus      <none>   prometheus.vmi.system.default.158.101.26.111.nip.io      158.101.26.111   80, 443   37h
        verrazzano-system   vmi-system-prometheus-gw   <none>   prometheus-gw.vmi.system.default.158.101.26.111.nip.io   158.101.26.111   80, 443   37h
        
3. Do `Lab 2: Data-centric microservices walkthrough with Helidon MP` to test the app, etc.
    - REPLACE STEP 1 INSTRUCTION IN LAB
        - Instead of running `cd $GRABDISH_HOME;./deploy.sh` run `cd $GRABDISH_HOME;./deploy-multicloud.sh`
    - Proceed with all other steps. Step 1 is the only difference.
    
4. Optionally, do labs 3, 4, and 5
    - Optionally do `Lab 3: Polyglot Microservices` to test with other languages such as Python, JS, .NET, and Go
        - Again, instead of running `cd $GRABDISH_HOME;./deploy.sh` run `cd $GRABDISH_HOME;./deploy-multicloud.sh`
    - Optionally do `Lab 4: Scaling` to show how the application can be scaled at the application and database tiers to maintain optimal performance.
        - Can be run without modification
    - Optionally do `Lab 5: Tracing Using Jaeger` to show microservice activity using OpenTracing and Jaeger.
        - Can be run without modification
    
4. Use https URLs and login from output in step 2 to view various dashboards deployed by Verrazzano and Jaeger.

TODOs
 - one open issue to configure RBAC source access (currently this done by changing the authorizationpolicy after the fact) 
 - ./setup-multicloud.sh should take a password to override those auto-generated and password(s) should not be displayed
 - add walkthrough of consoles...
 - possibly add Kiali

Future: Running on other clouds starting with Azure (using interconnect, etc.)...
