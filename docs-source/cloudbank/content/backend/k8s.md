+++
archetype = "page"
title = "Explore Kubernetes"
weight = 2
+++


Oracle Backend for Spring Boot and Microservices includes a number of platform services which are deployed into the Oracle Container Engine for Kubernetes cluster.  You configured **kubectl** to access your cluster in an earlier module.  In this task, you will explore the services deployed in the Kubernetes cluster.  A detailed explanation of Kubernetes concepts is beyond the scope of this course.

1. Explore namespaces

   Kubernetes resources are grouped into namespaces.  To see a list of the namespaces in your cluster, use this command, your output will be slightly different:

    ```shell
    $ kubectl get ns
      NAME                              STATUS   AGE
      admin-server                      Active   4h56m
      apisix                            Active   4h56m
      application                       Active   4h57m
      azn-server                        Active   4h56m
      cert-manager                      Active   4h59m
      coherence                         Active   4h56m
      conductor-server                  Active   4h56m
      config-server                     Active   4h55m
      default                           Active   5h8m
      eureka                            Active   4h57m
      grafana                           Active   4h55m
      ingress-nginx                     Active   4h57m
      kafka                             Active   4h56m
      kaniko                            Active   5h1m
      kube-node-lease                   Active   5h8m
      kube-public                       Active   5h8m
      kube-state-metrics                Active   4h57m
      kube-system                       Active   5h8m
      metrics-server                    Active   4h57m
      obaas-admin                       Active   4h55m
      observability                     Active   4h55m
      open-telemetry                    Active   4h55m
      oracle-database-exporter          Active   4h55m
      oracle-database-operator-system   Active   4h59m
      otmm                              Active   4h55m
      prometheus                        Active   4h57m
      vault                             Active   4h54m
    ```

   Here is a summary of what is in each of these namespaces:

      * `admin-server` contains Spring Admin which can be used to monitor and manage your services
      * `apisix` contains the APISIX API Gateway and Dashboard which can be used to expose services outside the cluster
      * `application` is a pre-created namespace with the Oracle Database wallet and secrets pre-configured to allow services deployed there to access the Oracle Autonomous Database instance
      * `cert-manager` contains Cert Manager which is used to manage X.509 certificates for services
      * `cloudbank` is the namespace where you deployed the CloudBank sample application
      * `conductor-server` contains Netflix Conductor OSS which can be used to manage workflows
      * `config-server` contains the Spring CLoud Config Server
      * `eureka` contains the Spring Eureka Service Registry which is used for service discovery
      * `grafana` contains Grafana which can be used to monitor and manage your environment
      * `ingress-nginx` contains the NGINX ingress controller which is used to manage external access to the cluster
      * `kafka` contains a three-node Kafka cluster that can be used by your application
      * `obaas-admin` contains the Oracle Backend for Spring Boot and Microservices administration server that manages deployment of your services
      * `observability` contains Jaeger tracing which is used for viewing distributed traces
      * `open-telemetry` contains the Open Telemetry Collector which is used to collect distributed tracing information for your services
      * `oracle-database-operator-system` contains the Oracle Database Operator for Kubernetes which can be used to manage Oracle Databases in Kubernetes environments
      * `otmm` contains Oracle Transaction Manager for Microservices which is used to manage transactions across services
      * `prometheus` contains Prometheus which collects metrics about your services and makes the available to Grafana for alerting and dashboards
      * `vault` contains HashiCorp Vault which can be used to store secret or sensitive information for services, like credentials for example

   Kubernetes namespaces contain other resources like pods, services, secrets and config maps.  You will explore some of these now.

2. Explore pods

   Kubernetes runs workloads in "pods."  Each pod can container one or more containers.  There are different kinds of groupings of pods that handle scaling in different ways.  Use this command to review the pods in the `apisix` namespace:

    ```shell
    $ kubectl -n apisix get pods
      NAME                                READY   STATUS    RESTARTS        AGE
      apisix-558f6f64c6-ff6xf             1/1     Running   0               4h57m
      apisix-dashboard-6f865fcb7b-n76c7   1/1     Running   4 (4h56m ago)   4h57m
      apisix-etcd-0                       1/1     Running   0               4h57m
      apisix-etcd-1                       1/1     Running   0               4h57m
      apisix-etcd-2                       1/1     Running   0               4h57m
    ```

   The first pod listed is the APISIX API Gateway itself.  It is part of a Kubernetes "deployment".  The next pod is running the APISIX Dashboard user interface - there is only one instance of that pod running.  And the last three pods are running the etcd cluster that APISIX is using to store its state.  These three pods are part of a "stateful set".

   To see details of the deployments and stateful set in this namespace use this command:

    ```shell
    $ kubectl -n apisix get deploy,statefulset
    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/apisix             3/3     3            3           6d18h
    deployment.apps/apisix-dashboard   1/1     1            1           6d18h
    
    NAME                           READY   AGE
    statefulset.apps/apisix-etcd   3/3     6d18h
    ```

   If you want to view extended information about any object you can specify its name and the output format, as in this example:

    ```shell
    $ kubectl -n apisix get pod apisix-etcd-0 -o yaml
    ```

