# Making Changes

**In this guide:** Step-by-step workflow for modifying infrastructure and applications in this repository.

**Time to read:** ~15 minutes

**Prerequisites:**
- [Repository Overview](../01-getting-started/repository-overview.md)
- [Terraform Basics](../01-getting-started/terraform-basics.md)

---

## ⚠️ Important: Read This First

**Most contributors work through Pull Requests without direct cloud access.**

Some operations require elevated privileges or sig-k8s-infra lead approval:
- Creating new cloud accounts/projects
- Modifying organization-level settings
- Core DNS changes (kubernetes.io, k8s.io)
- Production cluster modifications
- Organization-wide IAM changes

**👉 See [Privilege Requirements](../05-contributing/privilege-requirements.md) for complete details.**

As a contributor, you:
- ✅ **CAN**: Open PRs, propose changes, suggest improvements
- ✅ **AUTOMATED**: Atlantis applies Terraform (not you)
- ❌ **CANNOT**: Directly run `terraform apply` or access cloud consoles (unless you're an OWNER)

**This is normal and expected!** The workflow is designed for safe, reviewed changes.

---

## Before You Start

### Understand the Impact

Infrastructure changes can affect production systems. Before making changes:

1. **Identify what you're changing**: Infrastructure? Application? DNS?
2. **Understand the blast radius**: Who/what does this affect?
3. **Check for dependencies**: What else depends on this?
4. **Plan for rollback**: How do you undo this if needed?

### Find the Right Place

| What You're Changing | Where to Look |
|---------------------|---------------|
| AWS infrastructure | `infra/aws/terraform/` |
| GCP infrastructure | `infra/gcp/terraform/` |
| Azure infrastructure | `infra/azure/terraform/` |
| Fastly CDN | `infra/fastly/terraform/` |
| IBM Cloud | `infra/ibmcloud/terraform/` |
| Kubernetes app | `apps/<app-name>/` |
| Cluster config | `kubernetes/` |
| DNS records | `dns/zone-configs/` |

---

## Workflow Overview

```
1. Create a branch
2. Make changes
3. Test locally (if possible)
4. Open Pull Request
5. Automated checks run
6. Review and address feedback
7. Get approval from OWNERS
8. Changes applied automatically
```

---

## Making Terraform Changes

### Step 1: Find the Configuration

Navigate to the relevant Terraform directory:

```bash
cd infra/aws/terraform/prow-build-cluster/
```

### Step 2: Create a Branch

```bash
git checkout -b add-monitoring-bucket
```

**Branch naming conventions:**
- `fix/` - Bug fixes
- `feature/` - New functionality
- `update/` - Updates or modifications
- `docs/` - Documentation changes

Examples: `fix/s3-versioning`, `feature/add-cdn`, `update/terraform-version`

### Step 3: Make Your Changes

Edit the relevant `.tf` files:

```hcl
# Add a new S3 bucket
resource "aws_s3_bucket" "monitoring" {
  bucket = "k8s-prow-monitoring-logs"

  tags = {
    Purpose     = "Store monitoring logs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

**Best practices:**
- Add comments explaining WHY, not just WHAT
- Follow existing naming conventions
- Use consistent formatting (run `terraform fmt`)
- Add tags to resources for tracking

### Step 4: Validate Locally (Optional but Recommended)

```bash
# Format code
terraform fmt

# Validate syntax
terraform validate

# See what would change (requires AWS credentials)
terraform plan
```

**Note:** You need appropriate cloud credentials to run `plan` locally. If you don't have them, Atlantis will run the plan for you in the PR.

### Step 5: Commit Your Changes

```bash
git add .
git commit -m "Add S3 bucket for monitoring logs

This bucket will store Prometheus metrics and Grafana logs
from the prow-build-cluster for 90-day retention.

Refs: #12345"
```

**Good commit message structure:**
```
<short summary (50 chars)>

<detailed explanation of what and why>

<references to issues/docs>
```

### Step 6: Push and Create PR

```bash
git push origin add-monitoring-bucket
```

Then create a Pull Request on GitHub.

### Step 7: Atlantis Runs Automatically

Atlantis bot will:
1. Detect your Terraform changes
2. Run `terraform plan`
3. Comment the plan output on your PR

**Example Atlantis comment:**
```
Ran Plan for dir: infra/aws/terraform/prow-build-cluster workspace: default

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Review the plan carefully!** This shows exactly what will happen.

### Step 8: Get Review and Approval

- Request review from OWNERS (check `OWNERS` file in the directory)
- Address any feedback
- Get `/lgtm` (looks good to me) and `/approve`

### Step 9: Apply Changes

Once approved, comment on the PR:
```
atlantis apply
```

Atlantis will:
1. Run `terraform apply`
2. Report results in a comment
3. Your infrastructure is now updated!

**Alternative:** Some directories are configured to auto-apply after merge. Check the `atlantis.yaml` configuration.

---

## Making Kubernetes Changes

### Step 1: Find the Application

```bash
cd apps/codesearch/
```

### Step 2: Create a Branch

```bash
git checkout -b update-codesearch-replicas
```

### Step 3: Edit Manifests

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesearch
spec:
  replicas: 3  # Changed from 2
  # ...
```

### Step 4: Validate Locally

```bash
# Dry-run validation
kubectl apply --dry-run=client -f deployment.yaml

# Check for policy violations
conftest test deployment.yaml
```

### Step 5: Commit and Push

```bash
git add deployment.yaml
git commit -m "Scale codesearch to 3 replicas

Increased load requires additional capacity for search requests.

Refs: #67890"

git push origin update-codesearch-replicas
```

### Step 6: Create PR

Open Pull Request on GitHub. Automated checks will:
- Validate YAML syntax
- Run policy checks (OPA/Conftest)
- Check for security issues

### Step 7: Review and Merge

- Get approval from app OWNERS
- Merge the PR
- **ArgoCD automatically deploys** within minutes

**Check deployment:** Visit ArgoCD dashboard to monitor rollout.

---

## Making DNS Changes

### Step 1: Edit Zone File

```bash
cd dns/zone-configs/
```

Edit `k8s.io.yaml`:

```yaml
records:
  - name: "new-service"
    type: "A"
    ttl: 300
    values:
      - "192.0.2.1"
```

### Step 2: Validate

```bash
# Check YAML syntax
yamllint k8s.io.yaml

# Run any validation scripts
../scripts/validate-zones.sh
```

### Step 3: Create PR

DNS changes are sensitive, so:
- Explain why this change is needed
- Note what systems depend on this DNS record
- Get review from DNS OWNERS

### Step 4: Merge and Propagate

After merge, DNS changes propagate automatically (can take up to TTL + propagation time).

---

## Testing Your Changes

### Terraform Testing

```bash
# In Terraform directory

# 1. Format check
terraform fmt -check

# 2. Validation
terraform validate

# 3. Plan (requires credentials)
terraform plan

# 4. Optional: Policy check
conftest test *.tf
```

### Kubernetes Testing

```bash
# In app directory

# 1. Syntax validation
kubectl apply --dry-run=client -f .

# 2. Policy check
conftest test *.yaml

# 3. Optional: Deploy to test namespace
kubectl apply -f . -n test-namespace
```

### DNS Testing

```bash
# Validate zone files
../scripts/validate-zones.sh

# After merge, test DNS resolution
dig new-service.k8s.io
```

---

## Common Workflows

### Adding a New S3 Bucket

```bash
cd infra/aws/terraform/<relevant-directory>/

# Create s3.tf or add to existing file
cat > s3_new_bucket.tf <<EOF
resource "aws_s3_bucket" "new_bucket" {
  bucket = "k8s-new-bucket-name"

  tags = {
    Purpose     = "Describe purpose"
    ManagedBy   = "terraform"
    Environment = "production"
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

# Follow PR workflow above
```

### Scaling a Deployment

```bash
cd apps/<app-name>/

# Edit replicas in deployment.yaml
sed -i 's/replicas: 2/replicas: 3/' deployment.yaml

# Commit and PR
git add deployment.yaml
git commit -m "Scale <app> to 3 replicas"
git push origin scale-<app>
```

### Adding an IAM Policy

```bash
cd infra/aws/terraform/<directory>/

# Create or edit iam.tf
cat >> iam.tf <<EOF
resource "aws_iam_policy" "new_policy" {
  name        = "K8sInfraNewPolicy"
  description = "Policy for <purpose>"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::bucket-name",
          "arn:aws:s3:::bucket-name/*"
        ]
      }
    ]
  })
}
EOF

