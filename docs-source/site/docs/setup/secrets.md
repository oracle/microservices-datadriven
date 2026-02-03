---
title: Secrets
sidebar_position: 4
---

## Overview

You must create a few secrets before starting the installation of Helm charts. These secrets contain authentication information that will be needed by the Helm charts.

### Database Credentials Secret

Create a secret to provide OBaaS with the credentials for your database. This example assumes your database is called **demo1**:

```bash
kubectl create secret generic admin-user-authn \
  --from-literal=username=ADMIN \
  --from-literal=password="SuperSecretPassword" \
  --from-literal=service="demo1_tp" \
  --from-literal=dbname="demo1"
```  

Be careful to get the correct database name and service name, since these will be injected into applications that you deploy using the client side helm chart.

Verify your secret looks like this:

```bash
kubectl get secret admin-user-authn -o yaml
```

```yaml
apiVersion: v1
data:
  dbname: ZGV\...
  password: V2V\...
  service: ZGV\...
  username: QUR\...
kind: Secret
metadata:
  creationTimestamp: "2025-08-17T16:26:20Z"
  name: admin-user-authn
  namespace: default
  resourceVersion: "14755"
  uid: b71f045d-c2dc-4b25-ba6a-ab277ec2d00e
  type: Opaque
```

:::note
If you are planning to install multiple OBaaS instances, AND you want to use different databases, you need to create one of these secrets for EACH instance, and they must have different names.
:::

:::note
If you want to use an existing Oracle Database in your applications which is not deployed as an Oracle Autonomous Database in OCI or you do not want Oracle Database Operator to create/sync the **tns** secret containing the connection information for the database, provide the **dbhost** and **dbport** for the database instance while creating the secret as follows:
:::

```bash
kubectl create secret generic admin-user-authn \
  --from-literal=username=ADMIN \
  --from-literal=password="SuperSecretPassword" \
  --from-literal=service="demo1_tp" \
  --from-literal=dbname="demo1" \
  --from-literal=dbhost="demodb.demohost" \
  --from-literal=dbport="1522"
```

### OCI Credentials Secret

Run the provided script to generate the appropriate command for you from your OCI configuration. Note: You must have a working OCI CLI configured with access to your tenancy and the region where you want to install, on the machine where you run this command. The python script generated a command that you need to execute. to create the key.

```bash
python3 ./obaas-db/scripts/oci_config.py
```

```text
echo 'apiVersion: v1
kind: Secret
metadata:
  name: oci-config-file
  namespace: default
  type: Opaque
data:
  config: W0R\...
  oci_api_key.pem: LS0\...
' \| kubectl apply -f -
```

:::important

- The Python script reads the OCI config file and looks for the `DEFAULT` entry to determine the private key file.
- The OCI config file can not have more than one profile and needs to be named `DEFAULT`.
- This script requires your key file to be named **oci_api_key.pem** - if your key file has a different name, this script will produce an incorrect secret. In that case you would need to edit the name of the second key to make it **oci_api_key.pem** and update the value of the first key (config) to include that name. To update that value, you need to base64 decode it, update the plaintext, then base64 encode that.

:::

Once you have the correct command, run that command to create the secret. Then check your secret looks correct using this command:

```bash
kubectl get secret oci-config-file -o yaml
```

```yaml
apiVersion: v1
data:
  config: W0R\...
  oci_api_key.pem: LS0\...
kind: Secret
...
```

You should also base64 decode the values to check that they are correct. For example:

```bash
echo -n "W0R\... " \| base64 -d
```

```log
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaaxyzxyzxyz
fingerprint=d0:b5:60:bd:27:2b:...
tenancy=ocid1.tenancy.oc1..aaaaaaaaxyzxyzxyz
region=us-phoenix-1
key_file=/app/runtime/.oci/oci_api_key.pem
```

**Important note**: We recommend taking extra care to ensure these are all correct before moving on to the next step. If there are any errors here, the injection of the Database configuration will fail.

**Note**:  If you are planning to install multiple OBaaS instances, AND you want to use different OCI credentials, you need to create one of these secrets for EACH instance, and they must have different names.
