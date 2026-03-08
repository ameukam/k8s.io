# AWS Infrastructure

**In this guide:** Understand AWS infrastructure in the k8s.io repository and how Kubernetes project resources are managed on Amazon Web Services.

**Time to read:** ~20 minutes

**Prerequisites:**
- [Terraform Basics](../01-getting-started/terraform-basics.md)
- [Repository Overview](../01-getting-started/repository-overview.md)

---

## Overview

AWS hosts critical Kubernetes infrastructure including:
- **Artifact storage and distribution** - Release binaries and packages
- **Container registry** - Kubernetes container images
- **CI/CD clusters** - Prow build infrastructure for testing
- **Multi-region redundancy** - Global availability

All AWS infrastructure is managed in: `infra/aws/terraform/`

---

## AWS Services Used

| Service | Purpose |
|---------|---------|
| **S3** | Storage for artifacts, container image layers, test data, Terraform state |
| **CloudFront** | CDN for distributing packages and reducing transfer costs |
| **EKS** | Kubernetes clusters for Prow build infrastructure and kops CI |
| **IAM** | Role-based access, OIDC federation with GCP/GitHub |
| **VPC** | Network isolation for EKS clusters (dual-stack IPv4/IPv6) |
| **ECR** | Docker image storage for kops infrastructure |
| **ACM** | TLS certificates for CloudFront distributions |
| **WAF** | Protection for CloudFront distributions |
| **Route53** | Health checks for external resources |
| **EC2** | MacOS dedicated hosts, key pairs |
| **Secrets Manager** | Secure storage for sensitive configuration |
| **CloudWatch** | Metric alarms and monitoring |
| **Cost Explorer** | Cost tracking and budget alerts |
| **AWS Organizations** | Multi-account management |
| **Access Analyzer** | Security analysis for resource policies |
| **Service Quotas** | Quota management for test accounts |

---

## Directory Structure

```
infra/aws/terraform/
├── artifacts.k8s.io/          # Release artifacts distribution
├── audit-account/             # Security and compliance account
├── cdn.packages.k8s.io/       # Package distribution CDN
├── cncf-k8s-infra-aws-capa-ami/  # CAPA AMI publishing permissions
├── iam/                       # IAM roles and policies
│   ├── k8s-infra-prow/        # Production Prow IAM
│   └── k8s-infra-prow-canary/ # Canary Prow IAM
├── infrastructure-services/   # Shared infrastructure services
├── kops-infra-ci/            # Kops testing infrastructure
├── macos/                     # MacOS dedicated hosts
├── management-account/        # AWS Organizations management
├── modules/                   # Reusable Terraform modules
│   ├── eks-prow-iam/         # EKS Prow IAM module
│   ├── external-resource-health-check/  # Route53 health checks
│   ├── org-account/          # Organization account module
│   ├── registry-k8s-io-s3-bucket/  # Registry bucket module
│   ├── sns/                  # SNS topics/subscriptions
│   └── tag-policy/           # Tagging policies
├── policy-staging-account-1/  # Policy testing environment
├── prow-build-cluster/       # Main Prow build cluster (EKS)
├── registry-k8s-io-prod/     # Container image distribution
├── s3/                        # Shared S3 resources
├── service-quotas/           # Service quota management
│   └── boskos/               # Test account quotas
└── sso/                       # SSO configuration
```

---

## Key Deployments

### 1. prow-build-cluster (Production CI/CD)

**Location:** `infra/aws/terraform/prow-build-cluster/`

**Purpose:** Primary build cluster for running Kubernetes CI/CD jobs via Prow.

**Components:**
- **EKS Cluster** (v20.20+) with managed node groups
- **Karpenter** for autoscaling compute capacity
- **VPC** with public/private/intra subnets (dual-stack)
- **IRSA** (IAM Roles for Service Accounts) for:
  - VPC CNI
  - EBS CSI Driver
  - AWS Load Balancer Controller
  - Secrets Manager
- **GitOps** via FluxCD
- **Monitoring** stack (Prometheus, Grafana, Alertmanager)

**Environments:**
- **Production:** `k8s-infra-prow` account (468814281478)
- **Canary:** `k8s-infra-prow-canary` account (054318140392)