# Follow PR workflow
```

---

## Handling Failures

### Terraform Apply Failed

If `atlantis apply` fails:

1. **Read the error carefully** - Error messages usually indicate the problem
2. **Check Terraform state** - State might be partially updated
3. **Don't panic** - Terraform is designed to recover
4. **Fix the code** and re-apply

**Common issues:**
- Resource already exists → Import it or rename it
- Permission denied → Check IAM permissions
- Dependency not met → Ensure dependent resources exist

### Kubernetes Deployment Failed

If ArgoCD deployment fails:

1. **Check ArgoCD UI** for error details
2. **Check application logs**: `kubectl logs -n <namespace> <pod>`
3. **Check events**: `kubectl get events -n <namespace>`
4. **Revert if necessary**: Open PR to revert changes

### DNS Changes Not Propagating

1. **Check TTL** - Old records may be cached
2. **Verify zone file syntax** - Errors prevent updates
3. **Check DNS servers**: `dig @8.8.8.8 record.k8s.io`
4. **Wait for propagation** - Can take minutes to hours

---

## Rollback Strategies

### Terraform Rollback

**Option 1: Revert the code change**
```bash
# Revert the commit
git revert <commit-hash>

# Create PR with revert
# Atlantis will plan/apply the revert
```

**Option 2: Manual state manipulation (advanced)**
```bash
# Only for emergencies!
terraform state rm <resource>
terraform import <resource> <id>
```

### Kubernetes Rollback

**Option 1: Revert the commit**
```bash
git revert <commit-hash>
# ArgoCD will sync the old version
```

**Option 2: ArgoCD rollback**
- Use ArgoCD UI to rollback to previous sync
- This is temporary until git is fixed

**Option 3: Manual kubectl**
```bash
kubectl rollout undo deployment/<name> -n <namespace>
```

### DNS Rollback

```bash
# Revert commit with DNS changes
git revert <commit-hash>

