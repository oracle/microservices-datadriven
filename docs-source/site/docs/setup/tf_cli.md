---
title: Terraform Installation (CLI)
sidebar_position: 1
---
## Oracle Backend for Microservices and AI - Terraform for OCI

This document describes how to setup OBaaS using the Terraform CLI.

### What Gets Deployed

This Terraform configuration deploys a complete Oracle Backend for Microservices and AI environment including:

- **Oracle Kubernetes Engine (OKE)** cluster with worker nodes
  - **OBaaS System Namespace** The OBaaS Cluster-singleton prerequisites. Defaults to `obaas-system`.
  - **OBaaS Namespace** OBaaS platform components (APISIX, Kafka, Eureka, Observability stack, etc.). Defaults to the value of `label_prefix`.
- **Autonomous Database** (or connects to your existing database)
- **Load Balancer** for ingress traffic
- **Network infrastructure** (VCN, subnets, security lists, route tables)
- **Optional: AI Optimizer and Toolkit**

### Prerequisites

:::warning Important
Ensure all prerequisites are met before starting the deployment to avoid errors.
:::

#### Required Tools

- **Terraform**

  ```bash
  # Verify installation
  terraform version
  ```

- **OCI CLI** - Configured with API key authentication

  ```bash
  # Verify OCI CLI is configured
  oci os ns get
  ```

#### OCI Tenancy Requirements

Verify your tenancy has sufficient quotas for:

- **Compute**: At least 6 OCPUs for VM.Standard.E4/E5.Flex shapes
- **OKE**: Ability to create OKE clusters
- **Autonomous Database**: 2 ECPU minimum (unless using existing database)
- **Networking**: VCN, subnets, and flexible load balancer (10-100 Mbps)
- **Storage**: Block volumes for persistent storage

:::tip Checking Quotas
Navigate to **Governance & Administration → Tenancy Management → Limits, Quotas and Usage** in OCI Console to verify your quotas.
:::

### Quick Start

#### Step 1: Initialize Terraform

```bash
terraform init
```

**Expected output**: Terraform will download required providers (OCI provider) and initialize the backend.

#### Step 2: Choose and Configure Your Deployment

Copy an example configuration based on your needs:

```bash
# Option A: New Autonomous Database (recommended for new deployments)
cp examples/k8s-new-adb.tfvars terraform.tfvars

# Option B: Bring your own existing database
cp examples/k8s-byo-other-db.tfvars terraform.tfvars
```

#### Step 3: Configure OCI Credentials

Edit `terraform.tfvars` with your OCI credentials:

```hcl
# Required: OCI Authentication
tenancy_ocid     = "ocid1.tenancy.oc1..aaa..."      # From OCI Console
compartment_ocid = "ocid1.compartment.oc1..aaa..."  # Target compartment
user_ocid        = "ocid1.user.oc1..aaa..."         # Your user OCID
fingerprint      = "xx:xx:xx:xx:..."                # API key fingerprint
private_key_path = "~/.oci/oci_api_key.pem"         # Path to private key
region           = "us-phoenix-1"                   # OCI region

# Optional: Customize deployment
label_prefix     = "myapp"                          # Max 12 characters
```

:::tip Finding Your OCIDs

- **Tenancy OCID**: OCI Console → Profile Icon → Tenancy
- **Compartment OCID**: Identity & Security → Compartments → Select compartment
- **User OCID**: Identity & Security → Users → Your user
- **Fingerprint**: Identity & Security → Users → Your user → API Keys
:::

#### Step 4: Review the Deployment Plan

```bash
terraform plan
```

Review the resources that will be created.

#### Step 5: Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately 30-45 minutes.

:::note During Deployment
You'll see various resources being created. The OKE cluster and ADB provisioning take the longest.
:::

#### Step 6: Configure kubectl Access

After deployment completes, configure kubectl to access your cluster:

```bash
# The output will show the exact command. Example:
oci ce cluster create-kubeconfig \
  --cluster-id ocid1.cluster.oc1.phx... \
  --region us-phoenix-1 \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT
  --file $HOME/.kube/config \
  --with-auth-context \
  --profile DEFAULT

# Verify access
kubectl get nodes
```

:::tip First Deployment
It may take 5-10 additional minutes after `terraform apply` completes for all pods to reach Running state.
:::

#### Step 7: Access OBaaS Services

```bash
# View deployed services
kubectl get svc -A

# If AI Optimizer was deployed (deploy_optimizer = true)
echo "Optimizer UI: $(terraform output -raw optimizer_client_url)"
echo "Optimizer API: $(terraform output -raw optimizer_server_url)"
```

### Configuration Options

#### General Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `tenancy_ocid` | OCI Tenancy OCID | Required |
| `compartment_ocid` | Compartment for resources | Required |
| `region` | OCI Region | Required |
| `label_prefix` | Prefix for resource names (max 12 chars) | Auto-generated |

The `label_prefix` determines the name of the namespace where the OBaaS components will be installed. **WHAT ELSE??**

#### Database Options

Choose the database configuration that fits your needs:

| Option | Use Case | When to Choose |
|--------|----------|----------------|
| **New ADB** | New deployments | You don't have an existing database. Best for getting started. |
| **BYO ADB-S** | Existing Autonomous DB | You have an existing Autonomous Database you want to reuse. |
| **BYO Other DB** | Existing Oracle DB | You have an on-premise or other Oracle Database (19c+). |

##### Option 1: New Autonomous Database (Default)

**Recommended for**: First-time deployments, development, and testing.

