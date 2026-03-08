# Troubleshooting Guide

**Common issues and solutions when working with k8s.io infrastructure.**

---

## Terraform Issues

### "Error: Failed to get existing workspaces"

**Symptom:**
```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```

**Cause:** Terraform backend not initialized or wrong directory.

**Solution:**
```bash
# Make sure you're in the correct directory
cd infra/<provider>/terraform/<deployment>/

# Initialize Terraform
terraform init
```

---

### "Error: Inconsistent dependency lock file"

**Symptom:**
```
Error: Inconsistent dependency lock file

The following dependency selections recorded in the lock file are inconsistent with the current configuration:
  - provider.aws: required by this configuration but no version is selected
```

**Cause:** Provider versions changed or lock file missing.

**Solution:**
```bash
# Regenerate lock file
terraform init -upgrade
```

---

### "Error: resource already exists"

**Symptom:**
```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou: Your previous request to create the named bucket succeeded and you already own it.
```

**Cause:** Resource exists in cloud but not in Terraform state.

**Solution:**
```bash
# Import existing resource
terraform import aws_s3_bucket.example bucket-name

# Or remove from code if it shouldn't be managed
```

---

### "Error: Error acquiring the state lock"

**Symptom:**
```
Error: Error acquiring the state lock

Lock Info:
  ID:        abc123...
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2026-03-08 12:34:56
```

**Cause:** Another process is running Terraform, or previous run crashed.

**Solution:**
```bash
# If you're SURE no one else is running Terraform:
terraform force-unlock abc123

# Otherwise, wait for the other operation to complete
```

---

### "Permission denied" errors

**Symptom:**
```
Error: error reading S3 Bucket: AccessDenied: Access Denied
```

**Cause:** Missing or incorrect AWS/GCP credentials or IAM permissions.

**Solution:**
```bash
# Check credentials are configured
aws sts get-caller-identity  # AWS
gcloud auth list             # GCP

# Verify you're using the correct role
aws sts get-caller-identity | grep Arn
# Should show the expected role (e.g., EKSInfraAdmin)

# For EKS access, ensure role in kubeconfig:
kubectl config view | grep role-arn
```

---

## Kubernetes Issues

### "error: You must be logged in to the server"

**Symptom:**
```
error: You must be logged in to the server (Unauthorized)
```

**Cause:** kubeconfig not configured or expired credentials.

**Solution:**
```bash
# For EKS clusters, update kubeconfig:
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prow-build-cluster \
  --role-arn arn:aws:iam::ACCOUNT:role/EKSInfraAdmin

# For GKE clusters:
gcloud container clusters get-credentials CLUSTER_NAME \
  --region REGION \
  --project PROJECT_ID
```

---

### "Unable to connect to the server"

**Symptom:**
```
Unable to connect to the server: dial tcp: lookup api.cluster.k8s.io: no such host
```

**Cause:** Cluster doesn't exist, wrong context, or network issue.

**Solution:**
```bash
# List available contexts
kubectl config get-contexts

# Switch to correct context
kubectl config use-context CONTEXT_NAME

# Verify cluster accessibility
kubectl cluster-info
```

---

### "ImagePullBackOff" errors

**Symptom:**
```
NAME           READY   STATUS             RESTARTS   AGE
pod/app-xyz    0/1     ImagePullBackOff   0          2m
```

**Cause:** Image doesn't exist, wrong tag, or registry authentication issue.

**Solution:**
```bash
# Check pod events
kubectl describe pod app-xyz

# Common issues:
# - Typo in image name/tag
# - Image doesn't exist in registry
# - Missing imagePullSecrets for private registries

# Verify image exists:
docker pull <image>:<tag>
```

---

### "CrashLoopBackOff" errors

**Symptom:**
```
NAME           READY   STATUS             RESTARTS   AGE
pod/app-xyz    0/1     CrashLoopBackOff   5          10m
```

