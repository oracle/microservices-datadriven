+++
archetype = "page"
title = "Deploy the optional chatbot"
weight = 7
+++

In this section, you will learn how to deploy the `optional` chatbot application. **NOTE:** this requires that you have provisioned an Oracle Backend for Microservices and AI with a GPU cluster and are running Ollama in that cluster. The lab `CloudBank AI Assistant` outlines the steps.

> Note if you already have a running session with `oractl` you can skip step 1-3.

1. Start the tunnel

    ```shell
    kubectl port-forward -n obaas-admin svc/obaas-admin 8080
    ```

1. Get the password for the `obaas-admin` user

    ```shell
    kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

1. Start `oractl` from the `cloudbank-v4` directory and login as the `obaas-admin` user.

1. Run the following command in `oractl`:

    ```shell
    deploy --service-name chatbot --artifact-path chatbot/target/chatbot-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --java-version ghcr.io/oracle/graalvm-native-image-obaas:21
    ```

1. Start a tunnel to the `chatbot` application

    ```shell
    kubectl -n application port-forward svc/chatbot 7575:8080
   ```

1. Test the `chatbot` application.

    ```shell
    curl -X POST -d 'what is spring boot?'  http://localhost:7575/chat
    ```
   The command should return something similar to this:

    ```text
    A popular question!

    Spring Boot is an open-source Java-based framework that provides a simple and efficient wait to build web applications, RESTful APIs, and microservices. It's built on top of the Spring  Framework, but with a more streamlined and opinionated approach.
    ```
   