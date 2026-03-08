# Repository Overview

**In this guide:** Understand the architecture, purpose, and organization of the k8s.io infrastructure repository.

**Time to read:** ~10 minutes

**Prerequisites:** Basic understanding of Kubernetes concepts

---

## What This Repository Manages

This repository (`kubernetes/k8s.io`) contains the **infrastructure-as-code** for the Kubernetes project's production infrastructure. It manages:

- **Hosting infrastructure** for official Kubernetes websites and services
- **Artifact storage** for Kubernetes releases and binaries
- **CI/CD infrastructure** (Prow build clusters and test resources)
- **Container registries** for official Kubernetes images
- **DNS management** for kubernetes.io and k8s.io domains
- **CDN configuration** for fast global content delivery

**Who manages this:** The Kubernetes [sig-k8s-infra](https://github.com/kubernetes/community/tree/master/sig-k8s-infra) (Special Interest Group for Infrastructure)

## Multi-Cloud Architecture

Unlike most infrastructure repositories that use a single cloud provider, Kubernetes infrastructure spans **five cloud platforms**:

| Provider | Primary Purpose |
|----------|-----------------|
| **AWS** | Artifact storage, CDN, container registry, CI/CD build clusters |
| **GCP** | Kubernetes cluster hosting, artifact storage, core infrastructure |
| **Azure** | Storage and disaster recovery |
| **Fastly** | CDN for fast global content delivery |
| **IBM Cloud** | Hybrid cloud testing infrastructure |

**Why multi-cloud?**
- **Vendor neutrality**: Kubernetes is a CNCF project and shouldn't depend on one vendor
- **Redundancy**: Critical services have backups across providers
- **Testing**: Ensure Kubernetes works well on all major cloud platforms
- **Cost optimization**: Use each provider's strengths cost-effectively

## Repository Structure

```
k8s.io/
├── apps/              # Applications running on Kubernetes clusters
├── artifacts/         # Binaries and release artifacts
├── audit/             # Infrastructure audit exports
├── dns/               # DNS zone files for *.k8s.io domains
├── docs/              # This documentation!
├── groups/            # Google Groups management
├── hack/              # Development scripts and utilities
├── images/            # Container images for infrastructure tools
├── infra/             # Cloud provider infrastructure (Terraform)
│   ├── aws/           # AWS infrastructure
│   ├── azure/         # Azure infrastructure
│   ├── fastly/        # Fastly CDN configuration
│   ├── gcp/           # GCP infrastructure
│   └── ibmcloud/      # IBM Cloud infrastructure
├── kubernetes/        # Kubernetes manifests for managed clusters
├── policy/            # Open Policy Agent policies for validation
└── registry.k8s.io/   # Container registry infrastructure
```

### Key Directories Explained

#### `apps/` - Community Applications
Kubernetes manifests for applications running on community-managed clusters:
- **codesearch** ([cs.k8s.io](https://cs.k8s.io)) - Code search across Kubernetes repositories
- **gcsweb** ([gcsweb.k8s.io](https://gcsweb.k8s.io)) - Web browser for Google Cloud Storage buckets
- **slack-infra** ([slack.k8s.io](https://slack.k8s.io)) - Slack invitation service
- **elekto** ([elections.k8s.io](https://elections.k8s.io)) - Community elections platform
- **publishing-bot** - Automates publishing of Kubernetes repositories
- **perfdash** - Performance testing dashboard

These applications support Kubernetes development and community operations.

#### `infra/` - Cloud Infrastructure
**This is where Terraform lives!** Each subdirectory contains infrastructure-as-code for one cloud provider:

```
infra/
├── aws/terraform/         # All AWS infrastructure
├── azure/terraform/       # All Azure infrastructure
├── fastly/terraform/      # CDN configuration
├── gcp/terraform/         # All GCP infrastructure
│   ├── bash/              # Helper scripts for GCP
│   └── terraform/         # Terraform configurations
└── ibmcloud/terraform/    # IBM Cloud infrastructure
```

This is the primary area you'll work in when making infrastructure changes.

#### `kubernetes/` - Cluster Configurations
Kubernetes manifests for infrastructure clusters, often using GitOps patterns with ArgoCD:
- Cluster definitions
- Application deployments via ApplicationSets
- Helm charts for common services (cert-manager, external-secrets, etc.)

#### `dns/` - DNS Management
Zone files and configuration for:
- `kubernetes.io` domain
- `k8s.io` domain and all subdomains

DNS changes here propagate to production DNS servers.

#### `policy/` - Infrastructure Validation
[Open Policy Agent](https://www.openpolicyagent.org) (OPA) policies used with [conftest](https://www.conftest.dev) to validate:
- Terraform configurations before apply
- Kubernetes manifests before deployment
- Security and compliance requirements

Think of these as automated guardrails preventing misconfigurations.

#### `registry.k8s.io/` - Container Registry
Infrastructure supporting the official Kubernetes container registry at `registry.k8s.io`, which replaced the legacy `k8s.gcr.io` registry.

#### `artifacts/` - Release Artifacts
Configuration for hosting Kubernetes release artifacts:
- Binary releases (kubectl, kubeadm, etc.)
- Release notes and changelogs
- SHA checksums for verification

Served from `artifacts.k8s.io`.

## Infrastructure Automation

### Atlantis - Terraform Automation
This repository uses [Atlantis](https://www.runatlantis.io) to automate Terraform workflows:

1. You open a Pull Request with Terraform changes
2. Atlantis automatically runs `terraform plan` and comments the results
3. Reviewers can see exactly what infrastructure will change
4. After approval, comment `atlantis apply` to apply changes
5. Atlantis runs `terraform apply` and reports results

This prevents anyone from making undocumented infrastructure changes.

### GitOps with ArgoCD
Kubernetes application deployments use GitOps principles:
- Changes merged to this repository automatically deploy to clusters
- ArgoCD continuously syncs cluster state with git state
- No manual `kubectl apply` needed

## How Changes Work

### Terraform Changes (Infrastructure)
```
1. Find the relevant directory (e.g., infra/aws/terraform/prow-build-cluster/)
2. Make changes to .tf files
3. Open a Pull Request
4. Atlantis runs `terraform plan` automatically
5. Review the plan output in PR comments
6. Get approval from OWNERS
7. Comment `atlantis apply` to execute changes
8. Atlantis applies and reports results
```

### Kubernetes Manifest Changes (Applications)
```
1. Find the relevant directory (e.g., apps/codesearch/ or kubernetes/)
2. Modify Kubernetes YAML files
3. Run validation: conftest test <file>
4. Open a Pull Request
5. Get approval from OWNERS
6. Merge PR
7. ArgoCD automatically deploys changes
```

### DNS Changes
```
1. Edit zone files in dns/
2. Open a Pull Request
3. Get approval from OWNERS
4. Merge PR
5. DNS automation propagates changes
```

## Important Principles

### 1. Everything is Code
All infrastructure is defined in this repository. No manual changes in cloud consoles.

**Why:**
- Changes are version controlled
- Changes are reviewed before applying
- Infrastructure is reproducible
- Documentation is always up-to-date

### 2. Review Before Apply
No infrastructure changes happen without:
- Code review by OWNERS
- Automated validation (policy checks)
- Terraform plan review (for infrastructure)

**Why:** Production infrastructure mistakes are expensive and disruptive.

### 3. Principle of Least Privilege
Access is granted at the minimum level needed:
- Most contributors can propose changes (PRs)
- Fewer people can approve changes (OWNERS)
- Very few people have direct cloud access

**Why:** Reduces blast radius of mistakes or compromised accounts.

### 4. Multi-Cloud Redundancy
Critical services have backups across cloud providers.

**Example:** Kubernetes release artifacts are stored in:
- AWS S3
- Google Cloud Storage
- Served via multiple CDNs

**Why:** If one provider has an outage, Kubernetes users aren't blocked.

## Ownership Model

### ⚠️ Privilege Levels

This repository has multiple privilege levels:
- **Anyone**: Can fork, open PRs, propose changes
- **Reviewers**: Can give technical review (`/lgtm`)
- **Approvers**: Can approve changes (`/approve`)
- **SIG Members**: Limited cloud console access
- **SIG Leads**: Can create accounts, modify org settings

**Most operations require OWNERS approval.** Some operations (creating cloud accounts, modifying organization settings, core DNS changes) require **sig-k8s-infra lead approval**.

**📖 See [Privilege Requirements](../05-contributing/privilege-requirements.md) for complete details.**

### OWNERS Files
Each directory has an `OWNERS` file listing who can approve changes:

```yaml
# kubernetes/apps/codesearch/OWNERS
approvers:
  - sig-k8s-infra-leads
reviewers:
  - codesearch-maintainers
```

**Approval flow:**
1. Submit PR
2. Request review from appropriate OWNERS
3. Address feedback
4. Get approval (`/lgtm` and `/approve` comments)
5. PR merges automatically

### SIG Responsibility
Different SIGs (Special Interest Groups) own different infrastructure:
- **sig-k8s-infra**: Core infrastructure, cloud resources
- **sig-testing**: Prow CI/CD, test infrastructure
- **sig-release**: Artifact storage, release infrastructure
- **sig-contributor-experience**: Community services (Slack, elections)

Check `OWNERS` files to find the right reviewers.

## Security & Compliance

### Secrets Management
**Never commit secrets to this repository!**

Secrets are managed via:
- **External Secrets Operator**: Fetches secrets from cloud secret managers
- **Environment variables**: For local development
- **Cloud IAM**: Service accounts and workload identity

### Audit Trail
All infrastructure changes have:
- Git commit history (who, what, when, why)
- PR review discussions (why decisions were made)
- Atlantis execution logs (what actually happened)

### Policy Enforcement
Before merging, code must pass:
- Terraform validation (`terraform validate`)
- Policy checks (`conftest test`)
- Security scans
- Peer review

## Common Workflows

### "I want to add a new S3 bucket"
1. Go to `infra/aws/terraform/<relevant-directory>/`
2. Add resource in a `.tf` file
3. Run locally: `terraform plan` (optional, Atlantis will do this)
4. Open PR
5. Review Atlantis plan output
6. Get OWNERS approval
7. Apply via Atlantis

### "I want to deploy a new application"
1. Create directory in `apps/<app-name>/`
2. Add Kubernetes manifests
3. Add `OWNERS` file
4. Test locally: `kubectl apply --dry-run=client`
5. Open PR
6. Get approval
7. Merge - ArgoCD deploys automatically

### "I want to change DNS"
1. Edit `dns/zone-configs/`
2. Validate syntax
3. Open PR
4. Get approval
5. Merge - DNS updates propagate

## Monitoring & Observability

Infrastructure health is monitored via:
- **Cost dashboards**: [Public billing report](https://datastudio.google.com/u/0/reporting/14UWSuqD5ef9E4LnsCD9uJWTPv8MHOA3e)
- **Prow dashboard**: [prow.k8s.io](https://prow.k8s.io)
- **ArgoCD**: GitOps deployment status
- **Testgrid**: [testgrid.k8s.io](https://testgrid.k8s.io) - CI test results

## Getting Help

- **Slack**: [#sig-k8s-infra](https://kubernetes.slack.com/messages/sig-k8s-infra)
- **Mailing list**: [sig-k8s-infra@kubernetes.io](https://groups.google.com/a/kubernetes.io/g/sig-k8s-infra)
- **Community**: [SIG K8s Infra meetings](https://github.com/kubernetes/community/tree/master/sig-k8s-infra#meetings)

## Key Takeaways

1. This repository manages **production Kubernetes project infrastructure**
2. Infrastructure spans **five cloud providers** for redundancy and neutrality
3. **Everything is code** - no manual cloud console changes
4. Changes require **review and approval** via OWNERS
5. **Automation** handles applying changes (Atlantis for Terraform, ArgoCD for K8s)
6. Different **SIGs own different parts** of the infrastructure

---

**Next Steps:**
- Read about specific cloud providers in [Cloud Providers](../02-cloud-providers/)
- Set up your local environment: [Setup Guide](setup.md)
- Learn how to read Terraform code: [Reading Terraform](../03-development/reading-terraform.md)