**Cause:** Application crashing on startup.

**Solution:**
```bash
# Check logs
kubectl logs app-xyz

# Check previous container logs if restarted
kubectl logs app-xyz --previous

# Check events
kubectl describe pod app-xyz

# Common causes:
# - Missing environment variables
# - Missing ConfigMap/Secret
# - Application configuration error
```

---

## DNS Issues

### "DNS changes not propagating"

**Symptom:** DNS query returns old value after updating zone file.

**Cause:** DNS caching (TTL) or changes not yet applied.

**Solution:**
```bash
# Check DNS directly (bypasses local cache)
dig @8.8.8.8 record.k8s.io

# Check multiple DNS servers
dig @8.8.8.8 record.k8s.io    # Google
dig @1.1.1.1 record.k8s.io    # Cloudflare

# Wait for TTL to expire
# If TTL was 300s (5 minutes), old records cached for up to 5 minutes

# Verify zone file was deployed correctly
git log dns/zone-configs/k8s.io.yaml
```

---

## Git / GitHub Issues

### "remote: Permission to kubernetes/k8s.io.git denied"

**Symptom:**
```
remote: Permission to kubernetes/k8s.io.git denied to user.
fatal: unable to access 'https://github.com/kubernetes/k8s.io.git/': The requested URL returned error: 403
```

**Cause:** Trying to push to upstream instead of your fork.

**Solution:**
```bash
# Check remotes
git remote -v

# Should have:
# origin     https://github.com/YOUR-USERNAME/k8s.io.git
# upstream   https://github.com/kubernetes/k8s.io.git

# Always push to origin (your fork):
git push origin branch-name
```

---

### "Merge conflict" in PR

**Symptom:** GitHub shows "This branch has conflicts that must be resolved"

**Solution:**
```bash
# Sync with upstream
git fetch upstream
git checkout your-branch
git merge upstream/main

# Git will show conflicts
# Edit conflicted files, look for:
<<<<<<< HEAD
your changes
=======
upstream changes
>>>>>>> upstream/main

# After resolving:
git add <resolved-files>
git commit
git push origin your-branch
```

---

## Atlantis Issues

### "Atlantis not commenting on PR"

**Symptom:** Opened PR with Terraform changes, but no Atlantis comment.

**Cause:** Atlantis didn't detect Terraform changes or configuration issue.

**Solution:**
```bash
# Manually trigger Atlantis
# Comment on PR:
atlantis plan

# Check atlantis.yaml configuration
cat .atlantis.yaml

# Verify changes are in a directory Atlantis watches
```

---

### "atlantis apply" fails

**Symptom:** `atlantis apply` command fails with error.

**Solution:**
1. Read the error message carefully
2. Fix the Terraform code
3. Push changes (Atlantis re-plans automatically)
4. Try `atlantis apply` again

**Common causes:**
- Resource dependency issues
- Permission errors
- Resource conflicts

---

### "Plan has changed" warning

**Symptom:**
```
Error: Plan has changed. Please run `atlantis plan` again.
```

**Cause:** You pushed new commits after Atlantis ran the plan.

**Solution:**
```bash
# Atlantis automatically re-plans after new pushes
# Wait for new plan comment, then:
atlantis apply
```

---

## ArgoCD Issues

### "Application OutOfSync"

**Symptom:** ArgoCD dashboard shows application status as "OutOfSync"

**Cause:** Git state differs from cluster state.

**Solution:**
```bash
# Option 1: Let ArgoCD sync automatically (if auto-sync enabled)
# Wait a few minutes

# Option 2: Manual sync via UI
# Click "Sync" in ArgoCD dashboard

# Option 3: Manual sync via CLI
argocd app sync <app-name>
```

---

### "Application Degraded"

**Symptom:** ArgoCD shows application as "Degraded"

**Cause:** Resources are deployed but not healthy.