3. Explore services

   Kubernetes services are essentially small load balancers that sit in front of groups of pods and provide a stable network address as well as load balancing.  To see the services in the `apisix` namespace use this command:

    ```shell
    $ kubectl -n apisix get svc
      NAME                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
      apisix-admin                ClusterIP   10.96.26.213   <none>        9180/TCP            4h59m
      apisix-dashboard            ClusterIP   10.96.123.62   <none>        80/TCP              4h59m
      apisix-etcd                 ClusterIP   10.96.54.248   <none>        2379/TCP,2380/TCP   4h59m
      apisix-etcd-headless        ClusterIP   None           <none>        2379/TCP,2380/TCP   4h59m
      apisix-gateway              NodePort    10.96.134.86   <none>        80:32130/TCP        4h59m
      apisix-prometheus-metrics   ClusterIP   10.96.31.169   <none>        9091/TCP            4h59m
    ```

   Notice that the services give information about the ports.  You can get detailed information about a service by specifying its name and output format as you did earlier for a pod.

4. Explore secrets

   Sensitive information in Kubernetes is often kept in secrets that are mounted into the pods at runtime.  This means that the container images do not need to have the sensitive information stored in them.  It also helps with deploying to different environments where sensitive information like URLs and credentials for databases changes based on the environment.

   Oracle Backend for Spring Boot and Microservices creates a number of secrets for you so that your applications can securely access the Oracle Autonomous Database instance.  Review the secrets in the pre-created `application` namespace using this command. **Note**, the name of the secrets will be different in your environment depending on the application name you gave when deploying the application.

    ```shell
    $ kubectl -n application get secret
      NAME                        TYPE                             DATA   AGE
      account-db-secrets          Opaque                           4      57m
      admin-liquibasedb-secrets   Opaque                           5      56m
      checks-db-secrets           Opaque                           4      57m
      customer-db-secrets         Opaque                           4      56m
      encryption-secret-key       Opaque                           1      5h1m
      public-key                  Opaque                           1      5h1m
      registry-auth               kubernetes.io/dockerconfigjson   1      5h
      registry-login              Opaque                           5      5h
      registry-pull-auth          kubernetes.io/dockerconfigjson   1      5h
      registry-push-auth          kubernetes.io/dockerconfigjson   1      5h
      testrunner-db-secrets       Opaque                           4      56m
      tls-certificate             kubernetes.io/tls                5      5h
      zimbadb-db-secrets          Opaque                           5      5h
      zimbadb-tns-admin           Opaque                           9      5h
    ```

   Whenever you create a new application namespace with the CLI and bind it to the database, these secrets will be automatically created for you in that namespace.  There will two secrets created for the database, one contains the credentials to access the Oracle Autonomous Database.  The other one contains the database client configuration files (`tnsadmin.ora`, `sqlnet.ora`, the keystores, and so on). The name of the secret depends on the application name you gave (or got autogenerated) during install, in the example above the application name is `zimba`.

   You can view detailed information about a secret with a command like this, you will need to provide the name of your secret which will be based on the name you chose during installation (your output will be different). Note that the values are uuencoded in this output:

    ```shell
    $ kubectl -n application get secret zimbadb-db-secrets -o yaml
      apiVersion: v1
      data:
      db.name: xxxxxxxxxx
      db.password: xxxxxxxxxx
      db.service: xxxxxxxxxx
      db.username: xxxxxxxxxx
      secret: xxxxxxxxxx
      kind: Secret
      metadata:
      creationTimestamp: "2024-05-08T16:38:06Z"
      moduleels:
         app.kubernetes.io/version: 1.2.0
      name: zimbadb-db-secrets
      namespace: application
      resourceVersion: "3486"
      uid: 66855e8d-22a5-4e24-b3df-379dd033ed1f
      type: Opaque
    ```

   When you deploy a Spring Boot microservice application into Oracle Backend for Spring Boot and Microservices, the pods that are created will have the values from this secret injected as environment variables that are referenced from the `application.yaml` to connect to the database.  The `xxxxxx-tns-admin` secret will be mounted in the pod to provide access to the configuration and keystores to allow your application to authenticate to the database.

