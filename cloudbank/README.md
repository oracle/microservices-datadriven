# Application: Cloudbank


This is a work in progress.

### Steps for basic bank transfer application

This app uses a single database with two users (bankauser and bankbuser) and two queues (bankaqueue and bankbqueue)
There is one bank-springboot microservices that is reused for both banka and bankb deployments (just uses different env values accordingly)

1. create DB with kubernetes secrets as done in normal setup for simplify microservices workshop (ie run lab 1)
2. run `microservices-datadriven/cloudbank/sql/AdminCreateUsers.sql` as admin
3. run `microservices-datadriven/cloudbank/sql/AQUserCreateQueues.sql` as aquser
4. run `microservices-datadriven/cloudbank/sql/BankAUser.sql` as bankauser
5. run `microservices-datadriven/cloudbank/sql/BankBUser.sql` as bankbuser
7. run `./build.sh` to build and push the bank-springboot image (note that this will also attempt to create public OCIR repos)
8. run `./deploy.sh` to create banka and bankb deployments and services
9. run `curlpod bank` shortcut command and issue curl such as...
10. curl -X POST -H "Content-type: application/json" -d  "{\"frombank\" : \"banka\" , \"fromaccount\" : \"100\", \"tobank\" : \"bankb\", \"toaccount\" : \"200\",  \"amount\" : \"1\"}"  "http://banka.msdataworkshop:8080/transferfunds"





### Steps for setting up AQ/TEQ prometheus metrics, Grafana dashboard, and deq/enq alert(s)

1. create DB with kubernetes secrets as done in normal setup for simplify microservices workshop (ie run lab 1)
2. `cd microservices-datadriven/oracle-db-appdev-monitoring/`
3. run `./install_observability_stack.sh`
4. run `microservices-datadriven/cloudbank/sql/AdminCreateUsers.sql` as admin
5. run `microservices-datadriven/cloudbank/sql/AQUserCreateQueues.sql` as aquser
6. `cd microservices-datadriven/cloudbank/observability`
7. run `./createMonitorsAndExporters.sh`
8. open Grafana as usual (ie find Grafana service created by install_observability_stack.sh and login as admin/prom-operator)
9. import the microservices-datadriven/cloudbank/observability/dashboard/cloudbankdashboard.json dashboard and notice metrics
10. create an alert panel and/or alert channel in Grafana as shown in the observability workshop/lab
11. create an alert for deq/enq rate falling as in the image alertrule_deqenqrate.png (todo add src here)
12. `cd microservices-datadriven/cloudbank/cloudbank-backend`
13. export `bankauser, bankapw, and bankaurl` 
    1. eg `export localbankqueueschema=aquser ; export localbankqueuename=BANKAQUEUE ; export banksubscribername=bankb_service ; export bankdbuser=bankauser ; export bankdbpw=Welcome12345 ; export bankdburl="jdbc:oracle:thin:@gd49301311_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_gd49301311"
14. run `mvn package`
15. run `java -jar target/springboot-0.0.1-SNAPSHOT.jar`
16. run `./loadTest.sh dequeue 1000`
17. run `./loadTest.sh enqueue 1000`
18. notice Grafana console and enq/rate above .5
19. kill dequeue load test
20. notice Grafana console and enq/rate drop below .5 and alert notification in console and/or channel as configured in step 10

<p><img src="alertrule_deqenqrate.png" ></p>

## License



Copyright (c) 2022 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at <https://oss.oracle.com/licenses/upl>.

