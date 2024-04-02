---
title: "HashiCorp Vault"
description: "Securing secrets with HashiCorp Vault in Oracle Backend for Spring Boot and Microservices"
keywords: "vault secrets security springboot spring development microservices development oracle backend"
resources:
  - name: vault-login
    src: "vault-login.png"
    title: "Vault Web User Interface"
  - name: vault-home
    src: "vault-home.png"
    title: "Vault Home Page"
  - name: vault-kv-v2-home
    src: "vault-kv-v2-home.png"
    title: "Vault K/V V2 Home"
  - name: vault-create-secret
    src: "vault-create-secret.png"
    title: "Vault Create Secret"
  - name: vault-secret
    src: "vault-secret.png"
    title: "Vault Secret"
  - name: vault-show-secret
    src: "vault-show-secret.png"
    title: "Vault Show Secret"
  - name: vault-grafana
    src: "vault-grafana.png"
    title: "Vault Grafana Dashboard"
---

Oracle Backend as a Service for Spring Cloud and Microservices includes [HashiCorp Vault](https://www.vaultproject.io/) to secure, store and tightly control
access to tokens, passwords, certificates, encryption keys for protecting secrets, and other sensitive data using a user interface (UI),
command-line interface (CLI), or Hypertext Transfer Protocol (HTTP) API.

{{< hint type=[tip] icon=gdoc_check title=Tip >}}
For more information about working with the HashiCorp Vault, see
the [HashiCorp Vault Documentation](https://www.vaultproject.io/) and [Tutorials Library](https://developer.hashicorp.com/tutorials/library?product=vault).
{{< /hint >}}

- [Setup Information](#setup-information)
- [Accessing the `root` Token Production Mode](#accessing-the-root-token-production-mode)
- [Accessing the `root` Token Development Mode](#accessing-the-root-token-development-mode)
- [Accessing Vault Recovery Keys Production Mode](#accessing-vault-recovery-keys-production-mode)
- [Accessing Vault Using kubectl](#accessing-vault-using-kubectl)
- [Accessing the Vault Using the Web User Interface](#accessing-the-vault-using-the-web-user-interface)
- [Audit Logs](#audit-logs)
- [Grafana dashboard for HashiCorp Vault](#grafana-dashboard-for-hashicorp-vault)

## Setup Information

The Vault can be deployed in two different ways. See the [Setup](../../setup/):

- **Development** mode
- **Production** mode

{{< hint type=[warning] icon=gdoc_check title=Warning >}}
**Never** run a **Development** mode server in production. It is insecure and will lose data on every restart (since it stores data
in-memory). It is only intended for development or experimentation.
{{< /hint >}}

Vault uses the following Oracle Cloud Infrastructure (OCI) services when running in **Production** mode. When running in **Development** mode,
only the OCI Container Engine for Kubernetes (OKE) is used.

- [Object storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm) for storing Vault data.
- [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm) to automatically unseal the Vault.
- [OCI Container Engine for Kubernetes](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm#) for running the Vault server.

When running in **Production** mode, the Vault is [unsealed](https://developer.hashicorp.com/vault/docs/configuration/seal/ocikms) using the
OCI Key Management Service (KMS) key. The `root` token can be accessed using the `kubectl` command-line interface. The `root` token
in **Development** mode is `root`.

The following Vault services are enabled during deployment. Other services can be enabled using the `vault` command and the web user interface:

- [Token Authentication Method](https://developer.hashicorp.com/vault/docs/auth/token). The `token` authentication method is built-in and automatically available. It allows users to authenticate using a token, as well as create new tokens, revoke secrets by token, and more.
- [AppRole Authentication Method](https://developer.hashicorp.com/vault/docs/auth/approle). The `approle` authentication method allows machines or applications to authenticate with Vault-defined roles.
- [Kubernetes Authentication Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes). The `kubernetes` authentication method can be used to authenticate with Vault using a Kubernetes service account token. This method of authentication makes it easy to introduce a Vault token into a Kubernetes Pod.
- [Userpass Authentication Method](https://developer.hashicorp.com/vault/docs/auth/userpass). The `userpass` authentication method allows users to authenticate with Vault with a user name and password combination.
- [Key/Value Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv). The non-versioned Key/Value secrets engine is a generic Key/Value store used to store arbitrary secrets.
- [Key/Value Secrets Engine Version 2](https://developer.hashicorp.com/vault/docs/secrets/kv). The Key/Value secrets engine is a generic Key/Value store used to store arbitrary secrets.

### Accessing the `root` Token Production Mode

`root` tokens have the `root` policy attached to them. `root` tokens can do anything in Vault and are useful in **Development** mode but should be restricted in **Production** mode. In fact, the Vault team recommends that `root` tokens only be used for the initial setup. Be sure to save the initial `root` token in a secure way. For example:

```shell
kubectl get secret vault-root-token -n vault --template="{{index .data \"root.token\" | base64decode}}"; echo
```

{{< hint type=[warning] icon=gdoc_check title=Warning >}}
It is **very important** that the token is saved in multiple places. Losing the token can result in loss of access to the Vault.
{{< /hint >}}

### Accessing the `root` Token Development Mode

The `root` token is set to `root` in **Development** mode. There are no recovery keys when running in **Development** mode.

### Accessing Vault Recovery Keys Production Mode

Vault is configured to automatically unseal (auto unseal) using OCI Vault. Initializing with auto unseal creates five recovery keys that are stored in K8s Secrets. They **MUST** be retrieved and stored in a second location.

{{< hint type=[warning] icon=gdoc_check title=Warning >}}
It is **very important** that recovery keys are saved in multiple places. Losing the recovery keys can result in loss of Vault.
{{< /hint >}}

To extract the five recovery keys, use the following commands:

``` shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.1\" }}"; echo
```

```shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.2\" }}"; echo
```

```shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.3\" }}"; echo
```

```shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.4\" }}"; echo
```

```shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.5\" }}"; echo
```

## Accessing Vault Using kubectl

1. To access the Vault using the `kubectl` command-line interface, you need to set up [Access Kubernetes Cluster](../../cluster-access/_index.md).

1. Test access to the Vault.

    [Vault Documentation](https://developer.hashicorp.com/vault/docs) contains all of the commands that you can use with the Vault CLI. For example, this command returns the current status of Vault on one of the pods:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault status
    ```

    The output looks similar to this:

    ```text
    Key                      Value
    ---                      -----
    Recovery Seal Type       shamir
    Initialized              true
    Sealed                   false
    Total Recovery Shares    5
    Threshold                3
    Version                  1.11.3
    Build Date               2022-08-26T10:27:10Z
    Storage Type             oci
    Cluster Name             vault-cluster-28535f69
    Cluster ID               993662ee-b3ee-2a13-3354-97adae01e1ca
    HA Enabled               true
    HA Cluster               https://vault-0.vault-internal:8201
    HA Mode                  active
    Active Since             2023-01-26T16:14:32.628291153Z
    ```

1. Get the token and log in to the Vault.

    To interact with the Vault in **Production** mode, you need to log in using a token that is stored in a K8s Secret. Get the token by running the following command. The output is the `root` token. It is **very important** that the token is saved in multiple places. Losing the token can result in loss of access to the Vault. In **Development** mode, the `root` token is `root`.

    Get the token with this command:

    ```shell
    kubectl get secret vault-root-token -n vault --template="{{index .data \"root.token\" | base64decode}}"; echo
    ```

    Log in to the Vault and provide the token with this command:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault login
    ```

    The following is sample output from logging in as the `root` user which should only be done during the initial set up. As an administrator, you **must** generate separate tokens and access control lists (ACLs) for the users that need access to the Vault. See [Vault Documentation](https://developer.hashicorp.com/vault/docs). For example:

    ```text
    Key                  Value
    ---                  -----
    token                hvs.......
    token_accessor       Hcx.......
    token_duration       ∞
    token_renewable      false
    token_policies       ["root"]
    identity_policies    []
    policies             ["root"]
    ```

1. To display the enabled secret engines, process this command:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault secrets list
    ```

    The output looks similar to this:

    ```text
    Path          Type         Accessor              Description
    ----          ----         --------              -----------
    cubbyhole/    cubbyhole    cubbyhole_a07a59ec    per-token private secret storage
    identity/     identity     identity_8b1e1a80     identity store
    kv-v2/        kv           kv_06acc397           n/a
    sys/          system       system_df5c39a8       system endpoints used for control, policy and debugging
    ```

1. To display the enabled authentication methods, process this command:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault auth list
    ```

    The output looks similar to this:

    ```text
    Path           Type          Accessor                    Description
    ----           ----          --------                    -----------
    approle/       approle       auth_approle_00ffb93b       n/a
    kubernetes/    kubernetes    auth_kubernetes_c9bb0698    n/a
    token/         token         auth_token_68b0beb2         token based credentials
    userpass/      userpass      auth_userpass_afb2fb02      n/a
    ```

1. Create a secret at path `kv-v2/customer/acme` with a `customer_name` and a `customer_email`. For example:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault kv put -mount=kv-v2 \ 
    customer/acme customer_name="ACME Inc." contact_email="john.smith@acme.com"
    ```

    The output looks similar to this:

    ```text
    ====== Secret Path ======
    kv-v2/data/customer/acme

    ======= Metadata =======
    Key                Value
    ---                -----
    created_time       2023-01-30T15:53:41.85529383Z
    custom_metadata    <nil>
    deletion_time      n/a
    destroyed          false
    version            1
    ```

1. Retrieve the created secret:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault kv get -mount=kv-v2 customer/acme
    ```

    The output looks similar to this:

    ```text
    ====== Secret Path ======
    kv-v2/data/customer/acme

    ======= Metadata =======
    Key                Value
    ---                -----
    created_time       2023-01-30T15:53:41.85529383Z
    custom_metadata    <nil>
    deletion_time      n/a
    destroyed          false
    version            1

    ======== Data ========
    Key              Value
    ---              -----
    contact_email    john.smith@acme.com
    customer_name    ACME Inc.
    ```

For more information about the Key/Value secrets engine, see the [Key/Value Documentation](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
and [Versioned Key/Value Secrets Engine Tutorial](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv).

## Accessing the Vault Using the Web User Interface

To access the Vault, process these steps:

1. Expose the Vault web user interface (UI) using this command:

    ```shell
    kubectl port-forward -n vault svc/vault 8200
    ```

1. Get the `root` token.

    To interact with the Vault in **Production** mode, you need to log in using a token that is stored in a K8s Secret. Get the token by running the following command. The output is the `root` token. It is **very important** that the token is saved in multiple places. Losing the token can result in loss of access to the Vault. In **Development** mode, the `root` token is `root`. For example:

    ```shell
    kubectl get secret vault-root-token -n vault --template="{{index .data \"root.token\" | base64decode}}"; echo
    ```

1. Open the Vault web user interface URL: <https://localhost:8200>

    <!-- spellchecker-disable -->
    {{< img name="vault-login" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Log in using the `root` token. As an administrator, you **must** generate separate tokens and access control lists (ACLs) for the users that need access to the Vault. See [Vault Documentation](https://developer.hashicorp.com/vault/docs).

1. You are presented with the **Home** screen:

    <!-- spellchecker-disable -->
    {{< img name="vault-home" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

## Audit logs

{{< hint type=[important] icon=gdoc_check title=Important >}}
Audit logging is **blocking**, if the file is bigger than allowed space HashiCorp Vault will stop taking requests.
{{< /hint >}}

If you deployed Oracle Backend for Spring Boot and Microservices using `STANDARD` edition, HashiCorp Vault will be deployed in `production` mode and you have the option of turing on audit logs. **Note**, you must be authenticated to turn on audit logs.

To turn on audit logs execute the following command:

```shell
kubectl exec pod/vault-0 -n vault -it -- vault audit enable file file_path=/vault/audit/vault-audit.log
```

You can to list enabled audit devices using the following command. The `file_path` is pointing to a directory on the pods where Vault is running.

```shell
kubectl exec pod/vault-0 -n vault -it -- vault audit list -detailed
```

If audit is enabled the output should look like this:

```text
Path     Type    Description    Replication    Options
----     ----    -----------    -----------    -------
file/    file    n/a            replicated     file_path=/vault/audit/vault-audit.log
```

To disable audit execute the following command:

```shell
kubectl exec pod/vault-0 -n vault -it -- vault audit disable file
```

Learn how to query audit logs [here](https://developer.hashicorp.com/vault/tutorials/monitoring/query-audit-device-logs).

## Grafana dashboard for HashiCorp Vault

Oracle Backend for Spring Boot and Microservices includes a [Grafana dashboard for HashiCorp Vault](../../observability/metrics/).

<!-- spellchecker-disable -->
{{< img name="vault-grafana" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

