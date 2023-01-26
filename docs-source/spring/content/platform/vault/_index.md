---
title: "Vault"
resources:
  - name: vault-login
    src: "vault-login.png"
    title: "Vault Web User Interface"
---

Oracle Backend as a Service for Spring Cloud includes [Hashicorp Vault](https://www.vaultproject.io/) to secure, store and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.

{{< hint type=[tip] icon=gdoc_check title=Tip >}}
For more information about working with the Hashicorp Vault, see the [Hashicorp Vault Documentation](https://www.vaultproject.io/) and [Tutorials Library](https://developer.hashicorp.com/tutorials/library?product=vault).
{{< /hint >}}

## Setup Information

Vault uses the following Oracle OCI Services:

- [Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm) for storing Vault data
- [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm) to auto unseal the Vault
- [Container Engine for Kubernetes](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm#) for running the Vault server

The Vault has ben unsealed using the OCI Vault Master Key. The `root` token is provided during deployment of Oracle Backend as a Service for Spring Cloud.

The following Vault services are enabled during deployment. Other services can be enabled using the `vault` command and the Web User Interface.

- [Token Auth Method](https://developer.hashicorp.com/vault/docs/auth/token). The token auth method is built-in and automatically available. It allows users to authenticate using a token, as well to create new tokens, revoke secrets by token, and more.
- [KV Secrets Engine Version 2](https://developer.hashicorp.com/vault/docs/secrets/kv). The kv secrets engine is a generic Key-Value store used to store arbitrary secrets.
- [AppRole Auth Method](https://developer.hashicorp.com/vault/docs/auth/approle). The approle auth method allows machines or apps to authenticate with Vault-defined roles.

## Accessing Vault using using kubectl

1. To access Vault using kubectl you need to setup [Kubernetes Access](../../cluster-access/_index.md)

2. Install the Vault client using these instructions [Install Vault](https://developer.hashicorp.com/vault/downloads). **NOTE** Installing the server part is not required to access Vault.

3. Expose the Vault Server using `port-forward`

    ```shell
    kubectl port-forward -n vault svc/vault 8200:8200
    ```

4. Test access to Vault

    [Vault Documentation](https://developer.hashicorp.com/vault/docs) contains all the commands you can use with the Vault CLI. For example this command returns the current status of Vault:

    ```shell
    kubectl exec pod/vault-0 -n vault  -it -- vault status
    ```

    The output will be similar to this:

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

5. Login into Vault

    To interact with vault you need to login using a token.

    ```shell
    kubectl exec pod/vault-0 -n vault  -it -- vault login
    Token (will be hidden):
    ```

    Sample output from logging in as the `root` user which only should be done initial setup. As an administrator you **must** generate separate tokens and ACLs for the users than needs access to Vault. See [Vault Documentation](https://developer.hashicorp.com/vault/docs). The `root` token is provided after successful deployment.

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

## Accessing Vault using the Web User Interface

1. Expose the Vault Web User Interface using `port-forward`

    ```shell
    kubectl port-forward -n vault svc/vault 8200:8200
    ```

2. Open the Vault Web User Interface: <https://localhost:8200>

    <!-- spellchecker-disable -->
    {{< img name="vault-login" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Login using a token. The `root` token is provided after successful deployment.
