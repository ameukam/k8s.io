# Glossary

**Quick reference for terms, acronyms, and concepts used in this repository.**

---

## Infrastructure & Cloud Terms

### IaC (Infrastructure as Code)
Managing infrastructure through code files rather than manual configuration. Terraform is an IaC tool.

### Resource
A piece of infrastructure managed by Terraform - like an S3 bucket, VM, DNS record, or IAM role.

### Provider
A Terraform plugin that knows how to interact with a specific cloud service (AWS, GCP, Azure, etc.).

### State
Terraform's record of what infrastructure it has created. Stored in `terraform.tfstate` files, usually in remote storage.

### Module
A reusable package of Terraform code. Like a function in programming that you can call multiple times with different parameters.

### Data Source
A Terraform construct that queries existing infrastructure without creating anything new.

### HCL (HashiCorp Configuration Language)
The language Terraform configuration files are written in. Files end in `.tf`.

### Remote Backend
Storing Terraform state in cloud storage (like S3 or GCS) instead of locally, allowing team collaboration.

### Plan
A preview of changes Terraform will make (via `terraform plan`). Like a diff for infrastructure.

### Apply
Executing infrastructure changes (via `terraform apply`). Actually creates/modifies/destroys resources.

---

## Kubernetes Infrastructure Terms

### SIG (Special Interest Group)
A community group focused on a specific aspect of Kubernetes. Example: `sig-k8s-infra` manages infrastructure.

### Prow
Kubernetes' CI/CD system built on top of Kubernetes itself. Runs tests and automation.

### GKE (Google Kubernetes Engine)
Google Cloud's managed Kubernetes service.

### EKS (Amazon Elastic Kubernetes Service)
AWS's managed Kubernetes service.

### AKS (Azure Kubernetes Service)
Microsoft Azure's managed Kubernetes service.

### Build Cluster
A Kubernetes cluster used for running CI/CD jobs and building artifacts, not for production workloads.

### Registry
A service that stores container images. `registry.k8s.io` is the official Kubernetes container image registry.

---

## AWS-Specific Terms

### S3 (Simple Storage Service)
Object storage service. Used for storing artifacts, binaries, and backups.

### CloudFront
AWS's Content Delivery Network (CDN) for fast global content delivery.

### IAM (Identity and Access Management)
AWS's service for managing permissions and access control.

### EC2 (Elastic Compute Cloud)
AWS's virtual machine service.

### VPC (Virtual Private Cloud)
Isolated network within AWS where resources run.

### IRSA (IAM Roles for Service Accounts)
Kubernetes feature allowing pods to assume AWS IAM roles for access to AWS services.

### Karpenter
Kubernetes node autoscaler for AWS that dynamically provisions EC2 instances based on pod requirements.

### ACM (AWS Certificate Manager)
Service for provisioning and managing SSL/TLS certificates.

### Route 53
AWS's DNS service.

### Organizations
AWS feature for managing multiple AWS accounts under a single umbrella.

---

## GCP-Specific Terms

### GCS (Google Cloud Storage)
Object storage service, similar to AWS S3.

### Cloud CDN
Google Cloud's Content Delivery Network.

### IAM (Identity and Access Management)
GCP's service for permissions and access control (same acronym as AWS, different implementation).

### GCE (Google Compute Engine)
GCP's virtual machine service, similar to EC2.

### Workload Identity
GCP's equivalent to AWS IRSA - allows Kubernetes pods to access GCP services.

### Cloud DNS
GCP's DNS service, similar to Route 53.

### Projects
GCP's organizational unit for grouping resources and billing.

---

## Azure-Specific Terms

### Storage Accounts
Azure's service for blob storage, file shares, queues, and tables.

### Azure CDN
Microsoft Azure's Content Delivery Network.

### Entra ID (formerly Azure AD)
Azure's identity and access management service.

### AKS (Azure Kubernetes Service)
Azure's managed Kubernetes service.

### Resource Groups
Azure's way of organizing related resources together.

---

## CDN & Fastly Terms

### CDN (Content Delivery Network)
A geographically distributed network of servers that cache and serve content from locations close to users.

### Edge Location
A CDN server location that caches content close to end users.

### Origin
The source server that the CDN fetches content from when it's not cached.

### TLS (Transport Layer Security)
Encryption protocol for secure communication (formerly SSL).

---

## Development & Git Terms

### Worktree
A Git feature allowing multiple working directories from one repository, useful for working on multiple branches simultaneously.

### PR (Pull Request)
A request to merge changes from one branch into another, subject to code review.

### OWNERS
A file specifying who can approve changes to specific parts of the codebase.

### Atlantis
An automation tool that runs Terraform commands (plan/apply) in response to pull request comments.

---

## Common Abbreviations

| Abbreviation | Full Term |
|--------------|-----------|
| ACL | Access Control List |
| AMI | Amazon Machine Image |
| ARN | Amazon Resource Name |
| CIDR | Classless Inter-Domain Routing |
| CNCF | Cloud Native Computing Foundation |
| CRD | Custom Resource Definition |
| FQDN | Fully Qualified Domain Name |
| OIDC | OpenID Connect |
| RBAC | Role-Based Access Control |
| SLO | Service Level Objective |
| SSO | Single Sign-On |
| TTL | Time To Live |
| WAF | Web Application Firewall |

---

## Repository-Specific Terms

### aaa cluster
A community-managed Kubernetes cluster that runs various Kubernetes infrastructure applications.

### artifacts.k8s.io
Domain serving Kubernetes release artifacts and binaries.

### gcsweb
A web interface for browsing Google Cloud Storage buckets, running at gcsweb.k8s.io.

### publishing-bot
Automation that publishes Kubernetes repositories to various destinations.

### Boskos
Resource management system for managing test resources in CI/CD.

### Testgrid
Dashboard showing Kubernetes test results across multiple test runs and configurations.

---

## Terraform-Specific Patterns

### Root Module
The directory where you run `terraform` commands. Contains the main configuration.

### Child Module
A module called by another module. Receives inputs via variables, returns outputs.

### Workspace
A way to maintain multiple state files for the same configuration (e.g., dev, staging, prod).

### Lock File
`.terraform.lock.hcl` - Records provider versions to ensure consistent installs.

### Drift
When actual infrastructure differs from what Terraform expects based on its state.

### Import
Bringing existing infrastructure under Terraform management without recreating it.

---

## Need More Info?

- **Terraform**: See [Terraform Basics](../01-getting-started/terraform-basics.md)
- **Cloud Providers**: Check the [Cloud Providers](../02-cloud-providers/) section
- **Repository Structure**: See [Directory Structure](directory-structure.md)
- **General Questions**: Ask in [#sig-k8s-infra Slack](https://kubernetes.slack.com/messages/sig-k8s-infra)

---

**Last Updated:** 2026-03-08
