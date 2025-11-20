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
- [Monitoring the Oracle Database Operator](#monitoring-the-oracle-database-operator)
  - [Check operator logs](#check-operator-logs)

---

### Prerequisites and Assumptions

This guide makes the following assumptions:

- **Namespace**: The Oracle Database Operator is installed in the `oracle-database-operator-system` namespace (the default).
- **Kubectl Access**: You have kubectl configured and authenticated to your Kubernetes cluster with appropriate permissions to:
  - View operator pods and CRDs
  - Create and manage database custom resources
  - View logs from the oracle-database-operator-system namespace
- **Command-line Tools**: The following tools are installed and available:
  - `kubectl` - Kubernetes command-line tool
- **File References**: Examples reference YAML files that you can create for testing purposes.

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

### Monitoring the Oracle Database Operator

#### Check operator logs

View the operator logs to troubleshoot issues or monitor activity:

```shell
kubectl logs -n oracle-database-operator-system -l control-plane=controller-manager --tail=50
```

This shows the last 50 log lines from the operator controller manager.

