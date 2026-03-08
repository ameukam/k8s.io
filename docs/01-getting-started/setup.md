# Setup Guide

**In this guide:** Get your local environment ready for contributing to k8s.io infrastructure.

**Time to read:** ~15 minutes

**Prerequisites:** Basic command-line familiarity

---

## Overview

Most contributions to this repository don't require extensive local setup. The CI/CD automation (Atlantis, ArgoCD) handles most execution. However, local testing helps catch issues before opening PRs.

## Minimum Setup (Everyone)

### 1. Install Git

**macOS:**
```bash
# Using Homebrew
brew install git

# Or download from https://git-scm.com/
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install git

# Red Hat/CentOS
sudo yum install git
```

**Windows:**
Download from [git-scm.com](https://git-scm.com/download/win)

**Verify:**
```bash
git --version
# Should show: git version 2.x.x
```

### 2. Clone the Repository

```bash
# Fork first on GitHub, then:
git clone https://github.com/<your-username>/k8s.io.git
cd k8s.io
```

### 3. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Use the same email as your GitHub account!**

---

## Optional: Terraform (Infrastructure Changes)

Install Terraform if you want to test infrastructure changes locally.

### Install Terraform

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repo
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install
sudo apt update && sudo apt install terraform
```

**Windows:**
Download from [terraform.io](https://www.terraform.io/downloads)

**Verify:**
```bash
terraform version
# Should show: Terraform v1.x.x
```

### Terraform Version Requirements

This repository requires **Terraform >= 1.0**. Check `versions.tf` files for specific requirements.

```bash
cd infra/aws/terraform/<directory>
cat versions.tf | grep required_version
```

---

## Optional: kubectl (Kubernetes Changes)

Install kubectl if you want to test Kubernetes manifests locally.

### Install kubectl

**macOS:**
```bash
brew install kubectl
```

**Linux:**
```bash
# Download latest release
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Windows:**
Download from [Kubernetes releases](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

**Verify:**
```bash
kubectl version --client
# Should show client version
```

**Note:** You don't need cluster access for basic validation. `kubectl apply --dry-run=client` works without a cluster.

---

## Optional: Validation Tools

### Conftest (Policy Checking)

Conftest validates configurations against Open Policy Agent policies.

**Install:**
```bash
# macOS
brew install conftest

# Linux
wget https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_0.45.0_Linux_x86_64.tar.gz
tar xzf conftest_0.45.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/
```

**Verify:**
```bash
conftest --version
```

**Usage:**
```bash
# Test Terraform
conftest test infra/aws/terraform/<dir>/*.tf

# Test Kubernetes
conftest test apps/<app>/*.yaml
```

### yamllint (YAML Validation)

**Install:**
```bash
# macOS
brew install yamllint

# Linux/macOS with pip
pip install yamllint
```

**Usage:**
```bash
yamllint <file>.yaml
```

### Pre-commit Hooks (Recommended)

Automatically run checks before committing.

**Install:**
```bash
# macOS/Linux
brew install pre-commit
# or
pip install pre-commit

# In repository root
pre-commit install
```

**Configuration:**
Pre-commit hooks are configured in `.pre-commit-config.yaml` (if present).

---

## Optional: Cloud CLI Tools

### AWS CLI

Only needed if you want to test AWS Terraform locally (rare).

**Install:**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Configure:**
```bash
aws configure
# Enter AWS Access Key ID
# Enter AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

**Note:** Most contributors don't need AWS credentials. Atlantis handles Terraform execution.

### Google Cloud CLI

Only needed for testing GCP Terraform locally.

**Install:**
```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Configure:**
```bash
gcloud init
gcloud auth application-default login
```

### Azure CLI

Only needed for testing Azure Terraform locally.

**Install:**
```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Configure:**
```bash
az login
```

---

## Editor Setup

### Visual Studio Code (Recommended)

**Install Extensions:**
- **Terraform** - HashiCorp Terraform syntax and validation
- **Kubernetes** - YAML schema validation for K8s
- **YAML** - YAML language support
- **GitLens** - Enhanced Git capabilities

**Settings:**
```json
{
  "terraform.languageServer.enable": true,
  "terraform.validation.enable": true,
  "[terraform]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.formatAll.terraform": true
    }
  },
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  }
}
```

### Vim/Neovim

**Plugins:**
- **vim-terraform** - Terraform syntax highlighting
- **vim-kubernetes** - Kubernetes YAML support
- **ALE** - Linting and fixing

### Other Editors

Most modern editors have:
- Terraform extensions/plugins
- YAML language support
- Git integration

---

## Testing Your Setup

### Test Terraform

```bash
cd infra/aws/terraform/management-account/