**Access Pattern:**
```bash
# Via SSO or role assumption
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prow-build-cluster \
  --role-arn arn:aws:iam::ACCOUNT:role/EKSInfraAdmin
```

**Important:** Canary environment is ONLY for validating infrastructure changes, not connected to Prow control plane.

**Multi-Phase Provisioning Required:**

EKS clusters cannot be created in a single Terraform run:

```bash
# Phase 1: Create IAM provisioner role
cd infra/aws/terraform/iam/k8s-infra-prow/
make apply

# Phase 2: Create infrastructure without K8s resources
cd ../prow-build-cluster/
DEPLOY_K8S_RESOURCES=false make apply

# Phase 3: Deploy Kubernetes resources
DEPLOY_K8S_RESOURCES=true make apply

# Phase 4: Deploy non-Terraform K8s resources
kubectl apply -f resources/
```

**Why:** Terraform cannot plan Kubernetes resources before the cluster exists.

### 2. artifacts.k8s.io (Release Distribution)

**Location:** `infra/aws/terraform/artifacts.k8s.io/`

**Purpose:** Multi-region S3 buckets for serving Kubernetes release artifacts (binaries, releases, build artifacts).

**Pattern:** Regional buckets across 18+ AWS regions using aliased providers.

**Components:**
- S3 buckets per region (prefix-based naming)
- IAM roles for OIDC integration with k8s-infra trusted cluster
- Terraform state in `artifacts-k8s-io-tfstate` bucket

**Environments:**
- **Production:** `prod-` prefix buckets
- **Sandbox:** `test-` prefix buckets

**Usage Example:**
```bash
terraform apply -var prefix=prod-  # Production
terraform apply -var prefix=test-  # Testing
```

**⚠️ Gotcha:** Forgetting the prefix could apply test config to prod resources!

### 3. cdn.packages.k8s.io (Package CDN)

**Location:** `infra/aws/terraform/cdn.packages.k8s.io/`

**Purpose:** Cost-optimized package distribution via CloudFront CDN.

**Components:**
- S3 bucket for package storage
- CloudFront distribution with edge caching
- ACM TLS certificate
- WAF rules for protection

**Pattern:** Uses Terraform **workspaces** (unusual for this repo):
```bash
# Production workspace
make plan PROW_ENV=prod
make apply PROW_ENV=prod

# Canary workspace
make plan PROW_ENV=canary
make apply PROW_ENV=canary
```

### 4. registry-k8s-io-prod (Container Registry)

**Location:** `infra/aws/terraform/registry-k8s-io-prod/`

**Purpose:** Multi-region S3 buckets for serving Kubernetes container images.

**Status:** ⚠️ **Legacy** - Being replaced by GCP-based OCI proxy.

**Components:**
- Regional S3 buckets for image layers
- CloudFront distribution for global delivery
- IAM roles for archeio (image syncing)

**Note:** Check README to confirm current usage status before making changes.

### 5. kops-infra-ci (Kops Testing)

**Location:** `infra/aws/terraform/kops-infra-ci/`

**Purpose:** EKS cluster and supporting infrastructure for kops CI/CD testing.

**Components:**
- EKS cluster
- ECR repositories for test images
- S3 storage for test data
- VPC with isolated networking
- Metrics server for monitoring

**State:** Stored in `k8s-infra-kops-ci-tf-state` bucket.

### 6. cncf-k8s-infra-aws-capa-ami

**Location:** `infra/aws/terraform/cncf-k8s-infra-aws-capa-ami/`

**Purpose:** IAM permissions for publishing Cluster API AWS (CAPA) AMIs.

**Components:**
- IAM roles for AMI publication workflow
- OIDC providers for GitHub Actions integration

**Pattern:** Cross-cloud workload identity (GitHub → AWS).

### 7. management-account (AWS Organizations)

**Location:** `infra/aws/terraform/management-account/`

**Purpose:** Manage AWS Organizations structure and accounts.

**Components:**
- Organization configuration
- Member accounts (CAPA playground, infrastructure, kops, security, policy-staging)
- Cost and usage tracking
- Budget alarms
- SSO configuration
- Delegated administrators
- Tag policies for compliance

### 8. audit-account (Security & Compliance)

**Location:** `infra/aws/terraform/audit-account/`

