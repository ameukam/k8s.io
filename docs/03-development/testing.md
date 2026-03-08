# Testing Infrastructure Changes

**How to safely test changes before they reach production.**

**Time to read:** ~10 minutes

---

## Testing Philosophy

**Golden rule:** Test in lower environments before production.

The infrastructure uses multiple testing layers:
1. **Local validation** - Syntax and policy checks
2. **Canary/staging** - Safe environment for integration testing
3. **Production** - Only after successful canary validation

---

## Local Testing

### Terraform Validation

```bash
cd infra/<provider>/terraform/<deployment>/

# Format check
terraform fmt -check

# Initialize providers
terraform init

# Validate syntax
terraform validate

# Plan (shows what would change)
terraform plan
```

**What this catches:**
- Syntax errors
- Invalid references
- Type mismatches
- Provider configuration issues

**What this doesn't catch:**
- Runtime errors
- Permission issues
- Resource conflicts
- Integration problems

### Policy Validation

```bash
# Test against OPA policies
conftest test <file>.tf

# Test Kubernetes manifests
conftest test <file>.yaml
```

**Common policies checked:**
- S3 buckets must have encryption
- IAM roles must have permission boundaries
- Resources must have required tags
- No hardcoded credentials

### Kubernetes Dry-Run

```bash
# Validate without creating resources
kubectl apply --dry-run=client -f <manifest>.yaml

# Server-side validation (requires cluster access)
kubectl apply --dry-run=server -f <manifest>.yaml
```

---

## Canary/Staging Testing

### ⚠️ Access Requirements

**Testing in canary/staging environments requires appropriate access:**

- **Read-only testing**: Check Atlantis plan output in PRs (no special access needed)
- **Canary deployment**: Requires OWNERS approval + Atlantis automation
- **Direct canary access**: Requires Google Group membership or AWS role access

**Don't have access?** That's normal for most contributors! You can:
- Rely on Atlantis plan output to verify changes
- Request OWNERS to test in canary
- Ask in #sig-k8s-infra for access if you're a regular contributor

See [Privilege Requirements](../05-contributing/privilege-requirements.md) for access levels.

---

### AWS: Canary Account

**prow-build-cluster** has dedicated canary account:

```bash
# Deploy to canary first
cd infra/aws/terraform/prow-build-cluster/
PROW_ENV=canary make plan
PROW_ENV=canary make apply

# Validate in canary
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prow-build-cluster \
  --role-arn arn:aws:iam::CANARY_ACCOUNT:role/EKSInfraAdmin

kubectl get nodes
kubectl get pods -A

# Monitor for issues
# Wait 24-48 hours

# If stable, deploy to production
PROW_ENV=prod make plan
PROW_ENV=prod make apply
```

**artifacts.k8s.io** uses prefix-based testing:

```bash
# Test environment (test- prefix)
terraform apply -var prefix=test-

# Verify test buckets created
aws s3 ls | grep test-

# If working, deploy production
terraform apply -var prefix=prod-
```

### GCP: Sandbox Projects

Many GCP projects have sandbox equivalents:

```bash
# Example: k8s-infra-porche
cd infra/gcp/terraform/k8s-infra-porche-sandbox/
terraform plan
terraform apply

# Test in sandbox
# Verify functionality

# Deploy to production
cd ../k8s-infra-porche-prod/
terraform plan
terraform apply
```

### Fastly: Staging Domain

```bash
# Deploy to staging first
cd infra/fastly/terraform/dl.k8s.dev/
terraform plan
terraform apply

# Test staging domain
curl -I https://dl.k8s.dev/v1.30.0/bin/linux/amd64/kubectl

# If working, deploy production
cd ../dl.k8s.io/
terraform plan
terraform apply
```

---

## Testing Checklist

### Before Deploying

- [ ] Code formatted (`terraform fmt`)
- [ ] Syntax validated (`terraform validate`)
- [ ] Policy checks pass (`conftest test`)
- [ ] Terraform plan reviewed
- [ ] Understand what will change
- [ ] Have rollback plan

### After Deploying to Canary

- [ ] Resources created successfully
- [ ] No errors in logs
- [ ] Applications still running
- [ ] Monitoring shows normal metrics
- [ ] Wait appropriate soak period
- [ ] Document any issues found

### Before Production

- [ ] Canary testing complete
- [ ] Issues resolved
- [ ] Changes documented
- [ ] Reviewers approved
- [ ] Rollback plan confirmed

---

## Soak Period Guidelines

How long to wait in canary before production:

| Change Type | Soak Period |
|-------------|-------------|
| Minor config change | 1-2 hours |
| Application update | 4-24 hours |
| Infrastructure change | 24-48 hours |
| Major refactor | 1 week |

**Monitor during soak:**
- Error rates
- Resource utilization
- Application logs
- User-facing metrics

---

## Automated Testing

### Atlantis Workflow

Atlantis automatically tests Terraform changes:

```
1. Open PR with Terraform changes
2. Atlantis runs `terraform plan`
3. Review plan output in PR comment
4. Make adjustments if needed
5. Get approval
6. Atlantis applies changes
```

**What Atlantis validates:**
- Terraform syntax
- Plan generation
- State consistency
- Backend access

### CI Checks

GitHub Actions runs on every PR:

**Checks include:**
- Terraform format check
- Validation
- Policy tests (conftest)
- Security scanning
- Linting

**All must pass before merge.**

---

## Testing Scenarios

### Scenario 1: Adding S3 Bucket

