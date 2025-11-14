---
title: Create Required Secrets
sidebar_position: 5
---
## Create Required Secrets

You must create a few secrets before starting the installation of Helm charts. These secrets contain authentication information that will be needed by the Helm charts. If you're planning to use the External Secrets Operator it must be deployed and configured as part of the pre-requisites for installation.

### Image Pull Secrets

Create an image pull secret to allow pull access to your container repository. This is the repository where application images will be stored. If you are using the recommended OKE, this should be an OCI-R repository in the same compartment and region. This example assumes your tenancy is called **tenancy**, the region **phx.ocir.io** and that your tenancy uses IDCS authentication. Adjust the command to match your tenancy:

```bash
kubectl create secret generic ocir \
  --from-literal=host=phx.ocir.io/tenancy \
  --from-literal=username=tenancy/oracleidentitycloudservice/bob.smith@oracle.com \
  --from-literal=password="SuperSecretPassword" \
  --from-literal=email=bob.smith@oracle.com
```

:::important
Your OCI-R password must be an Authentication Token, not the password you use to log into the OCI web console.
:::

You can validate the token by performing a docker login using this command (with your own username and token):

```bash
docker login phx.ocir.io 
  -u tenancy/oracleidentitycloudservice/bob.smith@company.com 
  -p 'SuperSecretPassword'
```

You can verify your secret using this command:

```bash
kubectl get secret ocir -o yaml
```

```yaml
apiVersion: v1
data:
  email: bWF...
  host: cGh...
  password: KE4...
  username: bWF...
kind: Secret
metadata:
  creationTimestamp: "2025-08-17T16:06:14Z"
  name: ocir
  namespace: default
  resourceVersion: "9295"
  uid: d5fe5b24-fcf1-42d2-a615-28d299acd645
  type: Opaque
```

Note that the values are base64 encoded.

Create two additional secrets as shown below:

```bash
kubectl create secret generic obaas-registry-login \
  --from-literal=registry.username="tenancy/oracleidentitycloudservice/mark.x.nelson@oracle.com" \
  --from-literal=registry.password="SuperSecretPassword" \
  --from-literal=registry.push_url="phx.ocir.io/tenancy/obaas-dev"
```

```bash
kubectl create secret docker-registry obaas-registry-pull-auth \
  --docker-server="phx.ocir.io/tenancy" \
  --docker-username="tenancy/oracleidentitycloudservice/mark.x.nelson@oracle.com" \
  --docker-password="SuperSecretPassword" \
  --docker-email="mark.x.nelson@oracle.com"
```

Note that the first secret contains the registry prefix for images that would be created by OBaaS Admin.

Confirm you have the following secrets before moving on:

```bash
kubectl get secrets
```

```log
NAME                      TYPE                            DATA  AGE
obaas-registry-login      Opaque                          3     29s
obaas-registry-pull-auth  kubernetes.io/dockerconfigjson  1      8s
ocir                      Opaque                          4     13m
```

:::note
If you are planning to install multiple OBaaS instances, AND you want to use different private repositories, you need to create a set of these secrets for EACH instance, and they must have different names.
:::

### OBaaS Password Secrets

These secrets are used to set the passwords for various OBaaS components. Note that these are not optional in M3. In the final 2.0.0 release, these will be optional, and if you omit them, each component will have a different random password set for it. If you want to use random passwords, see below.

Create the secrets using these commands:

```bash
kubectl create secret generic signoz \
  --from-literal=email="admin@nodomain.com" \
  --from-literal=password=SuperSecretPassword
```

```bash
kubectl create secret generic clickhouse \
  --from-literal=username="clickhouse_operator" \
  --from-literal=password=SuperSecretPassword
```

```bash
kubectl create secret generic alertmanager \
  --from-literal=username="admin" \
  --from-literal=password="SuperSecretPassword"
```

To use random passwords, instead of specifying a password as shown above, use this form of the command instead:

```bash
kubectl create secret generic signoz \
  --from-literal=email="admin@nodomain.com" \
  --from-literal=password=\$(openssl rand -base64 16)
```

:::note
If you are planning to install multiple OBaaS instances, AND you want to use different passwords, you need to create a set of these secrets for EACH instance, and they must have different names.
:::

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
