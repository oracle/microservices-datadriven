# CloudBank v5 Installation Guide

## Overview

This guide walks you through installing CloudBank v5, a microservices-based banking application, into an existing Oracle Backend as a Service (OBaaS) environment. CloudBank v5 consists of six microservices: account, customer, transfer, checks, creditscore, and testrunner.

**Estimated time:** 30-45 minutes

---

## Prerequisites

Before you begin, ensure you have:

- Oracle Backend as a Service (OBaaS) installed in namespace `obaas-dev`
- Java 21 installed
- Maven installed
- kubectl configured and connected to your cluster
- Docker or compatible container runtime (Rancher Desktop, Docker Desktop, etc.)
- `yq` command-line tool installed. On ubuntu it must be the `go` version and not the Python based.
- Access to a container registry (OCI Registry or Docker Hub)
- **Note:** Container registry repositories must be public (private repositories are currently not supported due to authentication issues)

---

## Step 1: Configure Your Environment

### 1.1 Set Docker Host

Configure the DOCKER_HOST variable for your container runtime.

**For Rancher Desktop on macOS:**

```bash
export DOCKER_HOST=unix:///Users/<your-username>/.rd/docker.sock
```

**For Docker Desktop:**

```bash
export DOCKER_HOST=unix:///var/run/docker.sock
```

### 1.2 Create Container Registry Repositories

Run the provided script to create necessary repositories in OCI Registry:

```bash
source create-oci-repos.sh <username> <registry-path>
```

**Example:**

```bash
source create-oci-repos.sh andytael sjc.ocir.io/maacloud/cloudbank
```

**Expected outcome:** Six repositories created for each microservice

---

## Step 2: Build Dependencies

Build and install the common dependencies:

```bash
mvn clean install -pl common,buildtools
```

**Expected outcome:** Build completes with `BUILD SUCCESS` message

---

## Step 3: Build CloudBank Microservices

### 3.1 Update Image Repository Configuration

Update the JKube configuration to point to your container registry:

```bash
./update-jkube-image.sh <your-registry-path>
```

**Example:**

```bash
./update-jkube-image.sh sjc.ocir.io/maacloud/cloudbank-v5
```

### 3.2 Build and Push Images

Build all microservices and push to your container registry:

```bash
mvn clean package k8s:build k8s:push -pl account,customer,transfer,checks,creditscore,testrunner
```

**Expected outcome:** All six microservice images built and pushed successfully

---

## Step 4: Configure Database

### 4.1 Update SQL Job Configuration

Edit the `sqljob.yaml` file and update these values for your environment:

- Database connection details
- Admin credentials
- Namespace (if different from `obaas-dev`)

### 4.2 Create Database Users

Run the SQL job to create the account and customer database users:

```bash
kubectl create -f sqljob.yaml
```

### 4.3 Verify Job Completion

**Important:** Verify the job completed successfully before proceeding:

```bash
kubectl get jobs -n obaas-dev
kubectl logs job/<job-name> -n obaas-dev
```

**Expected outcome:** Job status shows "Completed" and logs show successful user creation

---

## Step 5: Create Kubernetes Secrets

### 5.1 Update Secret Configuration

Edit the `acc_cust_secrets.sh` script and update these values:

- Database passwords
- Connection strings
- Wallet paths

### 5.2 Create Secrets

Run the script to create Kubernetes secrets:

```bash
source acc_cust_secrets.sh
```

**Expected outcome:** Secrets created in `obaas-dev` namespace

---

## Step 6: Configure Helm Values

### 6.1 Update Image References

Update the `values.yaml` file with your registry and tag:

```bash
./update-image.sh <repository> <tag>
```

**Example:**

```bash
./update-image.sh sjc.ocir.io/maacloud/cloudbank-v5 0.0.1-SNAPSHOT
```

### 6.2 Verify Secret Names

Open `values.yaml` and verify these values match your environment:

- `credentialSecret`: Database credential secret name
- `walletSecret`: Database wallet secret name

To find the correct secret names:

```bash
kubectl get secrets -n obaas-dev
```

---

## Step 7: Deploy CloudBank Services

Deploy all CloudBank microservices:

```bash
./deploy-all-services.sh obaas-dev
```

**Verify deployment:**

```bash
kubectl get pods -n obaas-dev | grep cloudbank
```

**Expected outcome:** All six microservices show "Running" status

---

## Step 8: Configure APISIX Routes

### 8.1 Retrieve APISIX Admin API Key

**Option 1 - Using yq:**

```bash
kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key'
```

**Option 2 - Manual retrieval:**

If the command above doesn't work:

1. Run: `kubectl get configmap apisix -n obaas-dev -o yaml`
2. Look for the `config.yaml` section
3. Find `deployment.admin.admin_key` and copy the key value

### 8.2 Create Port Forward to APISIX

Open a new terminal and create a tunnel to APISIX:

```bash
kubectl port-forward -n obaas-dev svc/apisix-admin 9180
```

**Keep this terminal open during route creation.**

### 8.3 Create Routes

In your original terminal, create the APISIX routes:

```bash
cd apisix-routes
source ./create-all-routes.sh <YOUR-API-KEY>
cd ..
```

**Expected outcome:** Routes created successfully for all microservices

---

## Step 9: Test the Installation

Follow the testing instructions in the [README](README.md) under the "Test CloudBank Services" section.

**Basic health check:**

```bash
# Check all pods are running
kubectl get pods -n obaas-dev

# Check service endpoints
kubectl get svc -n obaas-dev | grep cloudbank
```

---

## Troubleshooting

### Build Failures

**Problem:** Maven build fails with dependency errors

**Solution:** Ensure you've run `mvn clean install -pl common,buildtools` first

### Docker Connection Issues

**Problem:** Cannot connect to Docker daemon

**Solution:** Verify DOCKER_HOST is set correctly and Docker/Rancher is running

### Job Not Completing

**Problem:** SQL job stays in "Running" state

**Solution:** Check logs with `kubectl logs job/<job-name> -n obaas-dev` to identify database connection issues

### Pods Not Starting

**Problem:** Pods show "ImagePullBackOff" error

**Solution:** 

- Verify images were pushed successfully to registry
- Ensure registry is public or credentials are configured
- Check image names in `values.yaml` match pushed images

### APISIX Route Creation Fails

**Problem:** Route creation returns authentication error

**Solution:** Verify you're using the correct admin API key from the configmap

---

## Additional Resources

- [CloudBank README](README.md) - Application overview and testing guide
- [Oracle Backend as a Service documentation](https://oracle.github.io/microservices-datadriven/obaas/)
- [Report Issues](https://github.com/oracle/microservices-datadriven/issues) - GitHub Issues for this repository

---

## Notes

- This installation assumes both OBaaS and CloudBank v5 are deployed in the `obaas-dev` namespace
- CloudBank v5 has only been tested with Java 21
- Private container registries are currently not supported due to authentication issues