```hcl
# Leave byo_db_type empty (default)
adb_ecpu_core_count         = 2    # Minimum for development, 4+ for production
adb_data_storage_size_in_gb = 20   # Adjust based on needs
adb_license_model           = "LICENSE_INCLUDED"  # or "BRING_YOUR_OWN_LICENSE"
adb_networking              = "PRIVATE_ENDPOINT_ACCESS"  # Recommended for security
```

##### Option 2: Bring Your Own Autonomous Database (ADB-S)

**Recommended for**: Reusing an existing Autonomous Database instance.

```hcl
byo_db_type     = "ADB-S"
byo_db_password = "your_admin_password"  # ADMIN user password
byo_adb_ocid    = "ocid1.autonomousdatabase.oc1..."
```

##### Option 3: Bring Your Own Other Database

**Recommended for**: Connecting to an existing Oracle Database (on-premise or cloud).

```hcl
byo_db_type     = "OTHER"
byo_db_password = "your_system_password"  # SYSTEM user password
byo_odb_host    = "db-host.example.com"
byo_odb_port    = 1521
byo_odb_service = "SERVICENAME"
```

:::note Requirements

- Oracle Database 19c or later
- Network connectivity from OKE cluster to database
- SYSTEM user access for schema creation
:::

#### Kubernetes Options

| Variable | Description | Default |
|----------|-------------|---------|
| `k8s_cpu_node_pool_size` | Number of CPU worker nodes | 3 |
| `k8s_api_is_public` | Expose K8s API publicly | true |
| `k8s_api_endpoint_allowed_cidrs` | CIDRs allowed to access K8s API | "0.0.0.0/0" |
| `k8s_node_pool_gpu_deploy` | Deploy GPU node pool | false |
| `k8s_gpu_node_pool_size` | Number of GPU worker nodes | 1 |
| `k8s_run_cfgmgt` | Run configuration management | true |
| `k8s_use_cluster_addons` | Install OKE cluster add-ons | true |
| `k8s_byo_ocir_url` | BYO Oracle Container Registry URL | "" |

#### Compute Options

| Variable | Description | Default |
|----------|-------------|---------|
| `compute_cpu_shape` | CPU compute shape | VM.Standard.E5.Flex |
| `compute_cpu_ocpu` | OCPUs per CPU worker | 2 |
| `compute_gpu_shape` | GPU compute shape | VM.GPU.A10.1 |

#### Network Options

By default, a new VCN with public and private subnets is created. To use existing networking:

```hcl
byo_vcn_ocid            = "ocid1.vcn.oc1..."
byo_public_subnet_ocid  = "ocid1.subnet.oc1..."
byo_private_subnet_ocid = "ocid1.subnet.oc1..."
```

#### Load Balancer Options

| Variable | Description | Default |
|----------|-------------|---------|
| `lb_min_shape` | Minimum bandwidth (Mbps) | 10 |
| `lb_max_shape` | Maximum bandwidth (Mbps) | 10 |
| `client_allowed_cidrs` | CIDRs allowed for client access | "0.0.0.0/0" |
| `server_allowed_cidrs` | CIDRs allowed for server API access | "0.0.0.0/0" |

#### AI Optimizer

| Variable | Description | Default |
|----------|-------------|---------|
| `deploy_optimizer` | Deploy AI Optimizer and Toolkit | false |

### Examples

See the [examples/](examples/) directory for complete configuration examples:

| File | Description |
|------|-------------|
| `k8s-new-adb.tfvars` | Kubernetes deployment with new Autonomous Database |
| `k8s-byo-other-db.tfvars` | Kubernetes deployment with bring-your-own database |

#### Running Tests

The `examples/manual-test.sh` script validates configurations using your OCI credentials:

```bash
# Uses ~/.oci/config [DEFAULT] profile
./examples/manual-test.sh

# Use a specific profile
./examples/manual-test.sh MYPROFILE
```

### Outputs

After successful deployment:

| Output | Description |
|--------|-------------|
| `app_name` | Application label/namespace |
| `app_version` | Deployed application version |
| `optimizer_client_url` | AI Optimizer web UI URL |
| `optimizer_server_url` | AI Optimizer API URL |
| `kubeconfig_cmd` | Command to generate kubeconfig |

### OCI Resource Manager (ORM)

This configuration is compatible with OCI Resource Manager for deployment via the OCI Console. The `schema.yaml` file defines the ORM form layout.

### Directory Structure

```tree
.
├── README.md                 # README
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
├── schema.yaml               # OCI ORM schema
├── examples/                 # Example tfvars files
│   ├── README.md
│   ├── k8s-new-adb.tfvars
│   ├── k8s-byo-other-db.tfvars
│   └── manual-test.sh
├── modules/
│   ├── kubernetes/           # OKE cluster and configuration
│   └── network/              # VCN, subnets, gateways
└── cfgmgt/                   # Configuration management scripts
```

### Security Best Practices

:::warning Security Recommendations
:::

1. **Restrict API Access**: Change `k8s_api_endpoint_allowed_cidrs` from `"0.0.0.0/0"` to your specific IP ranges:

   ```hcl
   k8s_api_endpoint_allowed_cidrs = "203.0.113.0/24"  # Your IP range
   ```

2. **Use Private Database Access**: Set `adb_networking = "PRIVATE_ENDPOINT_ACCESS"` for production deployments

3. **Limit Load Balancer Access**: Configure `client_allowed_cidrs` to restrict who can access your services:

   ```hcl
   client_allowed_cidrs = "203.0.113.0/24"  # Your allowed clients
   ```

### Cleanup

To remove all deployed resources:

:::warning Data Loss
This will permanently delete all resources including the database (if created by Terraform). Ensure you have backups of any important data.
:::

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```
