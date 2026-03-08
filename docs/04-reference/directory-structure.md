# Directory Structure Reference

**Complete guide to the repository's directory layout and organization.**

---

## Top-Level Structure

```
k8s.io/
├── apps/              # Kubernetes applications
├── apt/               # APT repository management
├── artifacts/         # Release artifacts configuration
├── audit/             # Infrastructure audit exports
├── dns/               # DNS zone management
├── docs/              # Documentation (you are here!)
├── groups/            # Google Groups management
├── hack/              # Development and utility scripts
├── images/            # Container images for infra tools
├── infra/             # Cloud infrastructure (Terraform)
├── kubernetes/        # Kubernetes cluster configurations
├── policy/            # OPA policy validation
└── registry.k8s.io/   # Container registry infrastructure
```

---

## `/apps` - Community Applications

Kubernetes manifests for applications running on community-managed clusters.

```
apps/
├── cert-manager/              # Certificate management
├── codesearch/                # Code search (cs.k8s.io)
├── elekto/                    # Elections platform (elections.k8s.io)
├── gcsweb/                    # GCS web browser (gcsweb.k8s.io)
├── k8s-io/                    # Nginx reverse proxy for k8s.io
├── kettle/                    # CI/CD metrics collection
├── kubernetes-external-secrets/ # Secret synchronization
├── perfdash/                  # Performance dashboard
├── publishing-bot/            # Repository publishing automation
├── slack-infra/               # Slack integration (slack.k8s.io)
└── triageparty-cli/           # Issue triage tool
```

**Each app directory contains:**
- Kubernetes manifests (Deployments, Services, etc.)
- ConfigMaps for application configuration
- OWNERS file for approval authority

---

## `/infra` - Cloud Infrastructure

### Overview

```
infra/
├── aws/         # Amazon Web Services
├── azure/       # Microsoft Azure
├── fastly/      # Fastly CDN
├── gcp/         # Google Cloud Platform
└── ibmcloud/    # IBM Cloud
```

### `/infra/aws` - AWS Infrastructure

```
aws/
├── aws-costexplorer-export/   # Cost analysis automation
├── cloudformation/            # Legacy CloudFormation (deprecated)
└── terraform/                 # Terraform configurations
    ├── artifacts.k8s.io/      # Artifact storage and CDN
    ├── audit-account/         # Security and compliance account
    ├── cdn.packages.k8s.io/   # Package distribution CDN
    ├── cncf-k8s-infra-aws-capa-ami/ # Cluster API AMI management
    ├── iam/                   # IAM roles and policies
    ├── infrastructure-services/ # Shared infrastructure services
    ├── kops-infra-ci/         # Kops testing infrastructure
    ├── management-account/    # AWS Organizations management
    ├── modules/               # Reusable Terraform modules
    ├── policy-staging-account-1/ # Policy testing environment
    ├── prow-build-cluster/    # Prow CI/CD cluster
    └── registry-k8s-io-prod/  # Container registry infrastructure
```

**Key AWS directories:**
- **prow-build-cluster/** - EKS cluster for running CI/CD jobs
- **registry-k8s-io-prod/** - Infrastructure for registry.k8s.io
- **artifacts.k8s.io/** - S3 and CloudFront for release artifacts
- **modules/** - Reusable Terraform modules for consistency

### `/infra/gcp` - GCP Infrastructure

```
gcp/
├── bash/                      # Helper scripts
│   ├── namespaces/            # Kubernetes namespace management
│   ├── prow/                  # Prow project management
│   └── roles/                 # Custom GCP IAM roles
├── static/                    # Static configurations
└── terraform/                 # Terraform configurations
    ├── k8s-infra-*/           # Various GCP projects
    ├── modules/               # Reusable Terraform modules
    └── projects/              # GCP project configurations
