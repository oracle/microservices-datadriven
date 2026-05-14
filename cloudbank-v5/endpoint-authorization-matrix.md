# CloudBank v5 Endpoint Authorization Matrix

This file is a reference input table for defining roles, scopes, and endpoint authorization rules.
It is not the final security policy yet.

Scope:

- Includes deployed Spring services: `account`, `customer`, `creditscore`, `transfer`, `checks`, and `testrunner`.
- Includes planned `azn-server` endpoints from `markxnelson/azn-server` branch `SPRING_BOOT_3.X`.
- Excludes Helidon services and `chatbot` for this round.
- Paths are application paths unless the `Gateway route` column says otherwise.

Suggested placeholder meanings:

- `TBD`: role/scope still needs to be assigned.
- `Public`: no bearer token expected.
- `Internal`: service-to-service or framework callback; should not be public internet API.
- `Auth Server`: authorization-server protocol endpoint.

## Suggested Scopes And Roles

Use OAuth scopes for API authorization. Keep roles mainly as convenient user/client groupings that grant scopes.

### Scopes

| Scope | Purpose |
| --- | --- |
| `cloudbank.read` | Read account, customer, journal, transaction, and credit-score data. |
| `cloudbank.write` | Create or update normal CloudBank banking resources. |
| `cloudbank.admin` | Destructive/admin operations such as deleting accounts or customers. |
| `cloudbank.transfer` | Start the transfer workflow. |
| `cloudbank.internal` | Service-to-service calls and LRA callback/participant endpoints. Do not grant to normal user tokens. |
| `cloudbank.test` | Test runner endpoints only. Do not grant to normal user tokens. |
| `azn.users.read` | Read authorization-server users. |
| `azn.users.write` | Create/update authorization-server users and credentials. |
| `azn.users.admin` | Delete authorization-server users and change user roles. |
| `actuator.read` | Protected actuator endpoints, if required. |

### Roles

| Role | Suggested granted scopes |
| --- | --- |
| `ROLE_BANK_USER` | `cloudbank.read`, `cloudbank.transfer` |
| `ROLE_BANK_STAFF` | `cloudbank.read`, `cloudbank.write`, `cloudbank.transfer` |
| `ROLE_BANK_ADMIN` | `cloudbank.read`, `cloudbank.write`, `cloudbank.transfer`, `cloudbank.admin` |
| `ROLE_TESTER` | `cloudbank.test` |
| `ROLE_SERVICE` | `cloudbank.internal` |
| `ROLE_ACTUATOR` | `actuator.read` |
| `ROLE_AUTH_ADMIN` | `azn.users.read`, `azn.users.write`, `azn.users.admin` |

## Cross-Cutting Endpoints

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| all Spring services | GET | `/actuator/health` | Usually not externally routed | Operations | Public or Ops TBD | Needed for Kubernetes/platform health checks. |
| all Spring services | GET | `/actuator/info` | Usually not externally routed | Operations | Public or Ops TBD | Consider whether this leaks build/env details. |
| all Spring services | GET | `/actuator/prometheus` | Usually not externally routed | Metrics | Public within cluster or `SCOPE_actuator.read` | Needed for SigNoz metric scraping. |
| all Spring services | any | `/error` | n/a | Framework | Public | Needed so Spring can render error responses cleanly. |

## Account Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| account | GET | `/api/v1/accounts` | `/api/v1/account*` | Account read | `SCOPE_cloudbank.read` | List all accounts. |
| account | POST | `/api/v1/account` | `/api/v1/account*` | Account write | `SCOPE_cloudbank.write` | Create account. |
| account | GET | `/api/v1/account/{accountId}` | `/api/v1/account*` | Account read | `SCOPE_cloudbank.read` | Read account by id. |
| account | GET | `/api/v1/account/getAccounts/{customerId}` | `/api/v1/account*` | Account read | `SCOPE_cloudbank.read` | Read accounts by customer id. |
| account | DELETE | `/api/v1/account/{accountId}` | `/api/v1/account*` | Account admin/write | `SCOPE_cloudbank.admin` | Delete account. |
| account | GET | `/api/v1/account/{accountId}/transactions` | `/api/v1/account*` | Account read | `SCOPE_cloudbank.read` | Read account transactions. |
| account | POST | `/api/v1/account/journal` | `/api/v1/account/journal*` block route | Internal write | `SCOPE_cloudbank.internal` | Called by `checks`; service-to-service only. APISIX blocks external access with an unissued scope. |
| account | GET | `/api/v1/account/{accountId}/journal` | `/api/v1/account*` | Account read | `SCOPE_cloudbank.read` | Read journal entries. |
| account | POST | `/api/v1/account/journal/{journalId}/clear` | `/api/v1/account/journal*` block route | Internal write | `SCOPE_cloudbank.internal` | Called by `checks`; service-to-service only. APISIX blocks external access with an unissued scope. |
| account | POST | `/deposit` | Not currently public route | LRA participant | `SCOPE_cloudbank.internal` | Called by `transfer`; requires LRA header. |
| account | PUT | `/deposit/complete` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx completion callback. |
| account | PUT | `/deposit/compensate` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx compensation callback. |
| account | GET | `/deposit/status` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx status callback. |
| account | PUT | `/deposit/after` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx after-LRA callback. |
| account | POST | `/withdraw` | Not currently public route | LRA participant | `SCOPE_cloudbank.internal` | Called by `transfer`; requires LRA header. |
| account | PUT | `/withdraw/complete` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx completion callback. |
| account | PUT | `/withdraw/compensate` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx compensation callback. |
| account | PUT | `/withdraw/after` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx after-LRA callback. |
| account | n/a | withdraw status method | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | `WithdrawService.status` has `@Status` but no explicit Spring mapping; verify during implementation. |

