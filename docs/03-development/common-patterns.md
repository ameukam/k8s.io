# Common Patterns

**Recurring patterns and conventions used throughout this repository.**

---

## Terraform Patterns

### Module Pattern

**What:** Reusable Terraform configurations packaged as modules.

**Location:** `infra/<provider>/terraform/modules/`

**Structure:**
```
modules/my-module/
├── main.tf        # Resources
├── variables.tf   # Inputs
├── outputs.tf     # Outputs
├── versions.tf    # Version constraints
└── README.md      # Documentation
```

**Usage:**
```hcl
module "example" {
  source = "../../modules/my-module"

  input_var = "value"
}

# Reference outputs
resource "aws_iam_role" "example" {
  name = module.example.role_name
}
```

**Benefits:**
- DRY (Don't Repeat Yourself)
- Consistent configuration
- Easier testing and validation

### Multi-Region Pattern

**What:** Deploy same infrastructure across multiple regions.

**Pattern:**
```hcl
# Define providers for each region
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "ap-southeast-1"
  region = "ap-southeast-1"
}

# Instantiate module per region
module "bucket_us_east" {
  source = "./modules/bucket"

  providers = {
    aws = aws.us-east-1
  }
}

module "bucket_ap_southeast" {
  source = "./modules/bucket"

  providers = {
    aws = aws.ap-southeast-1
  }
}
```

**Examples:**
- `artifacts.k8s.io/` - 18+ regional S3 buckets
- `registry.k8s.io/` - Multi-region container storage

### Environment Separation

**Pattern 1: Workspaces**
```bash
# cdn.packages.k8s.io uses workspaces
terraform workspace select prod
terraform apply

terraform workspace select canary
terraform apply
```

**Pattern 2: Variable Prefixes**
```bash
# artifacts.k8s.io uses prefixes
terraform apply -var prefix=prod-
terraform apply -var prefix=test-
```

**Pattern 3: Separate Directories**
```
prow-build-cluster/    # Shared config
├── prod/              # Production-specific
└── canary/            # Canary-specific
```

**When to use:**
- **Workspaces:** Minor config differences
- **Prefixes:** Resource naming variations
- **Directories:** Completely different infrastructure

### Remote State Pattern

**What:** Store Terraform state in cloud storage instead of locally.

**Why:**
- Team collaboration
- State locking (prevents concurrent modifications)
- Backup and recovery

**Configuration:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "path/to/state.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Note:** Each deployment in this repo has its own state bucket.

---

## Kubernetes Patterns

### ApplicationSet Pattern

**What:** ArgoCD ApplicationSets deploy applications to multiple clusters.

**Location:** `kubernetes/apps/`

**Structure:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cert-manager
spec:
  generators:
    - list:
        elements:
          - cluster: gke-utility
            url: https://kubernetes.default.svc
  template:
    spec:
      source:
        repoURL: https://github.com/kubernetes/k8s.io
        path: kubernetes/{{cluster}}/helm/cert-manager.yaml
      destination:
        server: '{{url}}'
```

**Benefits:**
- Deploy to multiple clusters with one definition
- Automatic sync from git (GitOps)
- Centralized application management

### Helm Values Pattern

**What:** Store Helm chart values in git, deployed via ArgoCD.

**Location:** `kubernetes/<cluster>/helm/`

**Structure:**
```yaml
# kubernetes/gke-utility/helm/cert-manager.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cert-manager-helm-values
data:
  values.yaml: |
    installCRDs: true
    replicaCount: 2
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
```

**Benefits:**
- Values in version control
- GitOps deployment
- Easy rollback (revert git commit)

### Extra Objects Pattern

**What:** Add custom Kubernetes resources alongside Helm charts.

**Pattern:**
```yaml
# In Helm values
extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: custom-secret
    stringData:
      key: value
```

**Use cases:**
- ClusterIssuers for cert-manager
- ExternalSecrets for secrets sync
- Custom CRDs specific to deployment

**Example:** `kubernetes/gke-utility/helm/external-secrets.yaml`

### Namespace Organization

**Pattern:**
```
apps/
├── app-name/
│   ├── namespace.yaml     # Namespace definition
│   ├── deployment.yaml    # Workload
│   ├── service.yaml       # Networking
│   ├── ingress.yaml       # External access
│   └── OWNERS             # Approval authority
```

**Benefits:**
- Clear ownership
- Isolated failures
- RBAC per namespace

---

## IAM/RBAC Patterns

### Least Privilege Pattern

**What:** Grant minimum permissions needed.

**Example:**
```hcl
# Viewer role (read-only)
resource "aws_iam_role" "viewer" {
  name = "EKSInfraViewer"

  # Can describe, list, get
  # Cannot create, update, delete
}

# Admin role (full access)
resource "aws_iam_role" "admin" {
  name = "EKSInfraAdmin"

  # Full management permissions
}
```

**Benefits:**
- Reduces blast radius of mistakes
- Limits privilege escalation
- Enables "read-only" access for monitoring

### Permission Boundary Pattern

**What:** Set maximum permissions a role can have, even if policies grant more.

**Example:**
```hcl
resource "aws_iam_role" "node" {
  name                 = "EKSNodeRole"
  permissions_boundary = aws_iam_policy.boundary.arn

  # Even if policies attached later grant more,
  # boundary prevents privilege escalation
}

resource "aws_iam_policy" "boundary" {
  name = "EKSResourcesPermissionBoundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "s3:*"]  # Max allowed
        Resource = "*"
      }
    ]
  })
}
```

**Use case:** Prevent nodes from granting themselves admin access.

### OIDC Federation Pattern

**What:** Allow external workloads to assume AWS IAM roles without static credentials.

**Example:**
```hcl
# Trust GCP service account
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gcp.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "container.googleapis.com:sub"
      values   = [
        "system:serviceaccount:prow:deck"
      ]
    }
  }
}