```

**Key GCP directories:**
- **terraform/projects/** - GCP project configurations
- **bash/namespaces/** - Scripts for managing K8s namespaces
- **bash/prow/** - Boskos resource management for testing

### `/infra/azure` - Azure Infrastructure

```
azure/
├── bash/                      # Helper scripts
└── terraform/                 # Terraform configurations
```

Azure infrastructure is smaller in scope, primarily used for redundancy and testing.

### `/infra/fastly` - Fastly CDN

```
fastly/
└── terraform/                 # Fastly CDN configuration
```

Manages Fastly CDN services for:
- Fast global content delivery
- DDoS protection
- Traffic routing

### `/infra/ibmcloud` - IBM Cloud

```
ibmcloud/
└── terraform/                 # IBM Cloud configurations
```

Infrastructure for testing Kubernetes on IBM Cloud platform.

---

## `/kubernetes` - Cluster Configurations

GitOps configurations for Kubernetes clusters managed by ArgoCD.

```
kubernetes/
├── apps/                      # Application deployments
│   ├── argocd.yaml            # Bootstrap ArgoCD
│   ├── cert-manager.yaml      # Certificate management
│   ├── external-secrets.yaml  # Secret synchronization
│   ├── istio.yaml             # Service mesh
│   └── kustomization.yaml     # Kustomize configuration
└── gke-utility/               # GKE cluster configuration
    ├── argocd/                # ArgoCD config
    │   ├── argocd-cmd-params-cm.yaml
    │   ├── clusters.yaml       # Managed clusters
    │   └── extras.yaml
    ├── helm/                  # Helm values
    │   ├── cert-manager.yaml
    │   ├── external-secrets.yaml
    │   └── ...
    └── namespace/             # Namespace definitions
```

**Pattern: ApplicationSets**
- `apps/` directory contains ArgoCD ApplicationSets
- Each ApplicationSet deploys applications to multiple clusters
- `gke-utility/` contains cluster-specific configurations

---

## `/dns` - DNS Management

```
dns/
├── zone-configs/              # DNS zone files
│   ├── k8s.io.yaml
│   └── kubernetes.io.yaml
└── scripts/                   # DNS management automation
```

**Managed zones:**
- `kubernetes.io` - Primary domain
- `k8s.io` - Short domain for services

**Subdomains include:**
- `artifacts.k8s.io` - Release artifacts
- `registry.k8s.io` - Container registry
- `prow.k8s.io` - CI/CD dashboard
- `testgrid.k8s.io` - Test result dashboard

---

## `/policy` - OPA Policies

```
policy/
├── terraform/                 # Terraform validation policies
│   ├── aws/                   # AWS-specific policies
│   ├── gcp/                   # GCP-specific policies
│   └── common/                # Cross-cloud policies
└── kubernetes/                # Kubernetes manifest policies
```

**Purpose:**
- Validate Terraform configurations before apply
- Enforce security best practices
- Prevent common misconfigurations

**Usage:** `conftest test <file>` runs policy checks

---

## `/registry.k8s.io` - Container Registry

```
registry.k8s.io/
├── manifests/                 # Registry manifests
├── terraform/                 # Registry infrastructure
└── docs/                      # Registry documentation
```

Infrastructure supporting the official Kubernetes container registry that replaced `k8s.gcr.io`.

---

## `/artifacts` - Release Artifacts

```
artifacts/
├── binaries/                  # Binary release configurations
├── manifests/                 # Kubernetes manifests
└── terraform/                 # Artifact storage infrastructure
```

Configuration for hosting:
- `kubectl` binaries
- `kubeadm`, `kubelet` binaries
- Release notes and checksums

Served from `artifacts.k8s.io`.

---

## `/groups` - Google Groups

```
groups/
├── groups.yaml                # Group definitions
└── sig-*/                     # SIG-specific groups
```

Manages Google Groups for:
- Mailing lists
- Access control
- Team collaboration

---

## `/images` - Container Images

```
images/
├── builder/                   # Build infrastructure images
├── kas-network-proxy/         # Kubernetes API server proxy
└── ...
```

Container images for infrastructure tools, published to `gcr.io/k8s-staging-infra-tools`.

---

## `/hack` - Utility Scripts

```
hack/
├── verify/                    # Validation scripts
├── update/                    # Update automation
└── testing/                   # Test utilities
```

Development and maintenance scripts:
- Code validation
- Automated updates
- Testing utilities

---

## Common File Patterns

### OWNERS Files
Nearly every directory has an `OWNERS` file:

```yaml
approvers:
  - sig-k8s-infra-leads
