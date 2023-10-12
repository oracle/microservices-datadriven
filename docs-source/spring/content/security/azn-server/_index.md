---
title: "Authentication and Authorization Server"
resources:
  - name: azn-server-arch
    src: "azn-server-arch.png"
    title: "Authorization Server Architecture"
  - name: azn-stack-app-info
    src: "azn-stack-app-info.png"
    title: "Application Information"
  - name: azn-passwords-console
    src: "azn-passwords-console.png"
    title: "AZN User passwords"
---

The Authorization Server is an engine to authenticate and authorize requests to various components in Oracle Backend for Spring Boot and Microservices. The end user can manage users using REST Endpoints.

> **_NOTE:_** Oracle recommends that you change the default passwords for the default created users.

## Users & Roles

When deploying Oracle Backend for Spring Boot and Microservices, two users are created with the following roles:

| User Name     | Assigned Roles        |
|---------------|-----------------------|
| obaas-admin   | ROLE_ADMIN, ROLE_USER |
| obaas-user    | ROLE_USER             |

All users are stored in the database are deployed when installing Oracle Backend for Spring Boot and Microservices. The roles determine what the user is allowed to do in the environment. The allowed roles are `ROLE_ADMIN` and `ROLE_USER`.

> **_NOTE:_** See each components documentation about the roles and authorities.

The assigned passwords (either auto generated or provided by the installer) can be viewed in the OCI Console (ORM homepage). Click on **Application Information**.

<!-- spellchecker-disable -->
{{< img name="azn-stack-app-info" >}}
<!-- spellchecker-enable -->

If you click on **Unlock**, the password for the obaas-admin and obaas-user can be displayed.

<!-- spellchecker-disable -->
{{< img name="azn-passwords-console" >}}
<!-- spellchecker-enable -->

The passwords can also be obtained from k8s secrets using the `kubectl` command.

For `obaas-admin`:

```shell
kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
```

For `obaas-user`:

```shell
kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.user}' | base64 -d
```

## User Management REST endpoints

The following REST Endpoints are available to manage users. The table lists which minimum required role that is needed to perform the operation.

| End point                                         | Method | Description                                     | Minimum required Role |
|---------------------------------------------------|--------|-------------------------------------------------|-----------------------|
| /user/api/v1/findUser                             | GET    | Find all users                                  | ROLE_ADMIN            |
| /user/api/v1/findUser?username=\<username\>       | GET    | Find a user with the username \<username\>      | ROLE_ADMIN            |
| /user/api/v1/createUser                           | POST   | Create a user                                   | ROLE_ADMIN            |
| /user/api/v1/updatePassword                       | PUT    | Update a password for a user. A user with<br>Role ROLE_ADMIN can update any users password | ROLE_USER |
| /user/api/v1/deleteUsername?username=\<username\> | DELETE | Delete a user with username \<username\>        | ROLE_ADMIN            |
| /user/api/v1/deleteId?id=\<id\>                   | DELETE | Delete a user with the id \<id\>                | ROLE_ADMIN            |

### User Management REST Endpoints

In all examples below you need to replace `<username>:<password>` with your username and password. The examples are using `curl` to interact with the REST endpoints. They also requires that you have opened a tunnel on port 8080 to either the `azn-server` or `obaas-admin` service. For example

```shell
kubectl port-forward -n obaas-admin svc/obaas-admin 8080
```

#### /user/api/v1/findUser

```shell
curl -i -u <username>:<password> http://localhost:8080/user/api/v1/findUser
```

#### /user/api/v1/findUser?username=\<username\>

```shell
curl -i -u <username>:<password> 'http://localhost:8080/user/api/v1/findUser?username=obaas-admin'
```

#### /user/api/v1/createUser

When creating a user the following Roles are allowed: `ROLE_ADMIN` and `ROLE_USER`.

```shell
curl -u <username>:<password> -i -X POST \
    -H 'Content-Type: application/json' \
    -d '{"username": "a-new-user", "password": "top-secret-password", "roles" : "ROLE_ADMIN,ROLE_USER"}' \
    http://localhost:8080/user/api/v1/createUser
```

#### /user/api/v1/updatePassword

```shell
curl -u <username>:<password> -i -X PUT \
    -H 'Content-Type: application/json' \
    -d '{"username": "a-new-user", "password": "more-top-secret-password"}' \
    http://localhost:8080/user/api/v1/updatePassword
```

#### /user/api/v1/deleteUsername?username=\<username\>

```shell
curl -u <username>:<password> -i -X DELETE \ 
    http://localhost:8080/user/api/v1/deleteUsername?username=<username_to_be_deleted>
```

#### /user/api/v1/deleteId?id=\<id\>

```shell
curl -u obaas-admin:password -i -X DELETE \
    http://localhost:8080/user/api/v1/deleteId?id=<userid_to_be_deleted>
```

## Architecture

The following picture shows how the Authentication Server is used for AuthZ for the following modules:

- OBaaS Admin (OBaaS CLI server module)
- Config Server (Manages Config Server Entries)
- AZN Server (AUthentication Server User Management)
- GraalVM Compiler (GraalVM Native Compiler module)

<!-- spellchecker-disable -->
{{< img name="azn-server-arch" >}}
<!-- spellchecker-enable -->