# Format check (should pass with no changes)
terraform fmt -check

# Initialize (downloads providers)
terraform init

# Validate syntax
terraform validate
# Success! The configuration is valid.
```

### Test Kubernetes

```bash
cd apps/codesearch/

# Dry-run validation
kubectl apply --dry-run=client -f deployment.yaml
# deployment.apps/codesearch created (dry run)

# Policy check
conftest test deployment.yaml
```

### Test YAML

```bash
cd dns/zone-configs/

yamllint k8s.io.yaml
# Should show no errors
```

---

## Common Setup Issues

### "terraform: command not found"

**Solution:** Terraform not in PATH. Re-install or add to PATH:
```bash
export PATH=$PATH:/usr/local/bin
```

### "kubectl: command not found"

**Solution:** kubectl not in PATH. Re-install or add to PATH.

### "Permission denied" when installing

**Solution:** Use `sudo` for system-wide installs, or install to user directory.

### "Provider not found" in Terraform

**Solution:** Run `terraform init` to download providers:
```bash
cd <terraform-directory>
terraform init
```

### "AWS credentials not configured"

**Solution:** You probably don't need AWS credentials for validation. Use:
```bash
terraform validate  # Works without credentials
terraform fmt       # Works without credentials
terraform plan      # Requires credentials (let Atlantis do this)
```

---

## Recommended Workflow Setup

### Directory Structure

```
~/projects/
└── k8s.io/                    # Your clone
    ├── .git/
    ├── infra/
    ├── apps/
    └── ...
```

### Shell Aliases (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Quick navigation
alias k8s="cd ~/projects/k8s.io"

# Terraform shortcuts
alias tf="terraform"
alias tfv="terraform validate"
alias tff="terraform fmt"

# kubectl shortcuts
alias k="kubectl"
alias kdry="kubectl apply --dry-run=client -f"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit"
```

### GitHub CLI (Optional but Nice)

Makes PR creation easier from command line.

**Install:**
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Authenticate:**
```bash
gh auth login
```

**Usage:**
```bash
# Create PR from command line
gh pr create --title "Fix S3 versioning" --body "Enables versioning on monitoring bucket"
```

---

## Verification Checklist

Before making your first contribution, verify:

- [ ] Git installed and configured
- [ ] Repository cloned
- [ ] `git status` works
- [ ] Can create and switch branches
- [ ] (Optional) Terraform installed
- [ ] (Optional) kubectl installed
- [ ] (Optional) Validation tools installed
- [ ] Editor configured for Terraform/YAML

---

## Next Steps

You're ready to contribute! Here's what to do next:

1. **Find something to work on:**
   - Browse [good first issues](https://github.com/kubernetes/k8s.io/labels/good%20first%20issue)
   - Check [help wanted](https://github.com/kubernetes/k8s.io/labels/help%20wanted) labels
   - Look for documentation improvements

2. **Make your first change:**
   - Follow [Making Changes](../03-development/making-changes.md) guide
   - Start small (typo fix, documentation update)
   - Learn the PR workflow

3. **Get involved:**
   - Join [#sig-k8s-infra](https://kubernetes.slack.com/messages/sig-k8s-infra) on Slack
   - Attend [SIG K8s Infra meetings](https://github.com/kubernetes/community/tree/master/sig-k8s-infra#meetings)
   - Introduce yourself!

---

**Questions?** Ask in [#sig-k8s-infra Slack](https://kubernetes.slack.com/messages/sig-k8s-infra) or check the [troubleshooting guide](../04-reference/troubleshooting.md).