reviewers:
  - team-members
```

Defines who can approve changes to that directory.

### README.md Files
Most directories include documentation:
- Purpose of the directory
- How to use the code
- Prerequisites and dependencies
- Special considerations

### Terraform Structure
Terraform directories typically contain:
```
<directory>/
├── main.tf           # Primary resources
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── providers.tf      # Provider configuration
├── terraform.tf      # Backend and version constraints
├── versions.tf       # Provider version requirements
└── README.md         # Documentation
```

### Kubernetes Manifests
Application directories contain:
```
<app>/
├── deployment.yaml       # Workload definition
├── service.yaml          # Network exposure
├── configmap.yaml        # Configuration data
├── ingress.yaml          # External access
└── OWNERS                # Approval authority
```

---

## Navigation Tips

### Finding Infrastructure Code

**By Cloud Provider:**
```
infra/<provider>/terraform/
```

**By Purpose:**
- Artifact storage → `infra/aws/terraform/artifacts.k8s.io/`
- CI/CD cluster → `infra/aws/terraform/prow-build-cluster/`
- Container registry → `infra/aws/terraform/registry-k8s-io-prod/`
- GCP projects → `infra/gcp/terraform/projects/`

### Finding Applications

**By Application Name:**
```
apps/<app-name>/
```

**By Purpose:**
- Code search → `apps/codesearch/`
- Slack integration → `apps/slack-infra/`
- Elections → `apps/elekto/`

### Finding DNS Records

```
dns/zone-configs/<domain>.yaml
```

### Finding Policies

```
policy/<type>/<provider>/
```

Examples:
- `policy/terraform/aws/` - AWS Terraform policies
- `policy/kubernetes/` - Kubernetes manifest policies

---

## Size and Complexity Guide

| Directory | Complexity | Frequency of Changes |
|-----------|------------|---------------------|
| `/infra/aws/terraform/` | High | Medium |
| `/infra/gcp/terraform/` | High | Medium |
| `/apps/` | Medium | High |
| `/dns/` | Low | Low |
| `/policy/` | Medium | Low |
| `/kubernetes/` | Medium | Medium |
| `/groups/` | Low | Low |

**Beginner-friendly starting points:**
- `/apps/` - Kubernetes manifests are easier to understand
- `/dns/` - Simple YAML configurations
- `/policy/` - Small, focused policy files

**Advanced areas:**
- `/infra/*/terraform/modules/` - Reusable Terraform modules
- `/infra/gcp/bash/` - Complex bash scripting
- `/kubernetes/apps/` - ArgoCD ApplicationSets with templating

---

## Finding Relevant Code

### By Service
| Service | Location |
|---------|----------|
| artifacts.k8s.io | `infra/aws/terraform/artifacts.k8s.io/` |
| registry.k8s.io | `infra/aws/terraform/registry-k8s-io-prod/` |
| prow.k8s.io | `infra/aws/terraform/prow-build-cluster/` |
| cs.k8s.io (codesearch) | `apps/codesearch/` |
| gcsweb.k8s.io | `apps/gcsweb/` |

### By Infrastructure Type
| Type | Location |
|------|----------|
| S3 buckets | `infra/aws/terraform/**/s3*.tf` |
| GCS buckets | `infra/gcp/terraform/**/storage*.tf` |
| Kubernetes clusters | `infra/*/terraform/**/*eks*.tf` or `*gke*.tf` |
| IAM roles/policies | `infra/*/terraform/**/iam*.tf` |
| DNS records | `dns/zone-configs/*.yaml` |

---

**Next Steps:**
- Browse specific cloud provider docs: [Cloud Providers](../02-cloud-providers/)
- Learn to read Terraform: [Reading Terraform](../03-development/reading-terraform.md)
- Understand repository purpose: [Repository Overview](../01-getting-started/repository-overview.md)