# DNS will propagate the old record
```

---

## Best Practices

### DO ✅

- **Start small** - Make one change per PR when learning
- **Test locally** - Catch issues before PR
- **Write good commit messages** - Explain why, not just what
- **Review plans carefully** - Atlantis output shows exactly what happens
- **Tag resources** - Every resource should have tags
- **Use modules** - Reuse existing modules instead of copying code
- **Ask for help** - #sig-k8s-infra Slack channel

### DON'T ❌

- **Make changes directly in cloud consoles** - Everything must be in code
- **Skip reviews** - Even small changes need review
- **Rush the apply** - Read the plan output thoroughly
- **Ignore test failures** - Fix them before merging
- **Hardcode values** - Use variables and locals
- **Leave TODO comments** - Either do it or create an issue
- **Commit secrets** - Use secret management tools

---

## Getting Unstuck

### "I don't understand the error message"
1. Copy the full error
2. Search for it online
3. Ask in #sig-k8s-infra Slack
4. Check Terraform/K8s documentation

### "My PR checks are failing"
1. Read the error output in the PR
2. Fix locally and push again
3. Ask for help if unclear

### "I need cloud credentials"
You probably don't! Atlantis handles Terraform commands in CI. For local testing, ask in #sig-k8s-infra about getting access.

### "I don't know who to request review from"
Check the `OWNERS` file in the directory you changed.

---

**Next Steps:**
- Review [Contribution Workflow](../05-contributing/contribution-workflow.md) for detailed PR process
- Learn [Common Patterns](common-patterns.md) used in this repository
- Check [Troubleshooting](../04-reference/troubleshooting.md) for common issues