resource "aws_iam_role" "workload" {
  assume_role_policy = data.aws_iam_policy_document.trust.json
}
```

**Benefits:**
- No static credentials
- Automatic credential rotation
- Cross-cloud identity

**Example:** GCP Prow pods assume AWS IAM roles to access S3.

---

## Security Patterns

### Secrets Management

**Pattern:** Never commit secrets to git.

**Instead:**
```yaml
# Use External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: app-secrets
  data:
    - secretKey: password
      remoteRef:
        key: prod/app/password
```

**Flow:**
1. Store secret in AWS Secrets Manager / GCP Secret Manager
2. ExternalSecret syncs to Kubernetes Secret
3. Application mounts Secret

### S3 Bucket Security Pattern

**What:** Standard security configuration for all S3 buckets.

**Pattern:**
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

# Enable versioning
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**Why:**
- Versioning prevents accidental deletion
- Public access block prevents leaks
- Encryption protects data at rest

---

## Naming Patterns

### Resource Naming

**Convention:** `<project>-<environment>-<purpose>`

**Examples:**
- `prow-build-cluster` - Prow build EKS cluster
- `k8s-artifacts-prod` - Production artifacts bucket
- `eks-infra-admin` - EKS infrastructure admin role

**Rules:**
- Use kebab-case (lowercase with hyphens)
- Be descriptive but concise
- Include environment when multiple exist
- Avoid abbreviations unless obvious (EKS, S3, IAM are OK)

### Tagging Pattern

**What:** Consistent tags on all cloud resources.

**Standard tags:**
```hcl
tags = {
  ManagedBy   = "terraform"
  Project     = "k8s-infra"
  Environment = "production"
  Owner       = "sig-k8s-infra"
  Purpose     = "Artifact storage"
}
```

**Benefits:**
- Cost allocation
- Resource grouping
- Ownership tracking
- Compliance validation

---

## GitOps Patterns

### Git as Single Source of Truth

**Pattern:**
1. All configuration in git
2. Automated deployment from git
3. No manual changes in clusters/cloud

**Tools:**
- **ArgoCD** - Kubernetes applications
- **FluxCD** - Alternative GitOps tool
- **Atlantis** - Terraform automation

**Benefits:**
- Changes are versioned
- Changes are reviewed
- Changes are auditable
- Rollback is easy (git revert)

### Pull Request Workflow

**Pattern:**
1. Create branch
2. Make changes
3. Open PR
4. Automated checks run
5. Peer review
6. Merge
7. Automatic deployment

**Checks:**
- Syntax validation
- Policy enforcement (OPA/Conftest)
- Security scans
- Terraform plan (via Atlantis)

---

## Makefile Pattern

**What:** Wrap complex Terraform workflows in Makefiles.

**Example:**
```makefile
PROW_ENV ?= canary
TF_ARGS ?=

