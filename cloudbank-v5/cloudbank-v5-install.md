# CloudBank v5 Installation Guide

**Last Updated:** 11/18/2025

## Overview

CloudBank v5 is a reference application that demonstrates modern cloud-native microservices architecture using Oracle Backend as a Service (OBaaS). This comprehensive banking application showcases enterprise-grade distributed systems patterns, event-driven architecture, and production observability practices.

### What You'll Build

This guide walks you through deploying a complete microservices ecosystem consisting of six interconnected services:

| Service         | Purpose                                                     | Key Technologies                            |
|-----------------|-------------------------------------------------------------|---------------------------------------------|
| **account**     | Manages customer accounts, balances, and transactions       | Spring Data JPA, Liquibase, LRA participant |
| **customer**    | Handles customer profiles and information                   | Spring Data JPA, Liquibase, Oracle ADB 23ai |
| **transfer**    | Orchestrates money transfers using distributed transactions | LRA coordinator, Saga pattern, MicroTx      |
| **checks**      | Processes check deposits and clearances asynchronously      | Oracle Advanced Queuing (AQ), JMS messaging |
| **creditscore** | Provides credit scoring services                            | Stateless REST service                      |
| **testrunner**  | Test harness for sending messages and triggering workflows  | AQ producer, integration testing            |

### Technology Stack

- **Runtime**: Java 21, Spring Boot 3.4.6, Spring Cloud 2024.0.1
- **Database**: Oracle Autonomous Database 26ai (or 19c) with Universal Connection Pool (UCP)
- **Transactions**: Oracle MicroTx for LRA coordination
- **Messaging**: Oracle Advanced Queuing (AQ) with JMS
- **Observability**: OpenTelemetry, Micrometer, Prometheus, SigNoz
- **Platform**: Kubernetes, Helm, Docker/OCI containers

**Estimated time:** 60 minutes

---

## ⚠️ Important Assumptions

**NAMESPACE REQUIREMENT:** This installation guide assumes that CloudBank v5 will be installed into the **same namespace** as your Oracle Backend as a Service (OBaaS) installation.

- **Default namespace:** `obaas-dev`
- **Why this matters:** CloudBank services need direct access to OBaaS components (Eureka, APISIX, database secrets, etc.) within the same namespace
- **Service discovery:** Services communicate using Kubernetes DNS names like `account.obaas-dev` or `customer.obaas-dev`
- **Shared resources:** Database secrets, wallet secrets, and other OBaaS resources must be accessible in the same namespace

If you need to use a different namespace:
1. Replace `obaas-dev` with your namespace name throughout this guide
2. Ensure your namespace has access to OBaaS components
3. Update all Helm values files with the correct namespace references

---

## Prerequisites

Before you begin, ensure you have:

### Required Software

