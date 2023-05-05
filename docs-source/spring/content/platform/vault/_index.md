---
title: "Vault"
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
---

Oracle Backend as a Service for Spring Cloud includes [HashiCorp Vault](https://www.vaultproject.io/) to secure, store and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.

{{< hint type=[tip] icon=gdoc_check title=Tip >}}
For more information about working with the HashiCorp Vault, see the [HashiCorp Vault Documentation](https://www.vaultproject.io/) and [Tutorials Library](https://developer.hashicorp.com/tutorials/library?product=vault).
{{< /hint >}}

## Setup Information

Vault uses the following Oracle OCI Services:

- [Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/home.htm) for storing Vault data
- [OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/home.htm) to auto unseal the Vault
- [Container Engine for Kubernetes](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm#) for running the Vault server

The Vault is [unsealed](https://developer.hashicorp.com/vault/docs/configuration/seal/ocikms) using the OCI KMS key. The `root` token is provided during deployment of Oracle Backend as a Service for Spring Cloud.

The following Vault services are enabled during deployment. Other services can be enabled using the `vault` command and the Web User Interface.

- [Token Auth Method](https://developer.hashicorp.com/vault/docs/auth/token). The `token` auth method is built-in and automatically available. It allows users to authenticate using a token, as well to create new tokens, revoke secrets by token, and more.
- [AppRole Auth Method](https://developer.hashicorp.com/vault/docs/auth/approle). The `approle` auth method allows machines or apps to authenticate with Vault-defined roles.
- [Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes). The `kubernetes` auth method can be used to authenticate with Vault using a Kubernetes Service Account Token. This method of authentication makes it easy to introduce a Vault token into a Kubernetes Pod.
- [Userpass Auth Method](https://developer.hashicorp.com/vault/docs/auth/userpass)The `userpass` auth method allows users to authenticate with Vault using a username and password combination.
- [KV Secrets Engine Version 2](https://developer.hashicorp.com/vault/docs/secrets/kv). The kv secrets engine is a generic Key-Value store used to store arbitrary secrets.


## Accessing Vault using using kubectl

1. To access Vault using kubectl you need to setup [Kubernetes Access](../../cluster-access/_index.md)

2. Test access to Vault

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

3. Login into Vault

    To interact with vault you need to login using a token. The root token is stored in a k8s secret. Get the token by running this command, the output is the root token. It is **VERY IMPORTANT** that the token is saved in multiple places, loosing the token can result in loss of access to the Vault.

    ```shell
    kubectl get secret vault-root-token -n vault --template="{{index .data \"root.token\" | base64decode}}"
    ```

    Login to the vault:

    ```shell
    kubectl exec pod/vault-0 -n vault  -it -- vault login
    Token (will be hidden):
    ```

    Sample output from logging in as the `root` user which only should be done initial setup. As an administrator you **must** generate separate tokens and ACLs for the users than needs access to Vault. See [Vault Documentation](https://developer.hashicorp.com/vault/docs).

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

4. Display the enabled secret engines

    To display the enabled secrets engines execute the following command:

    ```shell
    kubectl exec pod/vault-0 -n vault  -it -- vault secrets list
    ```

    The output will look similar to this:

    ```text
    Path          Type         Accessor              Description
    ----          ----         --------              -----------
    cubbyhole/    cubbyhole    cubbyhole_a07a59ec    per-token private secret storage
    identity/     identity     identity_8b1e1a80     identity store
    kv-v2/        kv           kv_06acc397           n/a
    sys/          system       system_df5c39a8       system endpoints used for control, policy and debugging
    ```

5. Display the authentication methods enabled:

    To display the enabled authentication methods execute the following command:

    ```shell
    kubectl exec pod/vault-0 -n vault  -it -- vault auth list
    ```

    The output will look similar to this:

    ```text
    Path           Type          Accessor                    Description
    ----           ----          --------                    -----------
    approle/       approle       auth_approle_00ffb93b       n/a
    kubernetes/    kubernetes    auth_kubernetes_c9bb0698    n/a
    token/         token         auth_token_68b0beb2         token based credentials
    userpass/      userpass      auth_userpass_afb2fb02      n/a
    ```

6. Create a secret

    Create a secret at path `kv-v2/customer/acme` with a `nme` and an `email`

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault kv put -mount=kv-v2 customer/acme customer_name="ACME Inc." \                 contact_email="john.smith@acme.com"
    ```

    The output will look similar to this:

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

7. Get a secret

    Get the created secret:

    ```shell
    kubectl exec pod/vault-0 -n vault -it -- vault kv get -mount=kv-v2 customer/acme
    ```

    The output will look similar to this:

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

For more information about the Key/Value secrets engine [Key/value Documentation](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) and [Versioned Key/Value Secrets Engine Tutorial](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv).

## Accessing Vault using the Web User Interface

1. Expose the Vault Web User Interface using `port-forward`

    ```shell
    kubectl port-forward -n vault svc/vault 8200:8200
    ```

2. Get the root token

    To interact with vault you need to login using a token. The root token is stored in a k8s secret. Get the token by running this command, the output is the root token. It is **VERY IMPORTANT** that the token is saved in multiple places, loosing the token can result in loss of access to the Vault.

    ```shell
    kubectl get secret root-token -n vault --template="{{index .data \"root.token\" | base64decode}}"
    ```

3. Open the Vault Web User Interface: <https://localhost:8200>

    <!-- spellchecker-disable -->
    {{< img name="vault-login" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Login using the root token. As an administrator you **must** generate separate tokens and ACLs for the users than needs access to Vault. See [Vault Documentation](https://developer.hashicorp.com/vault/docs).

    You are presented with the home screen showing the installed secret engines

    <!-- spellchecker-disable -->
    {{< img name="vault-home" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

4. Create a Key/Value secret

    Click on the `k2-v2` link from the home page.

    <!-- spellchecker-disable -->
    {{< img name="vault-kv-v2-home" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Click on the `Create Secret` link

    <!-- spellchecker-disable -->
    {{< img name="vault-create-secret" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    Create a secret

    <!-- spellchecker-disable -->
    {{< img name="vault-secret" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    View the secret content by clicking on the eye icon for each value

    <!-- spellchecker-disable -->
    {{< img name="vault-show-secret" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

## Accessing Vault Recovery Keys

Vault is configured to Auto Unseal using OCI Vault. Initializing with Auto Unseal creates five recovery keys and they are stored in k8s secrets. They **MUST** be retrieved and stored in a second location.

To extract the five recovery keys use the following commands:

``` shell
% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.1\" }}"

% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.2\" }}"

% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.3\" }}"

% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.4\" }}"

% kubectl get secret vault-recovery-keys -n vault --template="{{index .data \"recovery.key.5\" }}"
```