## Customer Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| customer | GET | `/api/v1/customer` | `/api/v1/customer*` | Customer read | `SCOPE_cloudbank.read` | List customers. |
| customer | GET | `/api/v1/customer/name/{customerName}` | `/api/v1/customer*` | Customer read | `SCOPE_cloudbank.read` | Search customers by name. |
| customer | GET | `/api/v1/customer/{id}` | `/api/v1/customer*` | Customer read | `SCOPE_cloudbank.read` | Read customer by id. |
| customer | GET | `/api/v1/customer/byemail/{email}` | `/api/v1/customer*` | Customer read | `SCOPE_cloudbank.read` | Search customers by email. |
| customer | POST | `/api/v1/customer` | `/api/v1/customer*` | Customer write | `SCOPE_cloudbank.write` | Create customer. |
| customer | PUT | `/api/v1/customer/{id}` | `/api/v1/customer*` | Customer write | `SCOPE_cloudbank.write` | Update customer. |
| customer | DELETE | `/api/v1/customer/{customerId}` | `/api/v1/customer*` | Customer admin/write | `SCOPE_cloudbank.admin` | Delete customer. |
| customer | POST | `/api/v1/customer/applyLoan/{amount}` | `/api/v1/customer*` | Loan workflow | `SCOPE_cloudbank.write` | Currently returns `418 I_AM_A_TEAPOT`; decide whether to expose. |

## Credit Score Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| creditscore | GET | `/api/v1/creditscore` | `/api/v1/creditscore*` | Credit read | `SCOPE_cloudbank.read` | Returns random credit score for sample use. |

## Transfer Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| transfer | GET | `/hello` | Current route docs use `/api/v1/transfer*` | Health/sample | `SCOPE_cloudbank.read` or remove | Prefer removing from public docs if not needed. |
| transfer | POST | `/transfer` | `/transfer` | Transfer write | `SCOPE_cloudbank.transfer` | Starts transfer LRA workflow. Use valid account IDs from `/api/v1/accounts`. |
| transfer | POST | `/processconfirm` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | Internal process confirmation callback. |
| transfer | POST | `/processcancel` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | Internal process cancellation callback. |
| transfer | POST | `/confirm` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx completion callback; calls `/processconfirm`. |
| transfer | POST | `/cancel` | Not currently public route | LRA callback | `SCOPE_cloudbank.internal` | MicroTx compensation callback; calls `/processcancel`. |

## Checks Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| checks | n/a | JMS destination `deposits` | n/a | Async consumer | `SCOPE_cloudbank.internal` | Consumes `CheckDeposit` messages from `testrunner`. |
| checks | n/a | JMS destination `clearances` | n/a | Async consumer | `SCOPE_cloudbank.internal` | Consumes `Clearance` messages from `testrunner`. |
| checks | POST | outbound `/api/v1/account/journal` | n/a | Service-to-service call | `SCOPE_cloudbank.internal` | Feign client call to `account`; requires service token/scope. |
| checks | POST | outbound `/api/v1/account/journal/{journalId}/clear` | n/a | Service-to-service call | `SCOPE_cloudbank.internal` | Feign client call to `account`; requires service token/scope. |

## Test Runner Service

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| testrunner | POST | `/api/v1/testrunner/deposit` | `/api/v1/testrunner*` | Test workflow | `SCOPE_cloudbank.test` | Publishes to JMS destination `deposits`. Test/admin-only. |
| testrunner | POST | `/api/v1/testrunner/clear` | `/api/v1/testrunner*` | Test workflow | `SCOPE_cloudbank.test` | Publishes to JMS destination `clearances`. Test/admin-only. |