```bash
# 1. Local validation
terraform validate
conftest test s3_new_bucket.tf

# 2. Plan in test environment
terraform plan -var prefix=test-

# 3. Apply to test
terraform apply -var prefix=test-

# 4. Verify bucket created
aws s3 ls | grep test-new-bucket

# 5. Test upload/download
echo "test" > test.txt
aws s3 cp test.txt s3://test-new-bucket/
aws s3 cp s3://test-new-bucket/test.txt downloaded.txt

# 6. Apply to production
terraform apply -var prefix=prod-
```

### Scenario 2: Kubernetes Manifest Change

```bash
# 1. Local validation
kubectl apply --dry-run=client -f deployment.yaml
conftest test deployment.yaml

# 2. Apply to test namespace
kubectl apply -f deployment.yaml -n test

# 3. Verify pods running
kubectl get pods -n test
kubectl logs -n test deployment/app

# 4. If working, merge PR
# ArgoCD will deploy to production automatically

# 5. Monitor production rollout
kubectl rollout status deployment/app -n production
```

### Scenario 3: EKS Cluster Update

```bash
# 1. Update cluster version in locals.tf
# Change: cluster_version = "1.31"

# 2. Test in canary
PROW_ENV=canary make plan
# Review upgrade plan carefully!

PROW_ENV=canary make apply

# 3. Verify canary cluster
kubectl get nodes -o wide
# Check node versions

kubectl get pods -A
# Verify all pods running

# 4. Run application tests
# Deploy test workload
# Verify functionality

# 5. Monitor for 24-48 hours
# Watch logs, metrics, alerts

# 6. If stable, apply to production
PROW_ENV=prod make plan
PROW_ENV=prod make apply
```

---

## Rollback Testing

Always test rollback procedures:

### Terraform Rollback

```bash
# Test reverting a change
git revert <commit>
terraform plan
# Should show reverting to previous state

terraform apply
```

### Kubernetes Rollback

```bash
# Test deployment rollback
kubectl rollout undo deployment/app -n test

# Verify rolled back version
kubectl describe deployment/app -n test
```

---

## Monitoring During Tests

### What to Monitor

**Infrastructure:**
- Resource creation success
- Error logs in CloudWatch/Stackdriver
- Cost spikes (unexpected resources)
- Quota usage

**Applications:**
- Pod status
- Container restarts
- Error rates in logs
- Response times
- Resource usage (CPU/memory)

**External:**
- DNS resolution
- Certificate validity
- CDN hit rates
- External health checks

### Tools

```bash
# AWS CloudWatch
aws logs tail /aws/eks/cluster-name/cluster --follow

# GCP Stackdriver
gcloud logging read "resource.type=k8s_cluster" --limit 50

# Kubernetes
kubectl logs -f deployment/app
kubectl top nodes
kubectl top pods

# Prometheus queries
curl http://prometheus:9090/api/v1/query?query=up
```

---

## Common Testing Mistakes

### ❌ Don't Do

**Skip local validation**
- Results in failed CI checks
- Wastes reviewer time

**Test in production first**
- No safety net
- Production incidents

**Insufficient soak time**
- Issues appear later
- Harder to correlate with change

**Test once and assume it works**
- Flaky tests exist
- Race conditions may not appear

**Ignore monitoring**
- Silent failures
- Degraded performance unnoticed

### ✅ Do Instead

**Always validate locally**
- Catch issues before PR
- Faster feedback loop

**Use canary/staging**
- Safe testing environment
- Real integration testing

**Wait appropriate soak period**
- Let issues surface
- Build confidence

**Test multiple times**
- Verify consistency
- Catch intermittent issues

**Actively monitor**
- Watch logs and metrics
- Set up alerts for testing

---

## Test Environment Access

### ⚠️ Most Contributors Don't Need Direct Access

**The standard workflow:**
1. Open PR with changes
2. Atlantis shows `terraform plan` output
3. OWNERS review the plan
4. If approved, OWNERS or Atlantis test in canary
5. After canary validation, deploy to production

**You typically do NOT need canary credentials yourself.**

### Getting Canary Access (If Needed)

**Only request access if:**
- You're a regular contributor to the area
- You need to debug issues in canary
- OWNERS have approved your access request

**Request process:**
1. Ask in #sig-k8s-infra Slack
2. Explain why you need access
3. Wait for approval from leads
4. Access granted (may be time-limited)

**If granted, access commands:**

**AWS:**
```bash
# Assume canary role (requires granted permissions)
aws sso login --profile canary

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prow-build-cluster \
  --profile canary
```

**GCP:**
```bash
# Authenticate to sandbox project (requires project permissions)
gcloud config set project k8s-infra-porche-sandbox
gcloud auth application-default login
```

**See [Privilege Requirements](../05-contributing/privilege-requirements.md) for access details.**

---

## Documentation

### Document Your Tests

When opening PR, include test results:

```markdown
## Testing Performed

### Local Validation
- ✅ `terraform validate` passed
- ✅ `conftest test` passed
- ✅ `terraform plan` reviewed

### Canary Testing
- ✅ Applied to canary: 2024-03-08 10:00 UTC
- ✅ Verified resources created
- ✅ No errors in logs
- ✅ Monitored for 24 hours
- ✅ All metrics normal

### Test Results
```bash
$ kubectl get nodes
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-100.ec2.internal   Ready    <none>   5m    v1.31.0
ip-10-0-1-101.ec2.internal   Ready    <none>   5m    v1.31.0
```

Ready for production deployment.
```

---

## Next Steps

- Learn [Common Patterns](common-patterns.md) used in testing
- Review [Troubleshooting](../04-reference/troubleshooting.md) for test failures
- Check [Making Changes](making-changes.md) for deployment workflow

---

**Remember:** Testing is not optional. It's how we keep production stable while moving fast.