- **Oracle Backend as a Service (OBaaS)** installed in namespace `obaas-dev`
- **Oracle Autonomous Database** installed with Oracle Database 26ai or 19c.
- **Java 21** installed
- **Maven 3.6+** installed
- **kubectl** configured and connected to your cluster
- **Docker** or compatible container runtime (Rancher Desktop, Docker Desktop, etc.)
- **yq** command-line tool installed (must be the `go` version by mikefarah, not the Python version)
  - **Ubuntu/Debian:** `sudo snap install yq` or `sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq`
  - **RHEL/CentOS/Fedora:** `sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq`
  - **macOS:** `brew install yq`
  - **Manual install:** Download from [github.com/mikefarah/yq/releases](https://github.com/mikefarah/yq/releases)
- **OCI CLI** (if using OCI Registry)
  - Install: [docs.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

### Required Access

- Access to a container registry (OCI Registry or Docker Hub)
- **Know your OCI region identifier** (if using OCI Registry)
  - Find your region: [OCI Regions and Availability Domains](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm)
  - Region format: `REGION_KEY.ocir.io` (e.g., `iad.ocir.io` for us-ashburn-1, `phx.ocir.io` for us-phoenix-1)
  - To find your current region: `oci iam region list --query "data[].{name:name,key:key}" --output table`
- **⚠️ Note:** Container registry repositories must be public (private repositories are currently not supported due to authentication issues)
- OBaaS admin secret for database access (typically `obaas-db-secret`)
- Autonomous Database wallet secret (typically `obaas-adb-tns-admin-1`)

### Verify Prerequisites

Run these commands to verify your environment is ready:

```bash
# Check Java version (should be 21)
java --version

# Check Maven version (should be 3.6+)
mvn --version

# Check kubectl connectivity
kubectl version
kubectl get nodes

# Check Docker/container runtime is running
docker ps

# Check yq is installed
yq --version

# Check OCI CLI (if using OCI Registry)
oci --version

# Verify you can access your Kubernetes namespace
kubectl get pods -n obaas-dev

# Verify OBaaS database secret exists
kubectl get secret obaas-db-secret -n obaas-dev

# Verify database wallet secret exists
kubectl get secret obaas-adb-tns-admin-1 -n obaas-dev
```

---

## Overview of Installation

The installation process consists of nine main steps:

1. **Configure Your Environment** - Set up Docker host, authenticate with registry, and create container repositories
2. **Build Dependencies** - Build and install common libraries and build tools
3. **Build CloudBank Microservices** - Compile services and push container images to your registry
4. **Configure Database** - Create database users (account and customer schemas)
5. **Create Kubernetes Secrets** - Set up database credentials and wallet secrets
6. **Configure Helm Values** - Update Helm charts with your image references and secret names
7. **Deploy CloudBank Services** - Install all six microservices using Helm
8. **Configure APISIX Routes** - Set up API Gateway routes
9. **Test the Installation** - Verify all services are running correctly

Each step must be completed in order, as later steps depend on the successful completion of earlier ones.

**Time breakdown:**
- Steps 1-2: ~10 minutes
- Step 3: ~20 minutes (includes build and push)
- Steps 4-6: ~15 minutes
- Steps 7-9: ~15 minutes

---

## Quick Reference

This section provides all commands in sequence for experienced users. Detailed explanations follow in each step.

```bash
# Step 1: Configure Environment
export DOCKER_HOST=unix:///Users/YOUR_USERNAME/.rd/docker.sock  # Rancher Desktop
docker login YOUR_REGION.ocir.io -u 'YOUR_TENANCY/USERNAME'
./create-oci-repos.sh COMPARTMENT_NAME YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5

# Step 2: Build Dependencies
mvn clean install -pl common,buildtools

# Step 3: Build Microservices
./update-jkube-image.sh YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5
mvn clean package k8s:build k8s:push -pl account,customer,transfer,checks,creditscore,testrunner

# Step 4: Configure Database
# Edit sqljob.yaml first, then:
kubectl create -f sqljob.yaml
kubectl get jobs -n obaas-dev  # Wait for completion

# Step 5: Create Secrets
# Edit acc_cust_secrets.sh first, then:
source acc_cust_secrets.sh
kubectl get secrets -n obaas-dev | grep -E 'account|customer'

# Step 6: Configure Helm Values
./update-image.sh YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5 0.0.1-SNAPSHOT

# Step 7: Deploy Services
./deploy-all-services.sh obaas-dev
kubectl get pods -n obaas-dev -w | grep cloudbank

# Step 8: Configure APISIX Routes
export APISIX_KEY=$(kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key')
# In Terminal 2:
kubectl port-forward -n obaas-dev svc/apisix-admin 9180
# In Terminal 1:
cd apisix-routes && source ./create-all-routes.sh $APISIX_KEY && cd ..

# Step 9: Test Installation
kubectl get pods -n obaas-dev | grep cloudbank
# Get gateway IP and test endpoints (see Step 9 for details)
```

---

## Step 1: Configure Your Environment

**What this step does:** Prepares your container runtime and creates the necessary container registry repositories for all six CloudBank microservices.

**Time estimate:** 5 minutes

### 1.1 Set Docker Host

Configure the DOCKER_HOST variable for your container runtime.

**For Rancher Desktop on macOS:**

```bash
export DOCKER_HOST=unix:///Users/YOUR_USERNAME/.rd/docker.sock
```

Replace `YOUR_USERNAME` with your actual macOS username.

**For Docker Desktop (macOS/Linux/Windows):**

```bash
export DOCKER_HOST=unix:///var/run/docker.sock
```

**For Linux native Docker:**

```bash
export DOCKER_HOST=unix:///var/run/docker.sock
```

**Verify Docker is accessible:**

```bash
docker ps
```

**Expected outcome:** Shows list of running containers (or empty list if none running). If you get "Cannot connect to Docker daemon", ensure Docker/Rancher Desktop is running and DOCKER_HOST is set correctly.

**✅ Verification:** Docker command works without errors

---

### 1.2 Authenticate with Container Registry

**For OCI Registry:**

```bash
docker login YOUR_REGION.ocir.io -u 'TENANCY_NAMESPACE/USERNAME'
```

When prompted, enter your OCI Auth Token (not your console password).

**Example:**

```bash
docker login YOUR_REGION.ocir.io -u 'YOUR_TENANCY/oracleidentitycloudservice/john.doe@example.com'
```

**For Docker Hub:**

```bash
docker login -u YOUR_DOCKERHUB_USERNAME
```

**✅ Verification:** You see "Login Succeeded" message

---

### 1.3 Create Container Registry Repositories

Run the provided script to create necessary repositories in OCI Registry.

**What this script does:**
- Takes a compartment name and repository prefix as parameters
- Looks up the compartment OCID from the compartment name
- Creates 6 public container repositories (one for each microservice):
  - account
  - customer
  - transfer
  - checks
  - creditscore
  - testrunner

**Command:**

```bash
./create-oci-repos.sh COMPARTMENT_NAME REGISTRY_PATH
```

**Parameters:**
- `COMPARTMENT_NAME`: Your OCI compartment name (not OCID)
- `REGISTRY_PATH`: Full registry path in format `YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5`

**Example:**

```bash
./create-oci-repos.sh my-compartment YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5
```

**⚠️ Note:** Replace `YOUR_TENANCY` with your actual OCI tenancy namespace throughout this guide. For example, if your tenancy namespace is `maacloud`, use `YOUR_REGION.ocir.io/maacloud/cloudbank-v5`.

**ℹ️ Tip:** To find your tenancy namespace:
```bash
oci iam compartment list --query "data[0].\"compartment-id\"" --raw-output
```

**Expected outcome:** Six repositories created successfully

**Verify repositories were created:**

```bash
# List repositories in your compartment
oci artifacts container repository list --compartment-id COMPARTMENT_OCID --query "data.items[*].{name:\"display-name\",is-public:\"is-public\"}" --output table
```

You should see 6 repositories, all with `is-public: True`.

**✅ Verification:** All 6 repositories exist and are public

**⚠️ If script fails:** Make sure OCI CLI is configured (`oci setup config`) and you have permissions to create repositories in the compartment.

---

## Step 2: Build Dependencies

**What this step does:** Builds and installs the `common` and `buildtools` modules that all CloudBank microservices depend on. These modules contain shared configuration, utility classes, and build tools (checkstyle, dependency-check).

**Time estimate:** 3-5 minutes

**Working directory:** Project root (`cloudbank-v5/`)

Build and install the common dependencies:

```bash
mvn clean install -pl common,buildtools
```

**What happens during this build:**
- `buildtools` module: Compiles checkstyle and dependency-check configurations
- `common` module: Compiles shared code (UCP telemetry, logging filters, common configurations)
- Both artifacts are installed to your local Maven repository (~/.m2/repository)

**Expected outcome:** Build completes with `BUILD SUCCESS` message

**Example successful output:**

```
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for CloudBank 0.0.1-SNAPSHOT:
[INFO]
[INFO] buildtools ......................................... SUCCESS [  1.234 s]
[INFO] common ............................................. SUCCESS [  3.456 s]
[INFO] CloudBank .......................................... SUCCESS [  0.123 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.813 s
[INFO] ------------------------------------------------------------------------
```

**✅ Verification:** You see "BUILD SUCCESS" and no errors in the output

**⚠️ Troubleshooting:** If build fails:
- Ensure you're in the project root directory (`cloudbank-v5/`)
- Ensure Java 21 is being used: `java --version`
- Check Maven can access dependencies: `mvn dependency:resolve`

---

## Step 3: Build CloudBank Microservices

**What this step does:** Updates Maven configuration with your container registry, builds all six microservice JARs, creates container images, and pushes them to your registry.

**Time estimate:** 15-20 minutes (depends on network speed)

### 3.1 Update Image Repository Configuration

Update the JKube Maven plugin configuration to point to your container registry.

**What this script does:**
- Updates the `<name>` tag in the JKube `<configuration>` section of each service's `pom.xml`
- Changes from default `my-repository/${project.artifactId}` to `<your-registry>/<service>:${project.version}`
- Processes all 6 services: account, customer, transfer, checks, creditscore, testrunner

**Command:**

```bash
./update-jkube-image.sh YOUR_REGISTRY_PATH
```

**Example:**

```bash
./update-jkube-image.sh YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5
```

**⚠️ Note:** Replace `YOUR_TENANCY` with your actual OCI tenancy namespace (same as in Step 1.3).

**Result:** Each service's pom.xml will have image name like:
```xml
<image>
    <name>YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account:${project.version}</name>
</image>
```

**✅ Verification:** Check one pom.xml was updated:

```bash
grep -A2 "<image>" account/pom.xml
```

You should see your registry path in the `<name>` tag.

---

### 3.2 Build and Push Images

Build all microservices and push container images to your registry.

**Command:**

```bash
mvn clean package k8s:build k8s:push -pl account,customer,transfer,checks,creditscore,testrunner
```

**What happens during this build:**

1. **Package phase** (per service):
   - Compiles Java source code
   - Runs checkstyle checks
   - Runs unit tests
   - Packages Spring Boot JAR with dependencies

2. **k8s:build phase** (per service):
   - Creates Dockerfile (using JKube defaults)
   - Builds container image with base image `ghcr.io/oracle/openjdk-image-obaas:21`
   - Tags image as `<registry>/<service>:0.0.1-SNAPSHOT`

3. **k8s:push phase** (per service):
   - Authenticates with registry (using docker login credentials)
   - Pushes image layers to registry
   - Shows progress with upload percentage

**Time warning:** This step takes 15-20 minutes depending on your network upload speed. Each image is approximately 300-400 MB.

**Progress indicators:** You'll see output like:

```
[INFO] k8s: [YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account:0.0.1-SNAPSHOT] : Built image sha256:abc123...
[INFO] k8s: [YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account:0.0.1-SNAPSHOT] : Tag with latest
[INFO] k8s: Pushing image: YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account:0.0.1-SNAPSHOT
[INFO] k8s: Pushed sha256:def456... : latest
```

**Expected outcome:** All six microservice images built and pushed successfully

**✅ Verification:** Check images exist locally:

```bash
docker images | grep cloudbank-v5
```

You should see 6 images with tag `0.0.1-SNAPSHOT`.

**⚠️ Troubleshooting:**

- **Authentication errors during push:** Re-run `docker login` (Step 1.2)
- **Permission denied:** Ensure repositories are public, or you have push permissions
- **Build fails on checkstyle:** Fix code style issues or temporarily skip: `mvn clean package -Dcheckstyle.skip=true k8s:build k8s:push -pl ...`
- **Out of disk space:** Clean up old images: `docker image prune -a`

---

## Step 4: Configure Database

**What this step does:** Runs a Kubernetes Job that connects to your Autonomous Database and creates two database users (`account` and `customer`) with the necessary permissions for CloudBank microservices.

**Time estimate:** 5-10 minutes

### 4.1 Update SQL Job Configuration

Edit the `sqljob.yaml` file to match your environment.

**Open the file:**

```bash
vi sqljob.yaml  # or use your preferred editor
```

**Key sections to configure:**

#### **1. Namespace (Line 7)**

```yaml
namespace: obaas-dev  # Change if your OBaaS is in a different namespace
```

#### **2. User Passwords (Lines 26-27)**

```sql
-- Change these passwords to your own strong passwords
create user customer identified by "Welcome-12345";
create user account identified by "Welcome-12345";
```

**⚠️ Important:** Use strong passwords that meet Oracle password requirements:
- At least 12 characters
- Contains uppercase, lowercase, numbers
- Contains special characters
- Must start with a letter

**ℹ️ Tip:** Save these passwords - you'll need them in Step 5 for creating Kubernetes secrets.

#### **3. Database Version (Line 25)**

The default SQL statement uses Oracle Database 26ai syntax. If using 19c, you'll need to modify the grant statements.

**For 26ai (default):**
```sql
grant db_developer_role to customer;
grant db_developer_role to account;
```

**For 19c:**
```sql
grant connect, resource to customer;
grant connect, resource to account;
```

#### **4. Database Connection Secrets (Lines 48-70)**

Verify these secret names match your OBaaS installation:

```yaml
env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: obaas-db-secret        # ⚠️ Verify this secret exists
        key: db.username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: obaas-db-secret        # ⚠️ Verify this secret exists
        key: db.password
  - name: TNS_ALIAS
    valueFrom:
      secretKeyRef:
        name: obaas-db-secret        # ⚠️ Verify this secret exists
        key: db.service
volumes:
  - name: db-wallet-volume
    secret:
      secretName: obaas-adb-tns-admin-1  # ⚠️ Verify this wallet secret exists
```

**✅ Verification:** Check secrets exist:

```bash
kubectl get secret obaas-db-secret -n obaas-dev
kubectl get secret obaas-adb-tns-admin-1 -n obaas-dev
```

If these secrets don't exist or have different names, update the `sqljob.yaml` accordingly.

**ℹ️ Tip:** To see all secrets in the namespace:

```bash
kubectl get secrets -n obaas-dev
```

---

### 4.2 Create Database Users

Run the SQL job to create the account and customer database users:

```bash
kubectl create -f sqljob.yaml
```

**Expected outcome:** Job created successfully

```
job.batch/cloudbank-db-setup created
```

---

### 4.3 Verify Job Completion

**⚠️ Important:** Do not proceed to the next step until this job completes successfully. The microservices won't start if database users don't exist.

**Check job status:**

```bash
kubectl get jobs -n obaas-dev --sort-by=.metadata.creationTimestamp
```

Look for a job with "Completions: 1/1". Example:

```
NAME                    COMPLETIONS   DURATION   AGE
cloudbank-db-setup      1/1           23s        1m
```

**Get the job name dynamically:**

```bash
export JOB_NAME=$(kubectl get jobs -n obaas-dev --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
echo $JOB_NAME
```

**Check job logs:**

```bash
kubectl logs job/$JOB_NAME -n obaas-dev
```

**Expected log output:**

```
Connecting to database...
Connected successfully
Creating customer user...
User customer created
Granting permissions to customer...
Grants successful
Creating account user...
User account created
Granting permissions to account...
Granting AQ permissions to account...
Grants successful
Database setup complete
```

**✅ Verification:** Job status shows "Completed" (1/1) and logs show "Database setup complete"

**⚠️ Troubleshooting:**

- **Job stays in Running:** Check logs for connection errors
- **Authentication failed:** Verify `obaas-db-secret` has correct admin credentials
- **Wallet errors:** Verify `obaas-adb-tns-admin-1` secret exists and is valid
- **User already exists:** If re-running, drop users first or modify SQL to use `CREATE USER IF NOT EXISTS` (26ai only)

---

## Step 5: Create Kubernetes Secrets

**What this step does:** Creates Kubernetes secrets containing database credentials for the `account` and `customer` microservices. These secrets will be mounted into the service pods to provide database connectivity.

**Time estimate:** 5 minutes

### 5.1 Update Secret Configuration

Edit the `acc_cust_secrets.sh` script and update the values for your environment.

**Open the file:**

```bash
vi acc_cust_secrets.sh  # or use your preferred editor
```

**Script structure:**

The script creates two secrets: `account-db-secrets` and `customer-db-secrets`.

#### **Account Service Secret (Lines 6-12)**

```bash
kubectl -n obaas-dev create secret generic account-db-secrets \
  --from-literal=db.name=helmtest \            # Database name
  --from-literal=db.username=account \         # User from sqljob.yaml
  --from-literal=db.password=Welcome-12345 \   # Password from sqljob.yaml (CHANGE THIS!)
  --from-literal=db.service=helmtest_tp \      # TNS service name
  --from-literal=db.lb_username=admin \        # Liquibase admin user
  --from-literal=db.lb_password=Welcome-12345  # Admin password (CHANGE THIS!)
```

#### **Customer Service Secret (Lines 13-19)**

```bash
kubectl -n obaas-dev create secret generic customer-db-secrets \
  --from-literal=db.name=helmtest \            # Database name
  --from-literal=db.username=customer \        # User from sqljob.yaml
  --from-literal=db.password=Welcome-12345 \   # Password from sqljob.yaml (CHANGE THIS!)
  --from-literal=db.service=helmtest_tp \      # TNS service name
  --from-literal=db.lb_username=admin \        # Liquibase admin user
  --from-literal=db.lb_password=Welcome-12345  # Admin password (CHANGE THIS!)
```

**Values to update:**

| Field            | Description                                                                   | Where to get it                                       |
|------------------|-------------------------------------------------------------------------------|-------------------------------------------------------|
| `db.name`        | Database name                                                                 | From your ADB instance details                        |
| `db.username`    | Schema user (account or customer)                                             | Created in Step 4 (sqljob.yaml)                       |
| `db.password`    | User password                                                                 | Password you set in Step 4 (sqljob.yaml)              |
| `db.service`     | TNS service name (typically `<db-name>_tp` for TP or `<db-name>_low` for low) | From ADB connection details or tnsnames.ora in wallet |
| `db.lb_username` | Admin user for Liquibase migrations                                           | Typically `admin` (from obaas-db-secret)              |
| `db.lb_password` | Admin password                                                                | From obaas-db-secret                                  |

**ℹ️ Finding database connection details:**

```bash
# Get database name and service from OBaaS secret
kubectl get secret obaas-db-secret -n obaas-dev -o jsonpath='{.data.db\.name}' | base64 -d && echo
kubectl get secret obaas-db-secret -n obaas-dev -o jsonpath='{.data.db\.service}' | base64 -d && echo

# Get admin username
kubectl get secret obaas-db-secret -n obaas-dev -o jsonpath='{.data.db\.username}' | base64 -d && echo
```

**⚠️ Important:** The passwords for `account` and `customer` users MUST match what you set in `sqljob.yaml` (Step 4).

---

### 5.2 Create Secrets

Run the script to create Kubernetes secrets:

```bash
source acc_cust_secrets.sh
```

**Expected outcome:** Two secrets created successfully

```
secret/account-db-secrets created
secret/customer-db-secrets created
```

**✅ Verification:** Check secrets were created:

```bash
kubectl get secrets -n obaas-dev | grep -E 'account|customer'
```

You should see:

```
account-db-secrets    Opaque   7      10s
customer-db-secrets   Opaque   7      10s
```

**Verify secret structure (check keys, not values):**

```bash
kubectl describe secret account-db-secrets -n obaas-dev
kubectl describe secret customer-db-secrets -n obaas-dev
```

You should see 7 data keys:
- `db.name`
- `db.username`
- `db.password`
- `db.service`
- `db.lb_username`
- `db.lb_password`

**⚠️ Troubleshooting:**

- **Secret already exists:** Delete and recreate:
  ```bash
  kubectl delete secret account-db-secrets customer-db-secrets -n obaas-dev
  source acc_cust_secrets.sh
  ```
- **Permission denied:** Ensure you have permissions to create secrets in the namespace

---

## Step 6: Configure Helm Values

**What this step does:** Updates the Helm `values.yaml` files for all six microservices with your container image references and verifies database secret names are correct.

**Time estimate:** 5 minutes

### 6.1 Update Image References

Update all `values.yaml` files with your registry path and image tag.

**What this script does:**
- Finds all `values.yaml` files in `*/helm/` directories
- Extracts the service name from corresponding `Chart.yaml`
- Updates `image.repository` to `REPOSITORY/SERVICE_NAME`
- Updates `image.tag` to the specified tag

**Command:**

```bash
./update-image.sh REPOSITORY TAG
```

**Parameters:**
- `REPOSITORY`: Registry path (same as Step 3.1, without service name)
- `TAG`: Image version tag (typically `0.0.1-SNAPSHOT`)

**Example:**

```bash
./update-image.sh YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5 0.0.1-SNAPSHOT
```

**⚠️ Note:** Replace `YOUR_TENANCY` with your actual OCI tenancy namespace.

**Result:** Each service's `values.yaml` will have:

```yaml
image:
  repository: "YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account"
  tag: "0.0.1-SNAPSHOT"
```

**✅ Verification:** Check images were updated in all values files:

```bash
grep -E "repository:|tag:" */helm/values.yaml
```

You should see all services with your registry path and `0.0.1-SNAPSHOT` tag.

---

### 6.2 Verify Secret Names and Configuration

Open one or more `values.yaml` files and verify the OBaaS configuration section is correct.

**Check account service configuration:**

```bash
vi account/helm/values.yaml
```

**Key sections to verify:**

#### **OBaaS Namespace (Line ~151)**

```yaml
obaas:
  namespace: obaas-dev  # Should match your OBaaS installation namespace
```

#### **Framework (Line ~155)**

```yaml
  framework: SPRING_BOOT  # All CloudBank services use Spring Boot
```

#### **Database Secrets (Lines ~158-162)**

```yaml
  database:
    enabled: true
    credentialsSecret: account-db-secrets      # Created in Step 5
    walletSecret: obaas-adb-tns-admin-1        # ADB wallet from OBaaS
```

**⚠️ Important:** Verify the secret names match what exists in your cluster:

```bash
# Check credential secrets exist
kubectl get secret account-db-secrets -n obaas-dev
kubectl get secret customer-db-secrets -n obaas-dev

# Check wallet secret exists
kubectl get secret obaas-adb-tns-admin-1 -n obaas-dev
```

If your wallet secret has a different name, update all `values.yaml` files accordingly.

**ℹ️ To find all wallet secrets:**

```bash
kubectl get secrets -n obaas-dev | grep -i wallet
```

#### **Service-Specific Database Configuration**

Different services require different database configurations:

| Service         | Database | Credentials Secret    | Notes                           |
|-----------------|----------|-----------------------|---------------------------------|
| **account**     | ✅ Yes    | `account-db-secrets`  | Has own schema, needs LRA       |
| **customer**    | ✅ Yes    | `customer-db-secrets` | Has own schema                  |
| **checks**      | ✅ Yes    | `account-db-secrets`  | Uses account schema for journal |
| **transfer**    | ❌ No     | N/A                   | Stateless, orchestrates LRA     |
| **creditscore** | ❌ No     | N/A                   | Stateless, returns mock data    |
| **testrunner**  | ✅ Yes    | `account-db-secrets`  | Sends messages to AQ queues     |

**Verify checks service uses account credentials:**

```bash
grep -A4 "database:" checks/helm/values.yaml
```

Should show:

```yaml
  database:
    enabled: true
    credentialsSecret: account-db-secrets      # Uses account schema
    walletSecret: obaas-adb-tns-admin-1
```

**Verify transfer and creditscore have database disabled:**

```bash
grep -A4 "database:" transfer/helm/values.yaml
grep -A4 "database:" creditscore/helm/values.yaml
```

Should show:

```yaml
  database:
    enabled: false  # Stateless service
```

**✅ Verification checklist:**
- ✅ All services have correct image repository and tag
- ✅ All services have `obaas.namespace` set to `obaas-dev` (or your namespace)
- ✅ All services have `framework: SPRING_BOOT`
- ✅ Account, customer, checks, testrunner have database enabled with correct secrets
- ✅ Transfer and creditscore have database disabled
- ✅ All wallet secret names match what exists in your cluster

---

## Step 7: Deploy CloudBank Services

**What this step does:** Uses Helm to deploy all six CloudBank microservices to your Kubernetes cluster. Each service is deployed with its configuration from the `values.yaml` files updated in Step 6.

**Time estimate:** 5-10 minutes (deployment takes 2-3 minutes, plus startup time)

### 7.1 Deploy All Services

Deploy all CloudBank microservices using the provided script:

**Command:**

```bash
./deploy-all-services.sh obaas-dev
```

**What this script does:**
- Deploys services in sequence: account → customer → transfer → checks → creditscore → testrunner
- Uses `helm upgrade --install` (installs if new, upgrades if exists)
- Each deployment uses the service name as the Helm release name
- Uses `--wait` flag to wait for pods to be ready before continuing
- Uses `--debug` flag for verbose output
- Exits immediately if any deployment fails

**Time warning:** The deployment process takes 2-3 minutes. Each service will:
1. Create Kubernetes Deployment
2. Create Kubernetes Service (ClusterIP)
3. Create ConfigMap with application configuration
4. Pull container image from registry
5. Start pod and wait for health probes

**Expected output (per service):**

```
Installing account...
Release "account" does not exist. Installing it now.
NAME: account
LAST DEPLOYED: Mon Nov 18 10:00:00 2025
NAMESPACE: obaas-dev
STATUS: deployed
REVISION: 1
```

---

### 7.2 Monitor Deployment

In a separate terminal, watch pod startup progress:

```bash
kubectl get pods -n obaas-dev -w | grep cloudbank
```

**Pod startup stages:**

1. **Pending** - Pod created, waiting to be scheduled
2. **ContainerCreating** - Image being pulled
3. **Running (0/1)** - Container started, waiting for health probes
4. **Running (1/1)** - Health probes passing, pod ready ✅

**Example output:**

```
account-0        0/1     ContainerCreating   0          10s
account-0        0/1     Running             0          30s
account-0        1/1     Running             0          45s
customer-0       0/1     ContainerCreating   0          5s
customer-0       1/1     Running             0          35s
```

**⚠️ Note:** It's normal for pods to show "0/1" for 30-60 seconds while:
- Spring Boot application starts
- Database connections initialize
- Liquibase migrations run (account and customer services)
- Eureka registration completes
- Health probes pass

---

### 7.3 Verify Deployment

Once deployment completes, verify all services are running:

```bash
kubectl get pods -n obaas-dev | grep cloudbank
```

**Expected outcome:** All six microservices show "Running" status with "1/1" ready

```
NAME                           READY   STATUS    RESTARTS   AGE
cloudbank-account-0            1/1     Running   0          5m
cloudbank-customer-0           1/1     Running   0          4m
cloudbank-transfer-0           1/1     Running   0          3m
cloudbank-checks-0             1/1     Running   0          2m
cloudbank-creditscore-0        1/1     Running   0          1m
cloudbank-testrunner-0         1/1     Running   0          30s
```

**Check service endpoints:**

```bash
kubectl get svc -n obaas-dev | grep cloudbank
```

**Expected outcome:** All services have ClusterIP endpoints

```
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
cloudbank-account      ClusterIP   10.96.100.1      <none>        8080/TCP   5m
cloudbank-customer     ClusterIP   10.96.100.2      <none>        8080/TCP   4m
cloudbank-transfer     ClusterIP   10.96.100.3      <none>        8080/TCP   3m
cloudbank-checks       ClusterIP   10.96.100.4      <none>        8080/TCP   2m
cloudbank-creditscore  ClusterIP   10.96.100.5      <none>        8080/TCP   1m
cloudbank-testrunner   ClusterIP   10.96.100.6      <none>        8080/TCP   30s
```

**✅ Verification:** All 6 pods are Running (1/1) and all 6 services exist

---

### 7.4 Troubleshooting Deployment Issues

**If a pod shows "ImagePullBackOff":**

```bash
# Check image name is correct
kubectl describe pod POD_NAME -n obaas-dev | grep -A5 "Events:"

# Verify image exists in registry
docker pull YOUR_REGION.ocir.io/YOUR_TENANCY/cloudbank-v5/account:0.0.1-SNAPSHOT
```

**Solutions:**
- Verify images were pushed successfully in Step 3.2
- Ensure registry repositories are public
- Check image names in values.yaml match pushed images

**If a pod shows "CrashLoopBackOff":**

```bash
# Check pod logs for errors
kubectl logs POD_NAME -n obaas-dev

# Check previous instance logs if pod is restarting
kubectl logs POD_NAME -n obaas-dev --previous
```

**Common issues:**
- Database connection failures - Check secrets (Step 5)
- Wallet not found - Check wallet secret name in values.yaml
- Liquibase migration errors - Check admin credentials in secrets
- Eureka connection refused - Verify Eureka is running in OBaaS

**If a pod stays in "Running" but not "Ready" (0/1):**

```bash
# Check health probe status
kubectl describe pod POD_NAME -n obaas-dev | grep -A10 "Conditions:"

# Check application logs
kubectl logs POD_NAME -n obaas-dev | tail -50
```

**Solutions:**
- Wait longer (account/customer take 60-90 seconds due to Liquibase)
- Check health endpoints are responding
- Verify database connectivity

**To redeploy a single service:**

```bash
# Delete the Helm release
helm uninstall SERVICE_NAME -n obaas-dev

# Redeploy
helm install SERVICE_NAME ./SERVICE_NAME/helm -n obaas-dev
```

---

## Step 8: Configure APISIX Routes

**What this step does:** Creates API Gateway routes in APISIX to expose CloudBank microservices externally. Routes use Eureka service discovery to find service instances.

**Time estimate:** 5 minutes

### 8.1 Retrieve APISIX Admin API Key

Get the APISIX admin API key and save it to a variable for easy use.

**Option 1 - Using yq (recommended):**

```bash
export APISIX_KEY=$(kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key')

# Verify the key was extracted
echo $APISIX_KEY
```

**Expected output:** A long alphanumeric string (e.g., `edd1c9f034335f136f87ad84b625c8f1`)

**Option 2 - Manual retrieval:**

If the yq command doesn't work:

1. Get the configmap:
   ```bash
   kubectl get configmap apisix -n obaas-dev -o yaml > apisix-config.yaml
   ```

2. Open `apisix-config.yaml` and find the `config.yaml` section

3. Look for `deployment.admin.admin_key` and copy the key value:
   ```yaml
   admin_key:
     - name: admin
       key: edd1c9f034335f136f87ad84b625c8f1  # Copy this value
   ```

4. Set the variable:
   ```bash
   export APISIX_KEY=edd1c9f034335f136f87ad84b625c8f1
   ```

**✅ Verification:** Variable is set and not empty

```bash
echo "API Key: $APISIX_KEY"
```

---

### 8.2 Create Port Forward to APISIX

Open a **new terminal (Terminal 2)** and create a tunnel to the APISIX admin API:

**In Terminal 2:**

```bash
kubectl port-forward -n obaas-dev svc/apisix-admin 9180
```

**Expected output:**

```
Forwarding from 127.0.0.1:9180 -> 9180
Forwarding from [::1]:9180 -> 9180
```

**⚠️ Important:** Keep this terminal open during route creation. Do not close or interrupt the port-forward.

**ℹ️ Verify port-forward is working:**

In your original terminal (Terminal 1), test the connection:

```bash
curl -s http://localhost:9180/apisix/admin/routes -H "X-API-KEY: $APISIX_KEY" | head -20
```

You should get a JSON response (not a connection error).

---

### 8.3 Create Routes

Return to your original terminal (Terminal 1) and create all APISIX routes.

**What routes will be created:**

The script creates routes for all six microservices:

| Route ID  | Service     | URI Pattern            | Upstream                        |
|-----------|-------------|------------------------|---------------------------------|
| 1000      | account     | `/api/v1/account*`     | ACCOUNT (via Eureka)            |
| 1001-1004 | customer    | `/api/v1/customer*`    | CUSTOMER (via Eureka)           |
| 1001-1004 | creditscore | `/api/v1/creditscore*` | CREDITSCORE (via Eureka)        |
| 1001-1004 | testrunner  | `/api/v1/testrunner*`  | TESTRUNNER (via Eureka)         |
| 1005      | transfer    | `/transfer*`           | TRANSFER (via Eureka)           |
| (auto)    | checks      | N/A                    | Background processor, no routes |

**Route features:**
- Uses Eureka service discovery (`discovery_type: "eureka"`)
- Supports all HTTP methods (GET, POST, PUT, DELETE, OPTIONS, HEAD)
- OpenTelemetry tracing enabled (always_on sampling)
- Prometheus metrics enabled
- Round-robin load balancing

**In Terminal 1:**

```bash
cd apisix-routes
source ./create-all-routes.sh $APISIX_KEY
cd ..
```

**Expected output:**

```
Creating route for account service...
{"action":"set","node":{"key":"\/apisix\/routes\/1000",...}}

Creating route for customer service...
{"action":"set","node":{"key":"\/apisix\/routes\/1001",...}}

Creating route for transfer service...
{"action":"set","node":{"key":"\/apisix\/routes\/1005",...}}

Creating route for creditscore service...
Creating route for testrunner service...

All routes created successfully!
```

**✅ Verification:** List all created routes

```bash
curl -s http://localhost:9180/apisix/admin/routes -H "X-API-KEY: $APISIX_KEY" | jq '.list.nodes[] | {id: .key, uri: .value.uri, name: .value.name}'
```

You should see 5-6 routes with URIs matching the table above.

**You can now close the port-forward in Terminal 2** (Ctrl+C).

---

## Step 9: Test the Installation

**What this step does:** Verifies all CloudBank microservices are running correctly and responding to requests through the APISIX API Gateway.

**Time estimate:** 10-15 minutes

### 9.1 Get APISIX Gateway Address

Find the external IP or ingress point for the APISIX gateway.

**If using LoadBalancer service:**

```bash
kubectl get svc -n obaas-dev apisix-gateway
```

**Expected output:**

```
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
apisix-gateway   LoadBalancer   10.96.50.100    203.0.113.42     80:30080/TCP   5d
```

Set the IP as a variable:

```bash
export IP=EXTERNAL_IP  # e.g., export IP=203.0.113.42
```

**If using Ingress or NodePort:**

Consult your OBaaS documentation for the appropriate endpoint.

**If testing locally (no external IP):**

Port-forward to APISIX gateway:

```bash
kubectl port-forward -n obaas-dev svc/apisix-gateway 8080:80
export IP=localhost:8080
```

---

### 9.2 Basic Health Checks

Verify all pods are healthy and registered with Eureka.

**Check all pods are running:**

```bash
kubectl get pods -n obaas-dev | grep cloudbank
```

**Expected:** All 6 pods show "1/1 Running"

**Check service endpoints:**

```bash
kubectl get svc -n obaas-dev | grep cloudbank
```

**Expected:** All 6 services have ClusterIP addresses

**Check Eureka registration:**

Port-forward to Eureka (if not already):

```bash
kubectl port-forward -n obaas-dev svc/eureka 8761
```

Open browser to http://localhost:8761 and verify all 6 services are registered.

---

### 9.3 Test Account Service

**Test GET all accounts:**

```bash
curl -s http://$IP/api/v1/account | jq
```

**Expected response:** JSON array of accounts

```json
[
  {
    "accountId": 1,
    "accountName": "Andy's checking",
    "accountType": "CH",
    "accountCustomerId": "testuser",
    "accountOpenedDate": "2023-01-01T00:00:00",
    "accountOtherDetails": "Account Info",
    "accountBalance": 1040
  },
  {
    "accountId": 2,
    "accountName": "Mark's CCard",
    "accountType": "CC",
    ...
  }
]
```

**Test GET specific account:**

```bash
curl -s http://$IP/api/v1/account/1 | jq
```

**Expected:** Single account object with accountId=1

**✅ Verification:** Account service is responding and returning data

---

### 9.4 Test Customer Service

**Test GET all customers:**

```bash
curl -s http://$IP/api/v1/customer | jq
```

**Expected response:** JSON array of customers

```json
[
  {
    "customerId": "testuser",
    "customerName": "Test User",
    "customerEmail": "test@example.com",
    "customerOtherDetails": "Customer details",
    "customerPassword": null
  }
]
```

**Test POST create new customer:**

```bash
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"customerId": "bobsmith", "customerName": "Bob Smith", "customerEmail": "bob@smith.com", "customerOtherDetails": "New customer"}' \
  http://$IP/api/v1/customer
```

**Expected response:** HTTP 201 Created

**Verify customer was created:**

```bash
curl -s http://$IP/api/v1/customer | jq '.[] | select(.customerId == "bobsmith")'
```

**✅ Verification:** Customer service is responding and can create/read customers

---

### 9.5 Test Credit Score Service

**Test GET credit score:**

```bash
curl -s http://$IP/api/v1/creditscore | jq
```

**Expected response:** JSON with date and credit score (random)

```json
{
  "Date": "Mon Nov 18 10:30:00 PST 2025",
  "Credit Score": "750"
}
```

**✅ Verification:** Credit score service is responding

---

### 9.6 Test Check Deposit and Clearance (Event-Driven)

This test demonstrates the event-driven architecture using Oracle AQ.

**1. Check initial account balance:**

```bash
curl -s http://$IP/api/v1/account/1 | jq '.accountBalance'
```

**Note the initial balance** (e.g., 1040)

**2. Deposit a check (sends message to AQ queue):**

```bash
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"accountId": 1, "amount": 256}' \
  http://$IP/api/v1/testrunner/deposit
```

**Expected:** HTTP 200 OK

**3. Watch checks service process the message:**

```bash
kubectl logs -n obaas-dev svc/cloudbank-checks --tail=20
```

**Expected log output:**

```
Received check deposit message: accountId=1, amount=256
Creating journal entry with type=PENDING
Journal entry created with ID=JOURNAL_ID
```

**4. View journal entries:**

```bash
curl -s http://$IP/api/v1/account/1/journal | jq
```

**Expected:** New PENDING entry with amount=256

**5. Clear the check (sends clearance message):**

First, get the journal ID from the previous response, then:

```bash
curl -i -X POST -H 'Content-Type: application/json' \
  -d '{"journalId": JOURNAL_ID}' \
  http://$IP/api/v1/testrunner/clear
```

**6. Verify journal updated to DEPOSIT:**

```bash
curl -s http://$IP/api/v1/account/1/journal | jq '.[] | select(.journalId == JOURNAL_ID)'
```

**Expected:** journalType changed from "PENDING" to "DEPOSIT"

**7. Verify account balance increased:**

```bash
curl -s http://$IP/api/v1/account/1 | jq '.accountBalance'
```

**Expected:** Balance = initial balance + 256

**✅ Verification:** Check deposit/clearance workflow is working (testrunner → AQ → checks → account)

---

### 9.7 Test Transfer Service (LRA Saga Pattern)

This test demonstrates distributed transactions using Long Running Actions.

**1. Check initial balances:**

```bash
echo "Account 1 balance:"
curl -s http://$IP/api/v1/account/1 | jq '.accountBalance'

echo "Account 2 balance:"
curl -s http://$IP/api/v1/account/2 | jq '.accountBalance'
```

**Note both balances** (e.g., Account 1 = 1296, Account 2 = 5000)

**2. Perform transfer (Account 2 → Account 1):**

```bash
curl -i -X POST "http://$IP/transfer?fromAccount=2&toAccount=1&amount=100"
```

**Expected:** HTTP 200 OK with "Transfer completed successfully"

**3. Verify balances updated:**

```bash
echo "Account 1 balance (should increase by 100):"
curl -s http://$IP/api/v1/account/1 | jq '.accountBalance'

echo "Account 2 balance (should decrease by 100):"
curl -s http://$IP/api/v1/account/2 | jq '.accountBalance'
```

**Expected:**
- Account 1: initial + 100
- Account 2: initial - 100

**4. Check transfer service logs for LRA activity:**

```bash
kubectl logs -n obaas-dev svc/cloudbank-transfer --tail=30
```

**Expected log output:**

```
Starting LRA transaction: lra-id=http://...
Withdrawing 100 from account 2
Depositing 100 to account 1
LRA transaction completed successfully
```

**5. Test LRA rollback (insufficient funds):**

```bash
curl -i -X POST "http://$IP/transfer?fromAccount=2&toAccount=1&amount=999999"
```

**Expected:** HTTP 400 or 500 with error message

**Check logs:**

```bash
kubectl logs -n obaas-dev svc/cloudbank-transfer --tail=30
```

**Expected:** LRA compensating transaction executed, no balance changes

**✅ Verification:** Transfer service LRA saga pattern is working correctly

---

### 9.8 Access Swagger UI

Each microservice has a Swagger UI for API documentation and testing.

**Port-forward to a service:**

```bash
kubectl port-forward -n obaas-dev svc/cloudbank-account 8080
```

**Open browser:**

http://localhost:8080/swagger-ui/index.html

**Repeat for other services** by changing the service name and port.

---

### 9.9 Full Testing

For comprehensive testing procedures, see the [README](README.md) "Test CloudBank Services" section (lines 96-465).

**✅ Installation Complete!** All services are running and tested successfully.

---

## Post-Installation

### Access Observability Dashboards

#### Eureka Service Discovery

View registered services:

```bash
kubectl port-forward -n obaas-dev svc/eureka 8761
```

Open browser: http://localhost:8761

**Expected:** All 6 CloudBank services registered

---

#### Spring Boot Admin

Monitor service health, metrics, and logs:

```bash
kubectl port-forward -n obaas-dev svc/admin-server 8989
```

Open browser: http://localhost:8989

---

#### SigNoz (Tracing & Logs)

View distributed traces and logs:

```bash
kubectl port-forward -n obaas-dev svc/obaas-signoz-frontend 3301:3301
```

Open browser: http://localhost:3301

**Get credentials:**

```bash
echo "Email: $(kubectl get secret signoz-authn -n obaas-dev -o jsonpath='{.data.email}' | base64 -d)"
echo "Password: $(kubectl get secret signoz-authn -n obaas-dev -o jsonpath='{.data.password}' | base64 -d)"
```

---

### View Service Logs

**View logs for a specific service:**

```bash
kubectl logs -n obaas-dev svc/cloudbank-account
```

**Follow logs in real-time:**

```bash
kubectl logs -n obaas-dev svc/cloudbank-account -f
```

**View logs from all CloudBank services:**

```bash
kubectl logs -n obaas-dev -l app.kubernetes.io/name=cloudbank --tail=50
```

---

### Next Steps

- **Modify services:** Make code changes and redeploy using `mvn clean package k8s:build k8s:push` and `helm upgrade`
- **Scale services:** Modify `replicaCount` in values.yaml
- **Configure autoscaling:** Enable HPA in values.yaml
- **Add monitoring:** Configure Prometheus and Grafana dashboards
- **CI/CD integration:** Set up automated builds and deployments

---

## Troubleshooting

### Build Failures

**Problem:** Maven build fails with dependency errors

**Solution:** Ensure you've run `mvn clean install -pl common,buildtools` first (Step 2)

**Problem:** Checkstyle violations fail the build

**Solution:** Fix code style issues or temporarily skip:
```bash
mvn clean package -Dcheckstyle.skip=true
```

---

### Docker Connection Issues

**Problem:** Cannot connect to Docker daemon

**Solutions:**
- Verify DOCKER_HOST is set correctly
- Ensure Docker Desktop or Rancher Desktop is running
- Check Docker is accessible: `docker ps`
- Try restarting Docker/Rancher Desktop

---

### Script Permission Issues

**Problem:** `./script.sh: Permission denied`

**Solution:** Make scripts executable:
```bash
chmod +x *.sh
chmod +x apisix-routes/*.sh
```

---

### Script Not Found

**Problem:** `./script.sh: No such file or directory`

**Solution:** Ensure you're in the project root directory:
```bash
pwd  # Should show .../cloudbank-v5
ls -la *.sh  # Should list all shell scripts
```

---

### Database Connection Failures

**Problem:** Services crash with database connection errors

**Solutions:**
- Verify secrets exist and have correct names (Step 5.2)
- Check secret values match database users created in Step 4
- Verify wallet secret exists: `kubectl get secret obaas-adb-tns-admin-1 -n obaas-dev`
- Check database users were created: Review sqljob logs (Step 4.3)
- Verify TNS service name is correct in secrets

**Check database connectivity from a pod:**
```bash
kubectl exec -it POD_NAME -n obaas-dev -- sh
# Inside pod:
env | grep -i db
ls -la /db-secrets/
```

---

### Job Not Completing

**Problem:** SQL job (Step 4) stays in "Running" state

**Solutions:**
- Check logs: `kubectl logs job/JOB_NAME -n obaas-dev`
- Verify admin secret exists and has correct credentials
- Verify wallet secret exists
- Check database is accessible from cluster
- If job failed, delete and recreate: `kubectl delete job JOB_NAME -n obaas-dev`

---

### Secret Mounting Issues

**Problem:** Pods can't read secrets

**Solutions:**
- Verify secret names in values.yaml match actual secrets: `kubectl get secrets -n obaas-dev`
- Check secret has correct keys: `kubectl describe secret SECRET_NAME -n obaas-dev`
- Verify namespace matches: Secrets must be in same namespace as pods

---

### Pods Not Starting

**Problem:** Pods show "ImagePullBackOff" error

**Solutions:**
- Verify images were pushed successfully (Step 3.2): `docker images | grep cloudbank-v5`
- Ensure registry repositories are public
- Check image names in values.yaml match pushed images
- Verify image exists in registry manually: `docker pull IMAGE_NAME`
- Re-authenticate with registry: `docker login`

**Problem:** Pods show "CrashLoopBackOff"

**Solutions:**
- Check pod logs: `kubectl logs POD_NAME -n obaas-dev`
- Check previous logs: `kubectl logs POD_NAME -n obaas-dev --previous`
- Common causes: Database connection failures, missing secrets, wallet issues
- Check health probe configuration in values.yaml

**Problem:** Pods stay "Running" but not "Ready" (0/1)

**Solutions:**
- Wait longer (account/customer take 60-90 seconds for Liquibase migrations)
- Check logs for startup errors
- Verify health probe endpoints are configured correctly
- Check Eureka connectivity

---

### Service Discovery Issues

**Problem:** Services can't find each other

**Solutions:**
- Verify Eureka is running: `kubectl get pods -n obaas-dev | grep eureka`
- Check services registered in Eureka: Port-forward to 8761 and view dashboard
- Verify `eureka.enabled: true` in all values.yaml files
- Check pod logs for Eureka registration errors

---

### Wallet Issues

**Problem:** Services can't access database wallet

**Solutions:**
- Verify wallet secret exists: `kubectl get secret -n obaas-dev | grep wallet`
- Check wallet secret name matches values.yaml
- Verify wallet files are in secret: `kubectl get secret <wallet-secret> -n obaas-dev -o yaml`
- Ensure wallet is valid and not expired

---

### APISIX Route Creation Fails

**Problem:** Route creation returns authentication error

**Solutions:**
- Verify you're using the correct admin API key (Step 8.1)
- Ensure port-forward to apisix-admin is running (Step 8.2)
- Check APISIX admin service is running: `kubectl get svc apisix-admin -n obaas-dev`

**Problem:** Routes don't forward traffic

**Solutions:**
- Verify services are registered in Eureka
- Check route configuration: `curl http://localhost:9180/apisix/admin/routes -H "X-API-KEY: $APISIX_KEY"`
- Verify APISIX gateway has external IP/ingress

---

### Network/DNS Issues

**Problem:** Services can't reach each other or external services

**Solutions:**
- Check cluster networking is healthy
- Verify DNS is working: `kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default`
- Check service endpoints exist: `kubectl get endpoints -n obaas-dev | grep cloudbank`

---

### Image Pull Authentication

**Problem:** Private registry authentication fails

**Solutions:**
- **Recommended:** Use public repositories (private repos have known issues)
- If using private repos, create imagePullSecrets:
  ```bash
  kubectl create secret docker-registry ocir \
    --docker-server=YOUR_REGION.ocir.io \
    --docker-username='YOUR_TENANCY/USERNAME' \
    --docker-password='AUTH_TOKEN' \
    -n obaas-dev
  ```
- Update values.yaml:
  ```yaml
  imagePullSecrets:
    - name: ocir
  ```
- Redeploy services

---

## Cleanup/Rollback

### Uninstall All Services

Remove all CloudBank microservices:

```bash
helm uninstall account customer transfer checks creditscore testrunner -n obaas-dev
```

**Verify removal:**

```bash
kubectl get pods -n obaas-dev | grep cloudbank
# Should return no results
```

---

### Delete Secrets

Remove CloudBank secrets:

```bash
kubectl delete secret account-db-secrets customer-db-secrets -n obaas-dev
```

---

### Delete Database Users

To remove the database users created in Step 4, create a cleanup job:

**Create `cleanup-job.yaml`:**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: cloudbank-db-cleanup
  namespace: obaas-dev
spec:
  template:
    spec:
      containers:
      - name: sqlcl
        image: ghcr.io/oracle/sqlcl:latest
        command: ["/bin/bash", "-c"]
        args:
          - |
            echo "DROP USER account CASCADE;" | sql -L $DB_USER/$DB_PASSWORD@$TNS_ALIAS
            echo "DROP USER customer CASCADE;" | sql -L $DB_USER/$DB_PASSWORD@$TNS_ALIAS
        env:
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: obaas-db-secret
                key: db.username
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: obaas-db-secret
                key: db.password
          - name: TNS_ALIAS
            valueFrom:
              secretKeyRef:
                name: obaas-db-secret
                key: db.service
        volumeMounts:
          - name: db-wallet
            mountPath: /db-wallet
      volumes:
        - name: db-wallet
          secret:
            secretName: obaas-adb-tns-admin-1
      restartPolicy: Never
  backoffLimit: 3
```

**Run cleanup:**

```bash
kubectl create -f cleanup-job.yaml
kubectl logs job/cloudbank-db-cleanup -n obaas-dev
kubectl delete job cloudbank-db-cleanup -n obaas-dev
```

---

### Delete APISIX Routes

Remove all CloudBank routes:

```bash
# Port-forward to APISIX admin
kubectl port-forward -n obaas-dev svc/apisix-admin 9180

# Get API key
export APISIX_KEY=$(kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key')

# Delete routes (adjust route IDs as needed)
curl -X DELETE "http://localhost:9180/apisix/admin/routes/1000" -H "X-API-KEY: $APISIX_KEY"
curl -X DELETE "http://localhost:9180/apisix/admin/routes/1001" -H "X-API-KEY: $APISIX_KEY"
curl -X DELETE "http://localhost:9180/apisix/admin/routes/1005" -H "X-API-KEY: $APISIX_KEY"
# Continue for all route IDs...
```

---

### Delete Container Images

Remove images from local Docker:

```bash
docker rmi $(docker images | grep cloudbank-v5 | awk '{print $3}')
```

**⚠️ Note:** This doesn't delete images from the remote registry. To delete from OCI Registry, use the OCI Console or CLI.

---

### Starting Over

If you need to completely start over:

1. Uninstall all services (see above)
2. Delete all secrets (see above)
3. Delete database users (see above)
4. Delete APISIX routes (see above)
5. Delete local images (see above)
6. Return to Step 1 and begin again

---

## Additional Resources

- **[CloudBank README](README.md)** - Application overview and detailed testing guide
- **[Oracle Backend as a Service documentation](https://oracle.github.io/microservices-datadriven/obaas/)** - OBaaS platform documentation
- **[Report Issues](https://github.com/oracle/microservices-datadriven/issues)** - GitHub Issues for this repository
- **[Spring Boot Documentation](https://spring.io/projects/spring-boot)** - Spring Boot reference
- **[Eclipse JKube](https://www.eclipse.org/jkube/)** - Kubernetes/OpenShift Maven plugin
- **[Oracle MicroTx](https://docs.oracle.com/en/database/oracle/transaction-manager-for-microservices/)** - LRA coordinator documentation

---

## Notes

- This installation assumes both OBaaS and CloudBank v5 are deployed in the `obaas-dev` namespace
- CloudBank v5 has only been tested with Java 21
- Private container registries are currently not supported due to authentication issues
- All microservices use Spring Boot 3.4.6 with Spring Cloud 2024.0.1
- Database migrations for account and customer services are managed by Liquibase
- Distributed transactions use Oracle MicroTx LRA (Long Running Actions) pattern
- Event-driven workflows use Oracle Advanced Queuing (AQ) with JMS

---

**End of Installation Guide**