## Planned Authorization Server Service

These endpoints come from the planned `azn-server` based on `SPRING_BOOT_3.X`.

| Service | Method | Application path | Gateway route | Endpoint type | Required role/scope | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| azn-server | GET | `/.well-known/**` | `/.well-known/*` | Auth Server metadata | Public | Includes OAuth/OIDC discovery metadata. |
| azn-server | GET | `/oauth2/jwks` | `/oauth2/*` | Auth Server keys | Public | JWK set for JWT verification. |
| azn-server | POST | `/oauth2/token` | `/oauth2/*` | Auth Server token | Client auth | Token issuance. Usually client credentials for automation/internal calls. |
| azn-server | GET/POST | `/oauth2/authorize` | `/oauth2/*` | Auth Server authorize | Authenticated user | Used by authorization-code flows if enabled. |
| azn-server | GET/POST | `/login` | Optional route TBD | Auth Server login | Public form entry | Spring Security form login for browser flows. Verify whether this should be externally exposed. |
| azn-server | GET | `/user/api/v1/ping` | Not externally routed | User API health/sample | Cluster-internal only | Explicitly permitted in service config, so do not expose through APISIX. |
| azn-server | GET | `/user/api/v1/forgot` | Not externally routed | Password reset | `ROLE_ADMIN` basic auth | Finds user/email details for reset flow; do not expose through APISIX. |
| azn-server | POST | `/user/api/v1/forgot` | Not externally routed | Password reset | `ROLE_ADMIN` basic auth | Saves one-time password hash; do not expose through APISIX. |
| azn-server | PUT | `/user/api/v1/forgot` | Not externally routed | Password reset | `ROLE_ADMIN` basic auth | Resets password with OTP; do not expose through APISIX. |
| azn-server | GET | `/user/api/v1/connect` | Not externally routed | User API | Cluster-internal only | Reference requires any of `ADMIN`, `USER`, or `CONFIG_EDITOR`. |
| azn-server | GET | `/user/api/v1/findUser` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | POST | `/user/api/v1/createUser` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | PUT | `/user/api/v1/updatePassword` | Not externally routed | User self-service/admin | Cluster-internal only | Reference requires `USER`; admin can update others in method logic. |
| azn-server | PUT | `/user/api/v1/changeRole` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | PUT | `/user/api/v1/changeEmail` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | DELETE | `/user/api/v1/deleteUsername` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | DELETE | `/user/api/v1/deleteId` | Not externally routed | User admin | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | GET | `/user/api/v1/pinguser` | Not externally routed | User API sample | Cluster-internal only | Reference requires `USER`. |
| azn-server | GET | `/user/api/v1/pingadmin` | Not externally routed | User API sample | Cluster-internal only | Reference requires `ADMIN`. |
| azn-server | GET | `/user/api/v1/pingceditor` | Not externally routed | User API sample | Cluster-internal only | Reference requires `CONFIG_EDITOR`. |
| azn-server | GET | `/actuator/health` | Usually not externally routed | Operations | Public or Ops TBD | Reference permits health/info. |
| azn-server | GET | `/actuator/info` | Usually not externally routed | Operations | Public or Ops TBD | Reference permits health/info. |
| azn-server | GET | `/actuator/prometheus` | Usually not externally routed | Metrics | `SCOPE_actuator.read` or cluster-only public | Reference protects non-health/info actuator endpoints with `ACTUATOR`; decide if SigNoz scraping needs unauthenticated cluster access. |

## Open Decisions

| Decision | Options / notes | Owner |
| --- | --- | --- |
| Scope names | Examples: `cloudbank.read`, `cloudbank.write`, `cloudbank.admin`, `cloudbank.internal`, `cloudbank.test`, `azn.users.admin`. | TBD |
| Role names | Examples: `ROLE_USER`, `ROLE_ADMIN`, `ROLE_CONFIG_EDITOR`, `ROLE_ACTUATOR`, service roles. | TBD |
| LRA callback policy | Permit callback paths by path/header only, require service token, or both. Must not break MicroTx callbacks. | TBD |
| Transfer gateway path | APISIX exposes the transfer workflow at `/transfer`, matching the Spring controller. | Done |
| Testrunner exposure | Decide whether `testrunner` remains externally reachable or becomes admin/test-only. | TBD |
| Auth-server user API exposure | Keep `/user/api/v1*` cluster/admin-only; APISIX route script removes stale route `1012` if present. | Done |