.PHONY: init
init:
    terraform init -backend-config=backend-$(PROW_ENV).hcl

.PHONY: plan
plan: init
    terraform plan $(TF_ARGS)

.PHONY: apply
apply: init
    terraform apply $(TF_ARGS)

.PHONY: clean
clean:
    rm -rf .terraform
```

**Usage:**
```bash
make plan PROW_ENV=prod
make apply PROW_ENV=prod
```

**Benefits:**
- Prevents common mistakes (wrong backend, missing init)
- Consistent interface across deployments
- Environment selection built-in
- Self-documenting commands

**Examples:**
- `prow-build-cluster/Makefile`
- `cdn.packages.k8s.io/Makefile`

---

## Policy Validation Pattern

**What:** Automated policy checks using Open Policy Agent (OPA) and Conftest.

**Location:** `policy/<type>/<provider>/`

**Example Policy:**
```rego
# policy/terraform/aws/s3_encryption.rego
package terraform.s3

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  not resource.server_side_encryption_configuration

  msg := sprintf("S3 bucket '%s' must have encryption enabled", [name])
}
```

**Usage:**
```bash
conftest test infra/aws/terraform/**/*.tf
```

**Benefits:**
- Prevent security misconfigurations
- Enforce compliance
- Automated enforcement (CI checks)
- Self-service validation (test before PR)

---

## Documentation Patterns

### README in Every Directory

**Pattern:** Every infrastructure/app directory has README.md explaining:
- Purpose
- How to deploy
- Prerequisites
- Special considerations

**Benefits:**
- Self-documenting infrastructure
- Onboarding new contributors
- Reduces tribal knowledge

### OWNERS Files

**Pattern:** Every directory has OWNERS defining who can approve changes.

**Format:**
```yaml
approvers:
  - sig-k8s-infra-leads
reviewers:
  - team-members
  - individual-contributor
```

**Benefits:**
- Clear ownership
- Automatic review requests
- Approval automation

---

## Testing Patterns

### Dry-Run Validation

**Kubernetes:**
```bash
kubectl apply --dry-run=client -f manifest.yaml
```

**Terraform:**
```bash
terraform plan  # Shows what would change
```

**Benefits:**
- Catch syntax errors early
- Preview changes before applying
- No side effects (doesn't modify infrastructure)

### Canary Deployment

**Pattern:**
1. Test changes in canary environment
2. Monitor for issues
3. If stable, deploy to production
4. If problems, rollback canary

**Examples:**
- `prow-build-cluster` (prod + canary accounts)
- `cdn.packages.k8s.io` (workspaces)

---

## When to Use Each Pattern

| Pattern | Use When | Don't Use When |
|---------|----------|----------------|
| **Modules** | Repeating configuration 2+ times | One-off resources |
| **Multi-region** | Need global availability | Single region sufficient |
| **Workspaces** | Minor config differences | Completely different infra |
| **Prefixes** | Resource naming varies | Separate environments |
| **ApplicationSet** | Deploy to multiple clusters | Single cluster |
| **Makefiles** | Complex multi-step workflows | Simple `terraform apply` |
| **OIDC** | Cross-cloud workload identity | Same-cloud access |
| **Permission boundaries** | Untrusted roles | Fully trusted admin roles |

---

**Related:**
- [Making Changes](making-changes.md) - Apply these patterns
- [Reading Terraform](reading-terraform.md) - Understand existing patterns
- [AWS Infrastructure](../02-cloud-providers/aws.md) - AWS-specific patterns