**Solution:**
```bash
# Check application details in ArgoCD UI
# Look for resources with warnings/errors

# Check pod status
kubectl get pods -n <namespace>

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Common causes:
# - Image pull errors
# - Application crashes
# - Missing dependencies (ConfigMaps, Secrets)
```

---

## CI/CD Issues

### "Pre-commit checks failing"

**Symptom:**
```
[ERROR] Check failed
```

**Solution:**
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run -a

# Fix issues shown
# Commit and push again
```

---

### "Policy check failed"

**Symptom:**
```
FAIL - policy/terraform/aws/s3_bucket_encryption.rego
```

**Cause:** Terraform configuration violates OPA policy.

**Solution:**
```bash
# Run conftest locally
conftest test <file>.tf

# Read the policy to understand requirement
cat policy/terraform/aws/s3_bucket_encryption.rego

# Fix configuration to meet policy
# Example: Enable encryption on S3 bucket
```

---

## Local Development Issues

### "terraform: command not found"

**Solution:**
```bash
# Install Terraform
brew install terraform  # macOS
# Or download from terraform.io

# Verify installation
terraform version
```

---

### "kubectl: command not found"

**Solution:**
```bash
# Install kubectl
brew install kubectl  # macOS
# Or download from kubernetes.io

# Verify installation
kubectl version --client
```

---

## Cloud Provider Specific

### AWS: "An error occurred (ExpiredToken)"

**Symptom:**
```
An error occurred (ExpiredToken) when calling the GetCallerIdentity operation: The security token included in the request is expired
```

**Solution:**
```bash
# Re-authenticate with AWS
aws sso login

# Or refresh credentials
aws sts get-caller-identity  # This will fail if expired
# Then re-run aws configure or aws sso login
```

---

### GCP: "Your current active account is not a service account"

**Solution:**
```bash
# Authenticate with application default credentials
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

---

### Azure: "No subscriptions found"

**Solution:**
```bash
# Login to Azure
az login

# List subscriptions
az account list

# Set default subscription
az account set --subscription SUBSCRIPTION_ID
```

---

## Getting More Help

If you're still stuck:

### 1. Search Existing Issues
[kubernetes/k8s.io issues](https://github.com/kubernetes/k8s.io/issues)

### 2. Ask in Slack
[#sig-k8s-infra channel](https://kubernetes.slack.com/messages/sig-k8s-infra)

**Good question format:**
```
Hi! I'm trying to [what you're doing]

Error message:
[paste error]

What I've tried:
- [thing 1]
- [thing 2]

Relevant links:
PR: [link if applicable]
```

### 3. File an Issue
If you've found a bug or have a feature request:

[Create new issue](https://github.com/kubernetes/k8s.io/issues/new)

**Include:**
- What you were trying to do
- What happened
- What you expected
- Steps to reproduce
- Error messages (full output)
- Your environment (OS, Terraform version, etc.)

---

## Prevention Tips

### Before Making Changes

- [ ] Read relevant documentation
- [ ] Test locally if possible
- [ ] Run validation (`terraform validate`, `kubectl apply --dry-run`)
- [ ] Check policy compliance (`conftest test`)
- [ ] Review Terraform plan carefully

### Before Applying

- [ ] Verify you're in the correct account/project
- [ ] Verify you're in the correct environment (prod vs staging)
- [ ] Read the Atlantis plan output completely
- [ ] Consider blast radius - what could go wrong?
- [ ] Have a rollback plan

### After Changes

- [ ] Monitor deployment (ArgoCD, cluster health)
- [ ] Verify changes worked as expected
- [ ] Watch for alerts/errors
- [ ] Be available to fix issues

---

**Related:**
- [Making Changes](../03-development/making-changes.md) - Workflows for modifications
- [Setup Guide](../01-getting-started/setup.md) - Installation instructions
- [Contribution Workflow](../05-contributing/contribution-workflow.md) - PR process
