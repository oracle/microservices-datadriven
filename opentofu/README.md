# Oracle Backend for Microservices and AI - Terraform for OCI

This directory contains Terraform configuration to deploy Oracle Backend for Microservices and AI (OBaaS) on Oracle Cloud Infrastructure (OCI).

## Prerequisites

- [Terraform](https://www.terraform.io/) (>= 1.5)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) configured with API key authentication
- OCI tenancy with sufficient quotas for:
  - OKE (Oracle Kubernetes Engine) cluster
  - Flexible compute shapes (VM.Standard.E4/E5.Flex or VM.Standard.A1/A2.Flex)
  - Autonomous Database (unless using BYO database)
  - Load Balancer (flexible shape)

## Quick Start

1. **Initialize the configuration:**
   ```bash
   terraform init
   ```

2. **Copy an example configuration:**
   ```bash
   cp examples/k8s-new-adb.tfvars terraform.tfvars
   ```

3. **Configure OCI credentials** in `terraform.tfvars`:
   ```hcl
   tenancy_ocid     = "ocid1.tenancy.oc1..aaa..."
   compartment_ocid = "ocid1.compartment.oc1..aaa..."
   user_ocid        = "ocid1.user.oc1..aaa..."
   fingerprint      = "xx:xx:xx:..."
   private_key_path = "~/.oci/oci_api_key.pem"
   region           = "us-phoenix-1"
   ```

4. **Review and apply:**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Configure kubectl access** (after apply completes):
   ```bash
   # Use the kubeconfig_cmd output
   oci ce cluster create-kubeconfig --cluster-id <cluster_ocid> --region <region>
   ```

## Configuration Options

### General Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `tenancy_ocid` | OCI Tenancy OCID | Required |
| `compartment_ocid` | Compartment for resources | Required |
| `region` | OCI Region | Required |
| `label_prefix` | Prefix for resource names (max 12 chars) | Auto-generated |
| `init_destroy` | Prepare for deletion on apply, then destroy | `false` |

### Database Options

The deployment supports three database configurations:

#### Option 1: New Autonomous Database (Default)
```hcl
# Leave byo_db_type empty (default)
adb_ecpu_core_count         = 2
adb_data_storage_size_in_gb = 20
adb_license_model           = "LICENSE_INCLUDED"  # or "BRING_YOUR_OWN_LICENSE"
adb_networking              = "PRIVATE_ENDPOINT_ACCESS"  # or "SECURE_ACCESS"
```

#### Option 2: Bring Your Own Autonomous Database (ADB-S)
```hcl
byo_db_type    = "ADB-S"
byo_db_password = "your_admin_password"
byo_adb_ocid   = "ocid1.autonomousdatabase.oc1..."
```

#### Option 3: Bring Your Own Other Database
```hcl
byo_db_type     = "OTHER"
byo_db_password = "your_system_password"
byo_odb_host    = "db-host.example.com"
byo_odb_port    = 1521
byo_odb_service = "SERVICENAME"
```

### Kubernetes Options

| Variable | Description | Default |
|----------|-------------|---------|
| `k8s_cpu_node_pool_size` | Number of CPU worker nodes | 3 |
| `k8s_api_is_public` | Expose K8s API publicly | true |
| `k8s_api_endpoint_allowed_cidrs` | CIDRs allowed to access K8s API | "0.0.0.0/0" |
| `k8s_node_pool_gpu_deploy` | Deploy GPU node pool | false |
| `k8s_gpu_node_pool_size` | Number of GPU worker nodes | 1 |
| `k8s_deploy_kafka` | Deploy a Kafka cluster using the Strimzi operator | false |
| `k8s_deploy_coherence` | Deploy a Coherence cluster using the Coherence Operator | false |
| `k8s_run_cfgmgt` | Run configuration management | true |
| `k8s_use_cluster_addons` | Install OKE cluster add-ons | true |
| `k8s_use_local_charts` | Use local Helm charts from `helm/` instead of the remote Helm repository | false |
| `k8s_byo_ocir_url` | BYO Oracle Container Registry URL | "" |

### Primary Storage

The primary Kubernetes deployment preallocates block volumes independently of `fsdr_enabled`. The generated manifest reserves one CSI PV for each chart claim. `cfgmgt/apply.py` applies that manifest before installing Helm. With `k8s_run_cfgmgt=false`, apply the generated manifest before installing the charts manually.

The inventory covers three APISIX etcd claims, one ZooKeeper claim, one SigNoz claim and one ClickHouse claim. Enabling Kafka adds three 100 GiB volumes. OCI provisions at least 50 GiB per block volume. Chart replica counts and storage requests use the same inventory as provisioning; update that inventory when changing the deployed chart's storage requirements.

The `obaas-preallocated` StorageClass uses `blockvolume.csi.oraclecloud.com` so native FSDR recognizes its storage. PV claim references reserve the preallocated volumes for the chart's PVCs.

If an earlier apply created this class with `kubernetes.io/no-provisioner`, replace its metadata before reapplying. Run from `opentofu/`:

```bash
kubectl --kubeconfig cfgmgt/stage/kubeconfig delete storageclass obaas-preallocated
tofu apply
```

The apply regenerates and installs the corrected class. Existing PVs, PVCs and OCI volumes remain in place.

### Local Helm Chart Development

By default, the OCI Resource Manager build vendors the published Helm charts into the stack package. For local Terraform development, you can test charts from a local checkout without rebuilding the ZIP.

`apply.py` looks for local charts under the sibling `helm` directory:

```text
../helm/infra-charts/obaas-prereqs
../helm/infra-charts/obaas
```

Verify the charts are visible:

```bash
ls ../helm/infra-charts/obaas/Chart.yaml
ls ../helm/infra-charts/obaas-prereqs/Chart.yaml
```

If the charts have dependencies, update them in the chart repo before applying:

```bash
cd ../helm/infra-charts
helm dependency update obaas-prereqs
helm dependency update obaas
```

Then run Terraform with local charts enabled:

```bash
cd opentofu
terraform plan -var='k8s_use_local_charts=true'
terraform apply -var='k8s_use_local_charts=true'
```

You can also set this in `terraform.tfvars`:

```hcl
k8s_use_local_charts = true
```

To return to published charts for direct Terraform runs, remove that variable or set it to `false`.

### Full Stack Disaster Recovery

Enable FSDR by selecting a subscribed standby region:

```hcl
fsdr_enabled         = true
fsdr_region_1        = "uk-london-1"
k8s_use_local_charts  = true
```

The `fsdr_regional_application_urls` output provides each region's load balancer URL. After recovery, direct clients to the active region's URL. To create an application DNS record initially pointing to the primary, supply both optional inputs for an existing OCI public DNS zone:

```hcl
fsdr_dns_zone_ocid = "<oci-public-dns-zone-ocid>"
fsdr_dns_name      = "obaas.example.com"
```

The deployment creates:

- A standby VCN, OKE cluster, Native Ingress load balancer, and private Autonomous Data Guard database endpoint.
- Associated protection groups covering Autonomous Database, OKE, and the application's OCI persistent storage.
- Regional log and backup buckets, and IAM policies for FSDR protection groups and runtime container instances.
- Native switchover and failover plans covering database, storage and OKE recovery.

The standby starts with one CPU worker for OKE add-ons. FSDR scales its node pools to the primary's configured capacity during recovery. OKE backups include the OBaaS namespace and `obaas-system`; the default schedule is hourly with 20 retained backups. Private OCIR images are replicated with the OKE backups.

Run from a host with access to the primary cluster API and OCI CLI authentication. Prepare local chart dependencies when `k8s_use_local_charts=true` and grant the deployment identity the [FSDR permissions](../docs-source/site/docs/setup/cloud/oci.mdx#fsdr-policies).

Plan and apply the complete deployment:

```bash
tofu init
tofu plan -out=fsdr.tfplan
tofu apply fsdr.tfplan
```

FSDR groups the [primary volumes](#primary-storage) by availability domain and enables standby-region replication. Setting `fsdr_enabled=false` removes the recovery volume groups while preserving primary volumes, PV definitions and chart storage settings. Additional workload namespaces need their backing storage configured for DR separately.

The OCI provider manages protection-group membership and plan operations. Wait for initial storage replication and a successful OKE backup before running recovery prechecks. Increment `fsdr_plan_refresh_trigger` and `fsdr_plan_verify_trigger` after changing protected resources.
Native FSDR restores the protected application and `obaas-system` namespaces and performs the configured database and storage transitions. Apply chart upgrades on the active cluster through `cfgmgt/apply.py`; recovery uses the protected resources captured in a subsequent successful backup. Recovery of chart CRDs, cluster-scoped RBAC and admission webhooks requires verification in a DR drill. Configure destination database OCIDs, connection settings and wallets for OBaaS, then verify application and load-balancer health before directing traffic to the recovered region. The operator maintains DNS routing. Terraform preserves the runtime DR roles, storage members, worker counts and DNS target.

| Variable | Purpose | Default |
|----------|---------|---------|
| `fsdr_plan_types` | `SWITCHOVER`, `FAILOVER`, `START_DRILL`, `STOP_DRILL` plans | Switchover and failover |
| `fsdr_plan_refresh_trigger` | Increment to refresh plans after group changes | `null` |
| `fsdr_plan_verify_trigger` | Increment to verify plans | `null` |
| `fsdr_adb_drill_standby_type` | ADB drill mechanism | `SNAPSHOT_STANDBY` |
| `fsdr_timeouts` | Group, plan, and Automatic DR create/update/delete timeouts | `20m` each |
| `fsdr_automatic_dr` | ADB events that trigger standby-group DR plans | `null` |
| `fsdr_plan_executions` | Explicit executions keyed by lowercase plan type | `{}` |
| `fsdr_dns_zone_ocid` | Public DNS zone for the initial application record; supply with `fsdr_dns_name` | Empty |
| `fsdr_dns_name` | Hostname initially pointing to the primary; supply with `fsdr_dns_zone_ocid` | Empty |
| `fsdr_standby_network` | Existing standby VCN and public/private subnet IDs | Managed network |
| `fsdr_standby_vcn_cidr` | Managed standby VCN CIDR | `10.43.0.0/16` |
| `fsdr_standby_cpu_node_pool_size` | Warm CPU workers for OKE add-ons | `1` |
| `fsdr_backup_schedule` | RFC 5545 OKE backup recurrence, in UTC | `FREQ=HOURLY;INTERVAL=1` |
| `fsdr_backup_retention` | Retained OKE backups, whole number from 1 to 20 | `20` |
| `fsdr_additional_namespaces` | Workload namespaces using the OBaaS database | `[]` |

To prepare drill plans, include `START_DRILL` and `STOP_DRILL` in `fsdr_plan_types`. The initial apply creates Start Drill. After executing it successfully, clear `fsdr_plan_executions` and apply with `k8s_run_cfgmgt=false` to create Stop Drill on the inactive standby group. Stop Drill runs OCI's native cleanup steps. After it completes, clear the execution input and apply to remove the consumed Stop Drill plan. Drills use `SNAPSHOT_STANDBY` and the standby region's load balancer URL. Validate drill database connections and wallets before exercising application traffic. Refresh and verify triggers apply to every configured plan. The regional submodule supports cloning through `plans[key].source_plan_id`.

After a successful drill and recovery prechecks, opt into database-event-driven recovery:

```hcl
fsdr_automatic_dr = {
  is_auto_switchover_enabled = true
  is_auto_failover_enabled   = true
}
```

[Automatic DR](https://docs.oracle.com/en-us/iaas/disaster-recovery/doc/configure-automaticdr.html) runs the selected FSDR plan after the protected database emits a switchover or failover event. Each enabled event requires its corresponding active plan. After a role transition, prepare plans and Automatic DR on the new standby group before the next recovery operation. Configuration management applies the primary installation while its database remains primary.

Applying an explicit execution entry submits that operation. Start with a precheck:

```hcl
fsdr_plan_executions = {
  switchover = {
    plan_execution_type = "SWITCHOVER_PRECHECK"
  }
}
```

Execution types are the four plan types and their `_PRECHECK` variants. Submit one execution per apply. Root execution inputs enable prechecks by default and retain warnings. The regional submodule's `executions[key].plan_id` selects an existing plan when supplied; otherwise it selects the plan with the same key. Executions are stateful resources: review planned replacements before applying changes to execution inputs.

The regional submodule supports OKE `resource_modifier_mappings` for ConfigMaps describing destination resource changes. Use `block_volume_attach_and_mount_operations` for non-movable compute storage. Provider-computed plan groups, execution progress, and automatic execution details are available through the existing resource outputs. The protection-group resource output is sensitive because it includes secret references; `dr_protection_group_id` exposes its identifier separately.

After a switchover or failover, clear `fsdr_plan_executions`, increment the refresh and verify triggers, and review an apply once both regions are available. The provider reads current DR roles, preserves native storage membership after the transition, and creates plans and Automatic DR on the current standby. New storage provisioned in the recovered region requires enrollment in that region before failback. Review replication health and run the new standby's recovery prechecks.

`modules/kubernetes/storage` owns the primary volume inventory and PV configuration. `modules/fsdr` coordinates both regions and owns buckets and IAM. Its `storage` submodule groups the supplied primary volumes and provisions replication; its `region` submodule manages protection groups, plans and operations. Root configuration supplies the OKE, database and network details. See [the FSDR example](examples/k8s-fsdr.tfvars).

### Compute Options

| Variable | Description | Default |
|----------|-------------|---------|
| `compute_cpu_shape` | CPU compute shape | VM.Standard.E5.Flex |
| `compute_cpu_ocpu` | OCPUs per CPU worker | 2 |
| `compute_gpu_shape` | GPU compute shape | VM.GPU.A10.1 |

### Network Options

By default, a new VCN with public and private subnets is created. To use existing networking:

```hcl
byo_vcn_ocid            = "ocid1.vcn.oc1..."
byo_public_subnet_ocid  = "ocid1.subnet.oc1..."
byo_private_subnet_ocid = "ocid1.subnet.oc1..."
```

### Load Balancer Options

| Variable | Description | Default |
|----------|-------------|---------|
| `lb_min_shape` | Minimum bandwidth (Mbps) | 10 |
| `lb_max_shape` | Maximum bandwidth (Mbps) | 10 |
| `client_allowed_cidrs` | CIDRs allowed for client access | "0.0.0.0/0" |
| `server_allowed_cidrs` | CIDRs allowed for server API access | "0.0.0.0/0" |

### AI Optimizer

| Variable | Description | Default |
|----------|-------------|---------|
| `deploy_optimizer` | Deploy AI Optimizer and Toolkit | false |

## Examples

See the [examples/](examples/) directory for complete configuration examples:

| File | Description |
|------|-------------|
| `k8s-new-adb.tfvars` | Kubernetes deployment with new Autonomous Database |
| `k8s-byo-other-db.tfvars` | Kubernetes deployment with bring-your-own database |
| `k8s-fsdr.tfvars` | Two-region Full Stack Disaster Recovery with Autonomous Database |

### Running Tests

Run the mocked regression suites from `opentofu/`:

```bash
tofu init -backend=false
python3 tests/run-mocked-plans.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

The IaC workflow runs the same command and discovers every root and child-module suite. Tests run in temporary copies with isolated inputs and state, using the initialized provider versions. Kubernetes image tests use a targeted mocked cluster setup; all assertions run as plans. The suites use mocked providers and execute no OCI operations or provisioners.

| Suite | Coverage |
|-------|----------|
| Root | Database modes, networking, load balancer access, Marketplace, configuration management, FSDR wiring |
| Network | Public/private subnet separation, CIDR allocation, gateway routes, default ingress |
| Kubernetes | CPU/ARM/GPU workers, image selection, add-ons, API access, IAM, generated Helm values and credentials |
| FSDR | Protection groups, plans, executions, Automatic DR |

To run one module, use `python3 tests/run-mocked-plans.py --module modules/kubernetes` (or `--module .` for the root).

The `examples/manual-test.sh` script validates configurations using your OCI credentials:

```bash
# Uses ~/.oci/config [DEFAULT] profile
./examples/manual-test.sh

# Use a specific profile
./examples/manual-test.sh MYPROFILE
```

## Outputs

After successful deployment:

| Output | Description |
|--------|-------------|
| `app_name` | Application label/namespace |
| `app_version` | Deployed application version |
| `optimizer_client_url` | AI Optimizer web UI URL |
| `optimizer_server_url` | AI Optimizer API URL |
| `kubeconfig_cmd` | Command to generate kubeconfig |

## OCI Resource Manager (ORM)

This configuration is compatible with OCI Resource Manager for deployment via the OCI Console. The `schema.yaml` file defines the ORM form layout.

## Directory Structure

```
.
├── README.md                 # This file
├── main.tf                   # Core resources (LB, ADB)
├── variables.tf              # Root-level variables
├── output.tf                 # Root-level outputs
├── locals.tf                 # Local values
├── provider.tf               # Provider configuration
├── versions.tf               # Version constraints
├── data.tf                   # Data sources
├── nsgs.tf                   # Network Security Groups
├── module_network.tf         # Network module invocation
├── module_kubernetes.tf      # Kubernetes module invocation
├── module_fsdr.tf            # FSDR inputs and module invocation
├── schema.yaml               # OCI ORM schema
├── examples/                 # Example tfvars files
│   ├── README.md
│   ├── k8s-new-adb.tfvars
│   ├── k8s-byo-other-db.tfvars
│   └── manual-test.sh
├── modules/
│   ├── fsdr/                 # Two-region recovery coordination
│   │   └── region/           # Protection groups, plans, executions, Automatic DR
│   ├── kubernetes/           # OKE cluster and configuration
│   └── network/              # VCN, subnets, gateways
└── cfgmgt/                   # Configuration management scripts
```

## Cleanup

Set `init_destroy=true` and apply before starting destroy. Preparation skips chart installation and, for FSDR, disassociates groups and disables group and member-volume replication. Keep the deployed FSDR settings unchanged and leave `init_destroy=true` until destruction completes.

```hcl
init_destroy = true
```

```bash
tofu apply
```

For FSDR deployments, retire retained backups and empty the regional log and backup buckets before destroying the infrastructure. The regional buckets retain their contents until the operator retires them.

See [Clean Up](../docs-source/site/docs/setup/cloud/oci.mdx#clean-up) for local and Resource Manager instructions.

To destroy all resources:

```bash
terraform destroy
```

## License

Copyright (c) 2024, 2026, Oracle and/or its affiliates.
Licensed under the Universal Permissive License (UPL), Version 1.0.
See [LICENSE](http://oss.oracle.com/licenses/upl) for details.