**Purpose:** Security monitoring and compliance auditing.

**Components:**
- Access Analyzer for resource policy analysis
- S3 Storage Lens for visibility
- Audit log aggregation

### 9. service-quotas/boskos (Test Account Quotas)

**Location:** `infra/aws/terraform/service-quotas/boskos/`

**Purpose:** Apply service quota increases to AWS accounts used for e2e testing managed by Boskos (resource management system).

**Pattern:** Modular approach with CAPA-specific quotas module.

---

## Reusable Modules

Located in `infra/aws/terraform/modules/`:

### eks-prow-iam

**Purpose:** IAM roles and policies for EKS Prow cluster provisioning.

**Provides:**
- **EKSInfraAdmin** - Full cluster management permissions
- **EKSInfraViewer** - Read-only access
- **Permission boundaries** - Limit privilege escalation

**Usage:**
```hcl
module "eks_iam" {
  source = "../../modules/eks-prow-iam"

  cluster_name = "prow-build-cluster"
  account_id   = "468814281478"
}
```

### external-resource-health-check

**Purpose:** Route53 health checks for monitoring external resources.

**Provides:**
- HTTPS health check configuration
- CloudWatch alarm integration

### registry-k8s-io-s3-bucket

**Purpose:** Standardized S3 bucket configuration for registry.

**Provides:**
- Consistent bucket settings
- Encryption, versioning, lifecycle policies
- IAM policies for access

### sns

**Purpose:** SNS topics and email subscriptions for notifications.

**Submodules:**
- `sns-topic` - Create SNS topics
- `sns-subscribe-email` - Add email subscribers

### org-account

**Purpose:** AWS Organizations account management.

**Provides:**
- Account creation and configuration
- SSO permission sets
- Account-level settings

### tag-policy

**Purpose:** Tagging policies for organizational compliance.

**Provides:**
- Tag validation rules
- Required tags enforcement

---

## Terraform Patterns

### State Management

Each deployment uses **separate S3 backends**:

| Deployment | State Bucket |
|------------|-------------|
| artifacts.k8s.io | `artifacts-k8s-io-tfstate` |
| kops-infra-ci | `k8s-infra-kops-ci-tf-state` |
| service-quotas | `eks-e2e-boskos-tfstate` |
| audit/management | `k8s-aws-root-account-terraform-state` |

**Key organization:** Hierarchical like `audit-account/terraform.state`

**State locking:** Implied via DynamoDB (not visible in TF configs, handled by S3 backend).

### Provider Configuration

**Multi-Region Pattern:**
```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "ap-northeast-1"
  region = "ap-northeast-1"
}

module "us_east_1" {
  source = "./modules/registry-bucket"
  providers = {
    aws = aws.us-east-1
  }
}
```

**Role Assumption:**
```hcl
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT:role/EKSInfraAdmin"
  }
}
```

**Multiple Providers:**
- AWS (infrastructure)
- Kubernetes (cluster resources)
- Helm (application charts)

### Module Sources

**Public Registry Modules:**
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.20"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"
}
```

**Version Pinning:** `~>` allows minor version upgrades.

**Local Modules:**
```hcl
module "prow_iam" {
  source = "../../modules/eks-prow-iam"
}
```

### Naming Conventions

- **Resources:** Kebab-case (e.g., `prow-build-cluster`)
- **Prefixes:** Environment-based (`prod-`, `test-`)
- **Bucket names:** Service-based (e.g., `artifacts-k8s-io-tfstate`)

### Security Patterns

**Permission Boundaries:**
```hcl
resource "aws_iam_role" "example" {
  name                 = "EKSNodeRole"
  permissions_boundary = aws_iam_policy.boundary.arn
}
```
Prevents privilege escalation even if role is compromised.

**OIDC Federation:**
```hcl
# Trust GCP service accounts
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gcp.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "container.googleapis.com:sub"
      values   = ["system:serviceaccount:namespace:sa-name"]
    }
  }
}
```
Enables cross-cloud workload identity (GCP Prow → AWS resources).

**Least Privilege Roles:**
- **EKSInfraViewer** - Read-only for monitoring
- **EKSInfraAdmin** - Write access for changes
- Separate roles prevent accidental destructive operations

### Operational Patterns

**Makefiles for Safety:**
```bash
# Instead of: terraform apply
make apply

