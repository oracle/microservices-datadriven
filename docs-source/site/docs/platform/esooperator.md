---
title: External Secrets Operator
sidebar_position: 7
---
## External Secrets Operator

:::important
The External Secrets Operator is an optional prerequisite for Oracle Backend for Microservices and AI
:::

External Secrets Operator is a Kubernetes operator that integrates external secret management systems like OCI Vault, AWS Secrets Manager,
HashiCorp Vault, Google Secrets Manager, Azure Key Vault and many more. The operator reads information from external APIs and automatically injects the values into a Kubernetes Secret.

Full [documentation](https://external-secrets.io/latest/)

![External Secrets Operator](images/diagrams-high-level-simple.png)

---

## Table of Contents

- [Prerequisites and Assumptions](#prerequisites-and-assumptions)
- [Installing External Secrets Operator](#installing-external-secrets-operator)
- [Testing the External Secrets Operator](#testing-the-external-secrets-operator)
  - [Apply the config](#apply-the-config)
  - [Check the ExternalSecret status](#check-the-externalsecret-status)
  - [Verify the secret was created](#verify-the-secret-was-created)
  - [Cleanup](#cleanup)
- [Using with Production Secret Stores](#using-with-production-secret-stores)
  - [OCI Vault Configuration](#oci-vault-configuration)
  - [HashiCorp Vault Configuration](#hashicorp-vault-configuration)
- [Monitoring External Secrets](#monitoring-external-secrets)
  - [Check ExternalSecret Status](#check-externalsecret-status)
  - [View Detailed Status](#view-detailed-status)
  - [Monitor External Secrets Operator Logs](#monitor-external-secrets-operator-logs)
  - [Check Secret Sync Events](#check-secret-sync-events)

---

### Prerequisites and Assumptions

This guide makes the following assumptions:

- **Kubectl Access**: You have kubectl configured and authenticated to your Kubernetes cluster with appropriate permissions to:
  - Create and manage SecretStores and ExternalSecrets
  - View secrets in your namespace
  - View logs from the external-secrets namespace
- **Command-line Tools**: The following tools are installed and available:
  - `kubectl` - Kubernetes command-line tool
  - `jq` - JSON processor (used for secret verification examples)
- **File References**: Examples reference `eso-test.yaml` and `eso-cleanup.yaml` files. You'll need to create these files with the YAML content provided in the examples.

:::note Namespace Configuration
This guide uses two types of namespaces:
- **Operator namespace** (`-n external-secrets`): Where the External Secrets Operator is installed. Used when viewing operator logs or troubleshooting the operator itself.
- **Application namespace** (`-n obaas-dev` in examples): Where your SecretStores, ExternalSecrets, and application secrets are created. Replace `obaas-dev` with your actual application namespace.

To find the operator namespace, run:
```bash
kubectl get pods -A | grep external-secrets
```
:::

### Installing External Secrets Operator

External Secrets Operator will be installed if the `external-secrets.enabled` is set to `true` in the `values.yaml` file. The default namespace for External Secrets Operator is `external-secrets`.

### Testing the External Secrets Operator

#### Apply the config

To test the External Secrets Operator, you'll create two resources: a `SecretStore` and an `ExternalSecret`.

The `SecretStore` defines where secrets are stored (in this case, using a fake provider for testing purposes). The `ExternalSecret` defines which secrets to retrieve and how to map them into a Kubernetes Secret.

Create a file named `eso-test.yaml` with the following content:

```yaml
---
# SecretStore using the fake provider for testing
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: fake-secret-store
  namespace: obaas-dev
spec:
  provider:
    fake:
      data:
        - key: "test-secret-key"
          value: "test-secret-value"
        - key: "database-password"
          value: "super-secret-password"
        - key: "api-token"
          value: "fake-api-token-12345"
---
# ExternalSecret that references the fake SecretStore
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: obaas-dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: fake-secret-store
    kind: SecretStore
  target:
    name: my-test-secret
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: database-password
    - secretKey: token
      remoteRef:
        key: api-token
```

**Understanding the configuration:**

- **SecretStore** (`fake-secret-store`):
  - Uses the `fake` provider, which is designed for testing without requiring an external secret management system
  - Contains three hardcoded key-value pairs that simulate secrets stored in an external vault
  - In production, you would replace this with a real provider like OCI Vault, AWS Secrets Manager, etc.

- **ExternalSecret** (`test-external-secret`):
  - References the `fake-secret-store` SecretStore
  - Creates a Kubernetes Secret named `my-test-secret` in the target namespace
  - Uses `creationPolicy: Owner` so the Secret is automatically deleted when the ExternalSecret is removed
  - Maps two secrets from the store:
    - `database-password` → `password` (in the Kubernetes Secret)
    - `api-token` → `token` (in the Kubernetes Secret)
  - Refreshes every 1 hour (`refreshInterval: 1h`) to sync changes from the external source

Apply the configuration:

```shell
kubectl apply -f eso-test.yaml
```

You should see output similar to:
```
secretstore.external-secrets.io/fake-secret-store created
externalsecret.external-secrets.io/test-external-secret created
```

The External Secrets Operator will automatically create a Kubernetes Secret named `my-test-secret` containing the mapped secrets.

#### Check the ExternalSecret status

After applying the configuration, verify that both the SecretStore and ExternalSecret resources were created successfully and are in the correct state.

```shell
kubectl get secretstores,externalsecrets -n obaas-dev
```

You should see output similar to:

```
NAME                                          AGE   STATUS   CAPABILITIES   READY
secretstore.external-secrets.io/fake-secret-store   10s   Valid    ReadWrite      True

NAME                                                  STORE               REFRESH INTERVAL   STATUS         READY
externalsecret.external-secrets.io/test-external-secret   fake-secret-store   1h                 SecretSynced   True
```

**Understanding the output:**

- **SecretStore Status**:
  - `STATUS: Valid` - The SecretStore configuration is valid and the provider is accessible
  - `READY: True` - The SecretStore is ready to be used by ExternalSecrets
  - `CAPABILITIES: ReadWrite` - Indicates the store supports both reading and writing secrets

- **ExternalSecret Status**:
  - `STORE: fake-secret-store` - Shows which SecretStore this ExternalSecret is using
  - `REFRESH INTERVAL: 1h` - How often the operator will check for updates from the external source
  - `STATUS: SecretSynced` - The secret has been successfully synchronized from the external source
  - `READY: True` - The ExternalSecret is ready and the target Kubernetes Secret has been created

**Common status values:**

- `SecretSynced` - Everything is working correctly, the secret has been created
- `SecretSyncedError` - There was an error syncing the secret (check the ExternalSecret events for details)
- `SecretDeleted` - The target secret was deleted (the operator will recreate it on the next sync)

If the `READY` column shows `False`, use `kubectl describe` to get more details:

```shell
kubectl describe externalsecret test-external-secret -n obaas-dev
```

#### Verify the secret was created

The External Secrets Operator should have automatically created a Kubernetes Secret named `my-test-secret` based on the ExternalSecret configuration. Let's verify that the secret exists and contains the expected data.

First, check that the secret exists:

```shell
kubectl get secret my-test-secret -n obaas-dev
```

You should see output similar to:

```
NAME             TYPE     DATA   AGE
my-test-secret   Opaque   2      30s
```

The `DATA` column shows `2`, indicating the secret contains two key-value pairs (password and token).

Now, view the secret's contents in a readable format:

```shell
kubectl get secret my-test-secret -n obaas-dev -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

You should see the decoded secret values:

```
password: super-secret-password
token: fake-api-token-12345
```

Describe the secret to see metadata and ownership:

```shell
kubectl describe secret my-test-secret -n obaas-dev
```

This will show that the secret is owned by the ExternalSecret resource, confirming it was created by the External Secrets Operator.

**Troubleshooting:**

If the secret doesn't exist:
- Check the ExternalSecret status with `kubectl get externalsecret test-external-secret -n obaas-dev`
- View ExternalSecret events with `kubectl describe externalsecret test-external-secret -n obaas-dev`
- Check the operator logs as described in the Monitoring section

#### Cleanup

To remove the test resources, delete the ExternalSecret and SecretStore:

```shell
kubectl delete externalsecret test-external-secret -n obaas-dev
kubectl delete secretstore fake-secret-store -n obaas-dev
```

The `my-test-secret` Kubernetes Secret will be automatically deleted when the ExternalSecret is removed due to the `creationPolicy: Owner` setting.

Alternatively, you can use a cleanup manifest:

```yaml
# Cleanup file for External Secrets test resources
# This will remove the ExternalSecret, SecretStore, and the generated secret
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: obaas-dev
---
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: fake-secret-store
  namespace: obaas-dev
---
# The my-test-secret will be automatically deleted when the ExternalSecret is deleted
# due to creationPolicy: Owner, but including it here for completeness
apiVersion: v1
kind: Secret
metadata:
  name: my-test-secret
  namespace: obaas-dev
```

Apply with:
```shell
kubectl delete -f eso-cleanup.yaml
```

### Using with Production Secret Stores

The External Secrets Operator can be configured to use production secret management systems like OCI Vault or HashiCorp Vault.

#### OCI Vault Configuration

To use OCI Vault, configure a SecretStore with workload identity authentication.

For complete configuration details, see the [OCI Vault provider documentation](https://external-secrets.io/latest/provider/oracle-vault/).

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: oci-vault-store
  namespace: obaas-dev
spec:
  provider:
    oracle:
      vault: ocid1.vault.oc1..<your-vault-ocid>
      region: us-phoenix-1
      auth:
        workload:
          serviceAccountRef:
            name: external-secrets-sa
```

**Key configuration points:**

- `vault`: The OCID of your OCI Vault
- `region`: The OCI region where your vault is located
- `auth.workload`: Uses Kubernetes workload identity for authentication (recommended for production). See [Granting Workloads Access to OCI Resources](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contenggrantingworkloadaccesstoresources.htm) for workload identity setup
- `serviceAccountRef.name`: The Kubernetes service account configured with OCI Workload Identity. This service account must be mapped to an OCI IAM principal with permissions to read secrets from the vault

Create an ExternalSecret that references OCI Vault secrets:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: app-database-secret
  namespace: obaas-dev
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: oci-vault-store
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: ocid1.vaultsecret.oc1..<your-secret-ocid>
    - secretKey: username
      remoteRef:
        key: ocid1.vaultsecret.oc1..<your-username-secret-ocid>
```

**Note:** The `remoteRef.key` must be the OCID of the secret in OCI Vault, not the secret name.

**Alternative Authentication Methods:**

In addition to workload identity, OCI Vault supports:
- User principal authentication (using API keys)
- Instance principal authentication (for compute instances)

Refer to the [OCI Vault provider documentation](https://external-secrets.io/latest/provider/oracle-vault/) for detailed configuration options.

#### HashiCorp Vault Configuration

To use HashiCorp Vault, configure a SecretStore with appropriate authentication.

For complete configuration details, see the [HashiCorp Vault provider documentation](https://external-secrets.io/latest/provider/hashicorp-vault/).

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: vault-store
  namespace: obaas-dev
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets-role"
          serviceAccountRef:
            name: external-secrets-sa
```

**Key configuration points:**

- `server`: The URL of your HashiCorp Vault server
- `path`: The mount path where your secrets are stored (e.g., "secret" for KV v2 engine)
- `version`: The KV secrets engine version ("v1" or "v2")
- `auth.kubernetes`: Uses Kubernetes authentication method
- `mountPath`: The mount path of the Kubernetes auth method in Vault
- `role`: The Vault role that grants access to secrets

Create an ExternalSecret that references HashiCorp Vault secrets:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: app-config-secret
  namespace: obaas-dev
spec:
  refreshInterval: 10m
  secretStoreRef:
    name: vault-store
    kind: SecretStore
  target:
    name: application-config
    creationPolicy: Owner
  data:
    - secretKey: api-key
      remoteRef:
        key: myapp/config
        property: api_key
    - secretKey: db-password
      remoteRef:
        key: myapp/database
        property: password
```

**Note:** For HashiCorp Vault:
- `remoteRef.key` is the path to the secret in Vault (e.g., "myapp/config")
- `remoteRef.property` is the specific field within that secret (for KV v2 engine)

**Alternative Authentication Methods:**

In addition to Kubernetes authentication, HashiCorp Vault supports:
- AppRole authentication
- Token authentication
- JWT/OIDC authentication
- AWS IAM authentication (when running in AWS)

Refer to the [HashiCorp Vault provider documentation](https://external-secrets.io/latest/provider/hashicorp-vault/) for detailed configuration options.

### Monitoring External Secrets

#### Check ExternalSecret Status

Monitor the sync status of your ExternalSecrets:

```shell
kubectl get externalsecrets -n obaas-dev
```

The output shows the sync status, refresh time, and age:
```
NAME                   STORE               REFRESH INTERVAL   STATUS         READY
test-external-secret   fake-secret-store   1h                 SecretSynced   True
```

#### View Detailed Status

For detailed information about a specific ExternalSecret:

```shell
kubectl describe externalsecret test-external-secret -n obaas-dev
```

This shows:
- Current sync status
- Last sync time
- Any error messages
- Conditions and events

#### Monitor External Secrets Operator Logs

View the operator logs to troubleshoot sync issues:

```shell
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

Filter for specific ExternalSecret logs:

```shell
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets | grep test-external-secret
```

#### Check Secret Sync Events

Monitor Kubernetes events for your ExternalSecrets:

```shell
kubectl get events -n obaas-dev --field-selector involvedObject.name=test-external-secret
```

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).
