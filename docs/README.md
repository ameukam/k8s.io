# Kubernetes Infrastructure Documentation

Welcome to the Kubernetes infrastructure documentation! This guide helps you understand, navigate, and contribute to the k8s.io repository - the infrastructure-as-code that powers Kubernetes project infrastructure across multiple cloud providers.

## 📚 Documentation Structure

### 🚀 Getting Started
Perfect if you're new to this repository or infrastructure-as-code:

- **[Repository Overview](01-getting-started/repository-overview.md)** - Understand the architecture and what this repo manages
- **[Terraform Basics](01-getting-started/terraform-basics.md)** - Learn Terraform fundamentals from scratch
- **[Setup Guide](01-getting-started/setup.md)** - Get your local environment ready

### ☁️ Cloud Providers
Deep dives into each cloud platform used:

- **[AWS](02-cloud-providers/aws.md)** - Amazon Web Services infrastructure
- **[GCP](02-cloud-providers/gcp.md)** - Google Cloud Platform infrastructure
- **[Azure](02-cloud-providers/azure.md)** - Microsoft Azure infrastructure
- **[Fastly](02-cloud-providers/fastly.md)** - CDN configuration
- **[IBM Cloud](02-cloud-providers/ibmcloud.md)** - IBM Cloud infrastructure

### 💻 Development
Hands-on guides for working with this codebase:

- **[Reading Terraform](03-development/reading-terraform.md)** - How to understand .tf files
- **[Making Changes](03-development/making-changes.md)** - Workflow for modifications
- **[Testing](03-development/testing.md)** - Testing infrastructure changes safely
- **[Common Patterns](03-development/common-patterns.md)** - Reusable patterns in this repo

### 📖 Reference
Look up specific information:

- **[Directory Structure](04-reference/directory-structure.md)** - Complete directory guide
- **[Glossary](04-reference/glossary.md)** - Terms, acronyms, and concepts
- **[Troubleshooting](04-reference/troubleshooting.md)** - Common issues and solutions

### 🤝 Contributing
Ready to contribute?

- **[Contribution Workflow](05-contributing/contribution-workflow.md)** - Step-by-step guide
- **[Review Process](05-contributing/review-process.md)** - What to expect in code review
- **[Privilege Requirements](05-contributing/privilege-requirements.md)** - ⚠️ What you can do and what needs approval

## 🎯 Quick Start Paths

### "I've never used Terraform before"
1. Read [Terraform Basics](01-getting-started/terraform-basics.md)
2. Read [Repository Overview](01-getting-started/repository-overview.md)
3. Follow the [Setup Guide](01-getting-started/setup.md)
4. Try [Reading Terraform](03-development/reading-terraform.md)

### "I know Terraform but not this repo"
1. Read [Repository Overview](01-getting-started/repository-overview.md)
2. Skim the cloud provider docs for platforms you'll work with
3. Review [Common Patterns](03-development/common-patterns.md)
4. Check [Contribution Workflow](05-contributing/contribution-workflow.md)

### "I want to fix something specific"
1. Find the relevant cloud provider in [Cloud Providers](#️-cloud-providers)
2. Read [Making Changes](03-development/making-changes.md)
3. Follow [Contribution Workflow](05-contributing/contribution-workflow.md)

### "I'm just exploring"
Start with [Repository Overview](01-getting-started/repository-overview.md) to understand what this infrastructure powers, then follow your curiosity!

## 💡 About This Documentation

This documentation assumes you:
- Are comfortable with software development concepts
- Understand Kubernetes basics (pods, deployments, services)
- Have zero experience with Terraform (we'll teach you!)
- Have zero experience with cloud providers (we'll explain!)

**⚠️ Important:** Most infrastructure operations require OWNERS approval or sig-k8s-infra lead approval. See [Privilege Requirements](05-contributing/privilege-requirements.md) to understand what you can do independently versus what needs elevated approval.

## 🆘 Getting Help

- **Documentation Issues**: If something is unclear or wrong, [open an issue](https://github.com/kubernetes/k8s.io/issues)
- **Infrastructure Questions**: Join the [#sig-k8s-infra](https://kubernetes.slack.com/messages/sig-k8s-infra) Slack channel
- **General Contribution Help**: See the main [CONTRIBUTING.md](../CONTRIBUTING.md) in the repository root

## 📝 Contributing to These Docs

Found a typo? Want to improve an explanation? Documentation contributions are welcome! These docs live in the `docs/` directory and are written in Markdown.

---

**Next Steps:** Start with [Repository Overview](01-getting-started/repository-overview.md) to understand what infrastructure this repository manages.