# Makefile handles:
# - Environment selection (PROW_ENV=prod/canary)
# - Backend configuration
# - Multi-step workflows
# - Prevents common mistakes
```

**GitOps with FluxCD:**
- Kubernetes resources in `prow-build-cluster/resources/`
- Flux automatically syncs from git
- No manual `kubectl apply` needed

---

## Common Workflows

### Deploying to Canary First

Always test in canary before production:

```bash
# 1. Deploy to canary
cd infra/aws/terraform/prow-build-cluster/
PROW_ENV=canary make plan
PROW_ENV=canary make apply

# 2. Verify in canary
kubectl get nodes  # Check cluster health
# Run tests, validate changes

# 3. Deploy to production
PROW_ENV=prod make plan
PROW_ENV=prod make apply
```

### Adding a New S3 Bucket

```bash
cd infra/aws/terraform/artifacts.k8s.io/

# Edit s3_buckets.tf
cat >> s3_buckets.tf <<EOF
resource "aws_s3_bucket" "new_bucket" {
  bucket = "\${var.prefix}new-bucket-name"

  tags = {
    Purpose     = "Store new artifacts"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "new_bucket" {
  bucket = aws_s3_bucket.new_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "new_bucket" {
  bucket = aws_s3_bucket.new_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
EOF

# Plan and apply
terraform plan -var prefix=test-
terraform apply -var prefix=test-
```

### Updating EKS Cluster Version

```bash
cd infra/aws/terraform/prow-build-cluster/

# Edit locals.tf or variables.tf
# Update cluster_version = "1.31"

# Test in canary
PROW_ENV=canary make plan
# Review upgrade plan carefully!
PROW_ENV=canary make apply

# Monitor canary cluster
kubectl get nodes -o wide
# Verify applications still work

# Apply to production
PROW_ENV=prod make plan
PROW_ENV=prod make apply
```

---

## Beginner Gotchas

### 1. Multi-Phase EKS Provisioning

**Gotcha:** Can't create EKS cluster in one Terraform run.

**Why:** Terraform can't plan Kubernetes resources before cluster exists.

**Solution:** Follow 4-phase process (see prow-build-cluster section above).

### 2. State File Isolation

**Gotcha:** Each deployment has its own state in different S3 buckets.

**Impact:** Running `terraform apply` in wrong directory won't affect other infrastructure, but you must navigate to the correct deployment.

**Check:** Always verify working directory before running Terraform commands.

### 3. Role Assumption Required

**Gotcha:** Cannot directly access AWS resources without assuming IAM roles.

**Solution:**
```bash
# Configure SSO
aws sso login

# Or assume role manually
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/EKSInfraAdmin \
  --role-session-name my-session
```

### 4. Provider Alias Pattern

**Gotcha:** artifacts.k8s.io uses 18+ regional providers with aliases.

**Symptoms:**
```
Warning: Provider aws.us-west-2 is declared but not used
```

**Solution:** These warnings are expected and can be ignored (see root README.md).

### 5. Prefix-Based Environments

**Gotcha:** artifacts.k8s.io uses variable prefixes instead of workspaces.

**Risk:** Forgetting `-var prefix=prod-` could apply test config to prod!

**Solution:** Always specify prefix explicitly:
```bash
terraform apply -var prefix=prod-
```

### 6. Makefile Abstractions

**Gotcha:** prow-build-cluster and cdn.packages.k8s.io hide complexity behind Makefiles.

**Don't:**
```bash
terraform apply  # Direct command
```

**Do:**
```bash
make apply       # Uses Makefile
```

**Why:** Makefiles handle environment selection, backend config, multi-step workflows.

### 7. Version Differences

**Gotcha:** Different deployments require different Terraform/provider versions:
- Terraform: ~> 1.1 to ~> 1.6
- AWS Provider: ~> 4.52 to ~> 6.16

**Impact:** Cannot use single Terraform version for all deployments.

**Solution:** Use `tfenv` to manage multiple Terraform versions:
```bash
brew install tfenv
cd <deployment-directory>
tfenv install       # Installs version from versions.tf
tfenv use           # Switches to required version
```

### 8. Canary vs Production Confusion

**Gotcha:** Canary is a separate AWS account, NOT connected to Prow control plane.

**Accounts:**
- Production: k8s-infra-prow (468814281478)
- Canary: k8s-infra-prow-canary (054318140392)

**Purpose:** Canary validates infrastructure changes ONLY, doesn't run actual Prow jobs.

### 9. Legacy Deployments

**Gotcha:** Some directories are legacy and may not be actively used.

**Examples:**
- registry.k8s.io-prod (replaced by GCP OCI proxy)

**Solution:** Always read README.md to confirm deployment status.

### 10. OIDC Federation Complexity

**Gotcha:** IAM roles trust GCP service accounts, not AWS principals.

**Example:**
```hcl
# Trust policy references GCP, not AWS
principal {
  type = "Federated"
  identifiers = ["container.googleapis.com"]
}
```

**Why:** Cross-cloud workload identity for Prow (GCP) → AWS resources.

---

## AWS Account Structure

```
k8s-infra (AWS Organization)
├── management-account (root)
├── audit-account (security/compliance)
├── k8s-infra-prow (production build cluster)
├── k8s-infra-prow-canary (canary build cluster)
├── policy-staging-account-1 (policy testing)
├── k8s-infra-kops-* (kops testing accounts)
└── boskos-managed-accounts (e2e test accounts)
```

---

## Best Practices

### DO ✅

- **Test in canary first** - Always validate in canary before production
- **Use Makefiles** - They prevent common mistakes
- **Specify prefixes explicitly** - Don't rely on defaults
- **Read deployment READMEs** - Each has specific instructions
- **Check AWS account** - Verify you're in correct account
- **Use permission boundaries** - Limit blast radius
- **Enable versioning** - On all S3 buckets
- **Tag everything** - For cost tracking and organization

### DON'T ❌

- **Skip canary** - Always test infrastructure changes
- **Use direct terraform commands** - Use Makefiles when provided
- **Forget prefixes** - Could apply wrong config to prod
- **Assume single-phase deployment** - EKS needs multi-phase
- **Ignore provider warnings** - Read them, some are expected
- **Modify legacy deployments** - Check if still in use first
- **Hardcode account IDs** - Use variables
- **Create resources manually** - Everything must be in Terraform

---

## Monitoring & Cost

### Cost Dashboards

**Public billing report:** [Kubernetes Infrastructure Costs](https://datastudio.google.com/u/0/reporting/14UWSuqD5ef9E4LnsCD9uJWTPv8MHOA3e)

Accessible to sig-k8s-infra@kubernetes.io members.

### CloudWatch Alarms

Most deployments include CloudWatch alarms for:
- Budget thresholds
- Health check failures
- Resource utilization

### Cost Optimization

- **CloudFront CDN** - Reduces S3 data transfer costs
- **S3 lifecycle policies** - Transition old data to cheaper storage classes
- **Spot instances** - Used for non-critical workloads
- **Multi-region replication** - Only for critical data

---

## Access & Permissions

### Getting Access

1. **Join sig-k8s-infra** - Attend meetings, contribute
2. **Request access** - Ask in #sig-k8s-infra Slack
3. **SSO setup** - Via Okta (for approved contributors)

### Access Patterns

**Read-only:**
- EKSInfraViewer role
- View cluster status, logs, metrics
- Cannot make changes

**Admin:**
- EKSInfraAdmin role
- Full cluster management
- Can deploy resources, modify configuration

**Terraform applies:**
- Handled by Atlantis (CI/CD automation)
- Manual applies require explicit approval

---

## Next Steps

- **Explore specific deployments** - Navigate to `infra/aws/terraform/<deployment>/` and read README.md
- **Learn Terraform patterns** - Study existing configurations
- **Test in canary** - Try making a small change in canary environment
- **Review IAM module** - Understand permission structure in `modules/eks-prow-iam/`
- **Check other cloud providers** - Compare patterns with [GCP](gcp.md) and [Azure](azure.md)

---

**Related:**
- [GCP Infrastructure](gcp.md) - Google Cloud Platform
- [Making Changes](../03-development/making-changes.md) - Workflow guide
- [Terraform Basics](../01-getting-started/terraform-basics.md) - Fundamentals
