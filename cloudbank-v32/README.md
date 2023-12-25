# CloudBank Version 3.2

Version 3.2 of CloudBank is under development. This document is also WIP.

## Build CloudBank

`mvn clean package`

```text
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for cloudbank 0.0.1-SNAPSHOT:
[INFO] 
[INFO] cloudbank .......................................... SUCCESS [  0.734 s]
[INFO] account ............................................ SUCCESS [  2.511 s]
[INFO] customer ........................................... SUCCESS [  1.046 s]
[INFO] creditscore ........................................ SUCCESS [  0.815 s]
[INFO] transfer ........................................... SUCCESS [  0.427 s]
[INFO] testrunner ......................................... SUCCESS [  0.884 s]
[INFO] checks ............................................. SUCCESS [  0.912 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  7.586 s
[INFO] Finished at: 2023-12-25T17:50:52-06:00
[INFO] ------------------------------------------------------------------------
```

## Deploying Cloudbank

1. Start the tunnel

```shell
kubectl port-forward -n obaas-admin svc/obaas-admin 8080
```

1. Get the password for the `obaas-admin` user

```shell
kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
```

1. Start `oractl` and login.

```text
  _   _           __    _    ___
 / \ |_)  _.  _. (_    /  |   |
 \_/ |_) (_| (_| __)   \_ |_ _|_
 ========================================================================================
  Application Name: Oracle Backend Platform :: Command Line Interface
  Application Version: (1.1.0)
  :: Spring Boot (v3.2.0) :: 
  
  Ask for help:
   - Slack: https://oracledevs.slack.com/archives/C03ALDSV272 
   - email: obaas_ww@oracle.com

oractl:>connect
username: obaas-admin
password: **************
obaas-cli: Successful connected.
oractl:>
```
