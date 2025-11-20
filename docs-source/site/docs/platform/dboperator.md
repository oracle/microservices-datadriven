---
title: Oracle Database Operator for Kubernetes
sidebar_position: 6
---
## Oracle Database Operator for Kubernetes

The Oracle Database Operator for Kubernetes (_OraOperator_, or simply the _operator_) extends the Kubernetes API with custom resources and controllers to automate Oracle Database lifecycle management.

[Full Documentation](https://github.com/oracle/oracle-database-operator).

Learn about using the OraOperator in the Livelab [Microservices and Kubernetes for an Oracle DBA](https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/view-workshop?wid=3734)

---

## Table of Contents

- [Prerequisites and Assumptions](#prerequisites-and-assumptions)
- [Installing the Oracle Database Operator for Kubernetes](#installing-the-oracle-database-operator-for-kubernetes)
- [Testing the Oracle Database Operator](#testing-the-oracle-database-operator)
  - [Verify the operator is running](#verify-the-operator-is-running)
  - [Verify CRDs are installed](#verify-crds-are-installed)
  - [Validate a sample resource](#validate-a-sample-resource)
  - [Create and test a database instance](#create-and-test-a-database-instance)
  - [Test database connectivity](#test-database-connectivity)
  - [Clean up test resources](#clean-up-test-resources)
- [Monitoring the Oracle Database Operator](#monitoring-the-oracle-database-operator)
  - [Check operator logs](#check-operator-logs)
  - [Monitor database resource status](#monitor-database-resource-status)
- [Troubleshooting](#troubleshooting)
  - [Operator pod issues](#operator-pod-issues)
  - [Database provisioning failures](#database-provisioning-failures)
  - [Storage issues](#storage-issues)
  - [Database connectivity issues](#database-connectivity-issues)
  - [Common error messages](#common-error-messages)
  - [Debugging tips](#debugging-tips)

---

### Prerequisites and Assumptions

This guide makes the following assumptions:

- **Kubectl Access**: You have kubectl configured and authenticated to your Kubernetes cluster with appropriate permissions to:
  - View operator pods and CRDs
  - Create and manage database custom resources
  - View logs from the oracle-database-operator-system namespace
- **Command-line Tools**: The following tools are installed and available:
  - `kubectl` - Kubernetes command-line tool
- **File References**: Examples reference YAML files that you can create for testing purposes.

:::note Namespace Configuration
All `kubectl` commands in this guide use `-n oracle-database-operator-system` as the default namespace. If the Oracle Database Operator is installed in a different namespace, replace `oracle-database-operator-system` with your actual namespace name in all commands.

To find your namespace, run:
```bash
kubectl get pods -A | grep oracle-database-operator
```
:::

### Installing the Oracle Database Operator for Kubernetes

Oracle Database Operator for Kubernetes will be installed if the `oracle-database-operator.enabled` is set to `true` in the `values.yaml` file. The default namespace for Oracle Database Operator is `oracle-database-operator-system`.

### Testing the Oracle Database Operator

#### Verify the operator is running

After installation, verify that the Oracle Database Operator pods are running:

```shell
kubectl get pods -n oracle-database-operator-system
```

You should see output similar to:

```
NAME                                                        READY   STATUS    RESTARTS   AGE
oracle-database-operator-controller-manager-xxxxxxxxx-xxxxx   1/1     Running   0          5m
```

**Understanding the output:**

- `READY: 1/1` - The operator pod has 1 container and it's ready
- `STATUS: Running` - The pod is running successfully
- `RESTARTS: 0` - No restarts indicates stable operation

If the pod is not running, check the pod details:

```shell
kubectl describe pod -n oracle-database-operator-system -l control-plane=controller-manager
```

#### Verify CRDs are installed

The Oracle Database Operator installs several Custom Resource Definitions (CRDs) that extend the Kubernetes API. Verify these CRDs are installed:

```shell
kubectl get crds | grep oracle.db
```

You should see output listing the database-related CRDs:

```
autonomouscontainerdatabases.database.oracle.com
autonomousdatabases.database.oracle.com
autonomousdatabasebackups.database.oracle.com
autonomousdatabaserestores.database.oracle.com
cdbresources.database.oracle.com
dataguardbrokers.database.oracle.com
dbcssystems.database.oracle.com
oraclerestdataservices.database.oracle.com
pdbresources.database.oracle.com
shardingdatabases.database.oracle.com
singleinstancedatabases.database.oracle.com
```

These CRDs enable you to manage Oracle databases as Kubernetes resources.

To see detailed information about a specific CRD:

```shell
kubectl get crd singleinstancedatabases.database.oracle.com -o yaml
```

#### Validate a sample resource

To verify the operator can recognize and validate database resources without actually creating a database, you can use kubectl's dry-run feature.

Create a file named `sidb-test.yaml` with a minimal SingleInstanceDatabase resource:

```yaml
apiVersion: database.oracle.com/v1alpha1
kind: SingleInstanceDatabase
metadata:
  name: test-sidb
  namespace: default
spec:
  sid: FREE
  edition: free
  image:
    pullFrom: container-registry.oracle.com/database/free:latest-lite
    prebuiltDB: true
```

**Understanding the configuration:**

- `apiVersion`: Uses the database.oracle.com API group installed by the operator
- `kind: SingleInstanceDatabase`: Specifies a single instance Oracle database
- `sid: FREE`: The Oracle System Identifier (must be "FREE" for Free edition)
- `edition: free`: Uses Oracle Database Free edition
- `image.pullFrom`: Container image location
- `image.prebuiltDB`: Uses a prebuilt database to speed up provisioning

Validate the resource without creating it:

```shell
kubectl apply -f sidb-test.yaml --dry-run=server
```

You should see output similar to:

```
singleinstancedatabase.database.oracle.com/test-sidb created (server dry run)
```

This confirms that:
- The operator's CRDs are properly installed
- The resource definition is valid
- The operator would accept this resource if actually applied

**Note:** This command does not create any actual database or resources. It only validates that the manifest is syntactically correct and would be accepted by the operator. The dry-run validation happens at the Kubernetes API server level, so it will not appear in the operator logs.

To see what the operator would create, you can also use:

```shell
kubectl apply -f sidb-test.yaml --dry-run=server -o yaml
```

This shows the complete resource definition as the operator would see it, including any default values the operator would add.

#### Create and test a database instance

To fully test the operator's functionality, create an actual database instance. This example uses Oracle Database Free edition which is lightweight and quick to deploy.

Create a file named `sidb-live-test.yaml`:

```yaml
apiVersion: database.oracle.com/v1alpha1
kind: SingleInstanceDatabase
metadata:
  name: sidb-test
  namespace: default
spec:
  sid: FREE
  edition: free
  adminPassword:
    secretName: sidb-admin-secret
  image:
    pullFrom: container-registry.oracle.com/database/free:latest-lite
    prebuiltDB: true
  persistence:
    size: 20Gi
    storageClass: "oci-bv"
    accessMode: ReadWriteOnce
```

First, create the admin password secret:

```shell
kubectl create secret generic sidb-admin-secret \
  --from-literal=password='MyTestPassword123#' \
  -n default
```

:::warning
Use a strong password in production environments. This is just a test example.
:::

Apply the database resource:

```shell
kubectl apply -f sidb-live-test.yaml
```

Monitor the database creation:

```shell
kubectl get singleinstancedatabase sidb-test -w
```

**Expected progression:**

1. Initial state: `STATUS` will show as `Creating`
2. Database provisioning: Pod is created and database initialization begins
3. Ready state: `STATUS` shows `Healthy` and `READY` is `true`

This process typically takes 5-10 minutes for the Free edition with prebuiltDB enabled.

#### Test database connectivity

Once the database is ready, test connectivity using a SQLcl client pod:

```shell
kubectl run sqlcl-test --rm -it --restart=Never \
  --image=container-registry.oracle.com/database/sqlcl:25.3.0 \
  -- bash
```

Inside the pod, connect to the database using SQLcl:

```shell
sql sys/MyTestPassword123#@sidb-test.default.svc.cluster.local:1521/FREEPDB1 as sysdba
```

**Understanding the connection string:**

- `sys` - Database administrator user
- `MyTestPassword123#` - Password from the secret
- `sidb-test.default.svc.cluster.local` - Kubernetes service DNS name
- `1521` - Oracle listener port
- `FREEPDB1` - Default pluggable database (PDB) name for Free edition

Run a simple query to verify functionality:

```sql
SELECT 'Database is working!' as status FROM dual;
EXIT;
```

Expected output:

```
STATUS
-------------------
Database is working!
```

Exit the test pod (it will be automatically deleted due to `--rm` flag).

#### Clean up test resources

After testing, remove the test database and secret:

```shell
kubectl delete singleinstancedatabase sidb-test
kubectl delete secret sidb-admin-secret
```

**Note:** The persistent volume claim (PVC) may not be automatically deleted. Check and remove it if needed:

```shell
kubectl get pvc
kubectl delete pvc sidb-test-pvc  # Replace with actual PVC name
```

### Monitoring the Oracle Database Operator

#### Check operator logs

View the operator logs to troubleshoot issues or monitor activity:

```shell
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager --tail=50
```

This shows the last 50 log lines from the operator controller manager.

To follow logs in real-time:

```shell
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager -f
```

Filter logs for a specific database resource:

```shell
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager | grep "sidb-test"
```

#### Monitor database resource status

Check the status of all database resources:

```shell
# Single Instance Databases
kubectl get singleinstancedatabase --all-namespaces

# Autonomous Databases
kubectl get autonomousdatabase --all-namespaces

# Autonomous Container Databases
kubectl get autonomouscontainerdatabase --all-namespaces
```

Get detailed status for a specific database:

```shell
kubectl describe singleinstancedatabase <database-name> -n <namespace>
```

The status section shows:

- **Status**: Current state (Creating, Healthy, Unhealthy, etc.)
- **Conditions**: Detailed condition checks
- **Events**: Recent events related to the database
- **Connect String**: Connection information once ready

Watch for status changes:

```shell
kubectl get singleinstancedatabase <database-name> -w
```

---

## Troubleshooting

### Operator pod issues

**Problem: Operator pod is not running**

Check pod status:

```shell
kubectl get pods -n oracle-database-operator-system
kubectl describe pod -n oracle-database-operator-system -l control-plane=controller-manager
```

Common causes:

1. **Image pull errors**: Verify image access and credentials
2. **Resource constraints**: Check if the node has sufficient CPU/memory
3. **RBAC permissions**: Ensure service account has correct permissions

Check events for the operator deployment:

```shell
kubectl get events -n oracle-database-operator-system --sort-by='.lastTimestamp'
```

**Problem: Operator pod is CrashLoopBackOff**

View recent logs:

```shell
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager --previous
```

The `--previous` flag shows logs from the previous (crashed) container instance.

Common fixes:

- Verify webhook certificates are properly configured
- Check for conflicts with other operators
- Ensure all CRDs are properly installed

### Database provisioning failures

**Problem: Database stays in "Creating" state**

Check the database resource status:

```shell
kubectl describe singleinstancedatabase <database-name>
```

Look for:

- **Conditions**: Shows specific errors or warnings
- **Events**: Recent activities and failures
- **Status Message**: Detailed error description

Common issues:

1. **Pod not starting**: Check pod status
   ```shell
   kubectl get pods -l app=<database-name>
   kubectl describe pod <database-pod-name>
   ```

2. **Initialization errors**: Check database pod logs
   ```shell
   kubectl logs <database-pod-name>
   ```

3. **Insufficient resources**: Verify node resources
   ```shell
   kubectl describe node <node-name>
   ```

**Problem: Database status shows "Unhealthy"**

This indicates the database pod is running but failing health checks.

Check pod logs for errors:

```shell
kubectl logs <database-pod-name> --tail=100
```

Verify the database listener is running:

```shell
kubectl exec <database-pod-name> -- lsnrctl status
```

Check database alert log:

```shell
kubectl exec <database-pod-name> -- tail -100 /opt/oracle/diag/rdbms/*/*/trace/alert*.log
```

### Storage issues

**Problem: PVC remains in "Pending" state**

Check PVC status:

```shell
kubectl describe pvc <pvc-name>
```

Common causes:

1. **No storage class available**
   - List available storage classes:
     ```shell
     kubectl get storageclass
     ```
   - Specify a valid storage class in your database spec:
     ```yaml
     spec:
       persistence:
         storageClass: "oci-bv"  # or your cluster's storage class
     ```

2. **Insufficient storage quota**
   - Verify namespace resource quota
   - Request a smaller volume size

3. **Storage class not supporting access mode**
   - Verify the storage class supports the requested access mode (ReadWriteOnce, ReadWriteMany)

**Problem: Database fails with volume mount errors**

Check pod events and logs:

```shell
kubectl describe pod <database-pod-name>
kubectl logs <database-pod-name>
```

Verify PVC is bound:

```shell
kubectl get pvc
```

Ensure the persistent volume has correct permissions:

```shell
kubectl exec <database-pod-name> -- ls -la /opt/oracle/oradata
```

### Database connectivity issues

**Problem: Cannot connect to database from application**

1. **Verify database service exists**
   ```shell
   kubectl get svc | grep <database-name>
   ```

2. **Check service endpoints**
   ```shell
   kubectl get endpoints <service-name>
   ```
   Endpoints should point to the database pod IP.

3. **Test connectivity from within cluster**
   ```shell
   kubectl run test-connectivity --rm -it --restart=Never \
     --image=busybox -- sh -c "nc -zv <database-service-name> 1521"
   ```

4. **Verify listener is running**
   ```shell
   kubectl exec <database-pod-name> -- lsnrctl status
   ```

5. **Check network policies**
   ```shell
   kubectl get networkpolicies -n <namespace>
   ```
   Ensure network policies allow traffic to the database pod.

**Problem: Connection refused errors**

- Verify the database is fully initialized and healthy
- Check if listener is on the correct port (default: 1521)
- Ensure firewall rules allow traffic on port 1521
- Verify the service name and namespace in connection string

### Common error messages

**"Insufficient CPU/Memory"**

The node doesn't have enough resources to schedule the database pod.

Solution:

- Reduce resource requests in database spec
- Add more nodes to the cluster
- Remove unnecessary workloads

**"Failed to create database: Invalid SID"**

The SID doesn't match the edition requirements.

Solution:

- For Free edition, SID must be "FREE"
- For Enterprise/Standard, use alphanumeric SID (max 8 characters)

**"Webhook call failed"**

The operator's admission webhook is not responding.

Solution:

```shell
# Check webhook configuration
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Restart operator
kubectl rollout restart deployment -n oracle-database-operator-system oracle-database-operator-controller-manager
```

**"Secret not found"**

The admin password secret doesn't exist or is in wrong namespace.

Solution:

- Create the secret in the same namespace as the database resource
- Verify secret name matches the database spec

### Debugging tips

**Enable debug logging**

Modify the operator deployment to enable debug logs:

```shell
kubectl edit deployment oracle-database-operator-controller-manager -n oracle-database-operator-system
```

Add or modify the `--zap-log-level` argument to `debug`:

```yaml
spec:
  template:
    spec:
      containers:
      - args:
        - --zap-log-level=debug
```

**Check operator metrics**

The operator exposes Prometheus metrics:

```shell
kubectl port-forward -n oracle-database-operator-system \
  svc/oracle-database-operator-controller-manager-metrics-service 8443:8443
```

Access metrics at `https://localhost:8443/metrics`

**Verify RBAC permissions**

Check if the operator service account has correct permissions:

```shell
kubectl get clusterrole | grep oracle-database-operator
kubectl describe clusterrole oracle-database-operator-manager-role
```

Verify service account bindings:

```shell
kubectl get clusterrolebinding | grep oracle-database-operator
kubectl describe clusterrolebinding oracle-database-operator-manager-rolebinding
```

**Get operator version**

```shell
kubectl get deployment oracle-database-operator-controller-manager \
  -n oracle-database-operator-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Export database resource for inspection**

```shell
kubectl get singleinstancedatabase <database-name> -o yaml > database-export.yaml
```

This exports the complete resource including status, allowing offline analysis or sharing for support.

**Useful log patterns to search for**

```shell
# Find reconciliation errors
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager | grep "ERROR"

# Find specific database operations
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager | grep "Reconciling SingleInstanceDatabase"

# Find webhook validation issues
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager | grep "webhook"
```

## Getting Help

- [#oracle-db-microservices Slack channel](https://oracledevs.slack.com/archives/C06L9CDGR6Z) in the Oracle Developers slack workspace.
- [Open an issue in GitHub](https://github.com/oracle/microservices-datadriven/issues/new).

