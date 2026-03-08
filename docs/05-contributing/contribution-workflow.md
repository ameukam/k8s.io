# Contribution Workflow

**In this guide:** Complete step-by-step process for contributing to the k8s.io infrastructure repository.

**Time to read:** ~10 minutes

**Prerequisites:** Basic Git and GitHub knowledge

---

## Quick Overview

```
Fork repo → Clone → Create branch → Make changes → Push → Open PR → Review → Merge → Auto-deploy
```

Most contributions follow this standard GitHub workflow with some k8s.io-specific conventions.

---

## Prerequisites

### Required

- **GitHub account** - [Sign up](https://github.com/join) if needed
- **Git installed** - Check with `git --version`
- **Basic Kubernetes knowledge** - Understand pods, deployments, services

### Optional (for local testing)

- **Terraform** - For testing infrastructure changes locally
- **kubectl** - For testing Kubernetes manifests locally
- **Cloud credentials** - Usually not needed (Atlantis handles it)

### ⚠️ What You DON'T Need

**Most contributors do NOT need:**
- Direct cloud account access
- Permission to run `terraform apply`
- Cloud console access
- Production credentials

**Why?** All infrastructure changes are applied by Atlantis automation after OWNERS approval.

**Some operations require sig-k8s-infra lead approval.** See [Privilege Requirements](privilege-requirements.md) for:
- What you can do independently
- What needs OWNERS approval
- What needs lead approval
- How to request elevated access

---

## Step-by-Step Workflow

### 1. Fork the Repository

Visit [kubernetes/k8s.io](https://github.com/kubernetes/k8s.io) and click "Fork" (top-right).

This creates your personal copy at `github.com/<your-username>/k8s.io`.

### 2. Clone Your Fork

```bash
git clone https://github.com/<your-username>/k8s.io.git
cd k8s.io
```

### 3. Add Upstream Remote

```bash
git remote add upstream https://github.com/kubernetes/k8s.io.git

# Verify
git remote -v
# origin    https://github.com/<your-username>/k8s.io.git (fetch)
# upstream  https://github.com/kubernetes/k8s.io.git (fetch)
```

### 4. Create a Branch

**Always create a branch for changes!** Never commit directly to `main`.

```bash
# Sync with upstream first
git fetch upstream
git checkout main
git merge upstream/main

# Create your branch
git checkout -b my-feature-branch
```

**Branch naming:**
- `fix/short-description` - Bug fixes
- `feature/short-description` - New functionality
- `update/short-description` - Updates/improvements
- `docs/short-description` - Documentation changes

**Examples:**
- `fix/s3-bucket-versioning`
- `feature/add-monitoring-dashboard`
- `update/terraform-aws-provider`
- `docs/improve-getting-started`

### 5. Make Your Changes

Edit files as needed. See [Making Changes](../03-development/making-changes.md) for specific workflows.

**Tips:**
- Make focused changes (one logical change per PR)
- Follow existing code style
- Add comments explaining WHY, not just WHAT
- Update documentation if behavior changes

### 6. Test Your Changes

**For Terraform:**
```bash
cd <terraform-directory>
terraform fmt
terraform validate
```

**For Kubernetes:**
```bash
kubectl apply --dry-run=client -f <manifest>
conftest test <manifest>
```

**For DNS:**
```bash
yamllint <zone-file>
```

### 7. Commit Your Changes

```bash
git add <files>
git commit
```

**Write a good commit message:**

```
<type>: <short summary in 50 chars>

<detailed explanation of what and why, wrapped at 72 chars>

<optional references to issues/docs>
```

**Example:**

```
fix: enable versioning on monitoring S3 bucket

The monitoring bucket stores critical Prometheus metrics and should
have versioning enabled to prevent accidental data loss.

This change adds versioning configuration to the bucket, allowing
recovery of deleted or overwritten objects for 90 days.

Refs: https://github.com/kubernetes/k8s.io/issues/12345
```

**Commit message prefixes:**
- `fix:` - Bug fixes
- `feat:` - New features
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Maintenance tasks

### 8. Push to Your Fork

```bash
git push origin my-feature-branch
```

### 9. Open a Pull Request

1. Visit `https://github.com/<your-username>/k8s.io`
2. GitHub will show "Compare & pull request" button - click it
3. Fill out the PR template

**PR Title:** Same format as commit message
```
fix: enable versioning on monitoring S3 bucket
```

**PR Description Template:**

```markdown
## What type of PR is this?

/kind bug
/kind feature
/kind documentation
/kind cleanup

## What this PR does / why we need it:

This PR enables versioning on the monitoring S3 bucket to prevent
accidental data loss of Prometheus metrics.

## Which issue(s) this PR fixes:

Fixes #12345

## Special notes for your reviewer:

This requires one-time AWS credentials to apply. Atlantis will handle
the Terraform apply.

## Does this PR introduce a user-facing change?

<!--
If yes, write a release note in the block below. If not, delete this section.
-->

```

### 10. Automated Checks Run

GitHub Actions and other automation will:

**For Terraform changes:**
- Atlantis comments with `terraform plan` output
- Validation checks run
- Policy checks (conftest) run

**For Kubernetes changes:**
- YAML validation
- Policy checks (conftest)
- Security scans

**Review the output!** Fix any failures.

### 11. Request Review

GitHub automatically requests review from relevant OWNERS based on `OWNERS` files.

You can also manually request review:
- Click "Reviewers" (right sidebar)
- Select reviewers listed in the relevant `OWNERS` file

**Finding OWNERS:**
```bash
# Check OWNERS file in the directory you changed
cat infra/aws/terraform/prow-build-cluster/OWNERS
```

### 12. Address Feedback

Reviewers may request changes. To update your PR:

```bash
# Make changes
git add <files>
git commit -m "Address review feedback"
git push origin my-feature-branch
```

The PR updates automatically with your new commits.

### 13. Get Approval

You need **two things** to merge:

1. **`/lgtm`** (Looks Good To Me) - Technical review approval
2. **`/approve`** - Final approval from OWNERS

Reviewers add these as PR comments:
```
/lgtm
/approve
```

### 14. Merge

Once you have both `/lgtm` and `/approve`, the PR can merge.

**Auto-merge:** Many PRs merge automatically after approval.

**Manual merge:** For Terraform changes, you may need to:
1. Comment `atlantis apply` to apply infrastructure changes
2. Wait for Atlantis to complete
3. Then merge the PR

### 15. Changes Deploy

**Infrastructure (Terraform):**
- Already applied by Atlantis in step 14

**Kubernetes applications:**
- ArgoCD automatically syncs within minutes
- Check ArgoCD dashboard for deployment status

**DNS:**
- Automated systems propagate changes
- May take minutes to hours depending on TTL

---

## Special Commands (Prow Bot)

The Kubernetes Prow bot responds to commands in PR comments:

| Command | Purpose |
|---------|---------|
| `/lgtm` | Approve technically (from reviewers) |
| `/lgtm cancel` | Remove LGTM |
| `/approve` | Final approval (from OWNERS) |
| `/approve cancel` | Remove approval |
| `/assign @username` | Assign to reviewer |
| `/cc @username` | Request review |
| `/hold` | Prevent auto-merge |
| `/hold cancel` | Remove hold |
| `/kind bug` | Label as bug fix |
| `/kind feature` | Label as feature |
| `/kind documentation` | Label as docs |
| `/retest` | Re-run failed tests |
| `atlantis plan` | Run Terraform plan |
| `atlantis apply` | Apply Terraform changes |

---

## Atlantis-Specific Workflow

For Terraform changes, Atlantis handles execution:

### 1. PR Opened → Automatic Plan

Atlantis automatically runs `terraform plan` and comments the output.

**Example comment:**
```
Ran Plan for dir: infra/aws/terraform/prow-build-cluster workspace: default

Show Output

Plan: 1 to add, 0 to change, 0 to destroy.
```

### 2. Review the Plan

Click "Show Output" to see detailed plan. **Review carefully!**

Look for:
- Resources being created (`+`)
- Resources being modified (`~`)
- Resources being destroyed (`-`)
- Resources being replaced (`-/+`)

### 3. If Changes Needed

Push new commits. Atlantis automatically re-plans.

### 4. After Approval → Apply

Comment on the PR:
```
atlantis apply
```

Atlantis will:
1. Run `terraform apply`
2. Comment the results
3. Mark the PR as ready to merge

### 5. Merge the PR

After successful apply, merge the PR to update the code to match infrastructure.

**Note:** Some directories are configured for auto-apply after merge. Check `.atlantis.yaml`.

---

## Common Issues

### "CI checks failing"

**Solution:**
1. Read the error output in the PR
2. Fix the issue locally
3. Commit and push again
4. CI re-runs automatically

### "Merge conflict"

**Solution:**
```bash
# Sync with upstream
git fetch upstream
git checkout my-feature-branch
git merge upstream/main

# Resolve conflicts
git add <resolved-files>
git commit
git push origin my-feature-branch
```

### "No reviewers responding"

**Solution:**
- Wait 2-3 business days
- Ping in #sig-k8s-infra Slack
- Tag reviewers in a comment: `@username gentle ping for review`

### "Atlantis apply failed"

**Solution:**
1. Read the error output
2. Fix the Terraform code
3. Push changes
4. Atlantis will re-plan
5. Try `atlantis apply` again

### "Don't have permissions"

**Solution:**
- Most contributors don't need direct access
- Atlantis handles Terraform applies
- For special access needs, ask in #sig-k8s-infra

---

## Best Practices

### DO ✅

- **One change per PR** - Easier to review
- **Test before pushing** - Catch issues early
- **Write clear commit messages** - Future you will thank you
- **Respond to reviews promptly** - Keep momentum
- **Ask questions** - Better to ask than assume
- **Follow existing patterns** - Consistency matters
- **Update documentation** - If behavior changes

### DON'T ❌

- **Force push after review** - Reviewers lose context
- **Commit secrets** - Use secret management tools
- **Make unrelated changes** - Stay focused
- **Leave stale PRs** - Close if no longer relevant
- **Argue with reviewers** - Assume positive intent
- **Rush the process** - Infrastructure changes require care

---

## Getting Help

### Questions About Your PR

**Slack:** [#sig-k8s-infra](https://kubernetes.slack.com/messages/sig-k8s-infra)

Post:
```
Hi! I have a question about my PR kubernetes/k8s.io#12345
[your question]
```

### General Contribution Questions

**Slack:** [#sig-k8s-infra](https://kubernetes.slack.com/messages/sig-k8s-infra)
**Mailing list:** [sig-k8s-infra@kubernetes.io](https://groups.google.com/a/kubernetes.io/g/sig-k8s-infra)

### Technical Issues

**GitHub Issues:** [kubernetes/k8s.io/issues](https://github.com/kubernetes/k8s.io/issues)

### Community Meetings

**SIG K8s Infra meetings:** [Schedule and notes](https://github.com/kubernetes/community/tree/master/sig-k8s-infra#meetings)

Great place to:
- Ask questions
- Present proposals
- Get to know the community

---

## Your First Contribution

**Looking for an easy starting point?**

1. **Good first issues:** [Labels: good-first-issue](https://github.com/kubernetes/k8s.io/labels/good%20first%20issue)
2. **Documentation improvements:** Always welcome!
3. **Fix typos:** Small but valuable

**Tips for first-timers:**
- Start small to learn the workflow
- Don't be intimidated by complex infrastructure
- Ask questions - the community is friendly!
- Read other PRs to learn conventions

---

## Code Review Process

### What Reviewers Look For

**Technical correctness:**
- Does the code do what it claims?
- Are there edge cases not handled?
- Is it following best practices?

**Security:**
- No secrets committed
- Proper access controls
- Following principle of least privilege

**Maintainability:**
- Is the code clear and documented?
- Does it follow existing patterns?
- Will future contributors understand it?

**Testing:**
- Has it been tested?
- Are there automated checks?

### How to Be a Good Reviewee

- **Be responsive** - Address feedback promptly
- **Be open** - Assume reviewers want to help
- **Ask questions** - If feedback is unclear
- **Explain decisions** - Help reviewers understand your choices
- **Be patient** - Reviews take time

---

## After Your PR Merges

### Celebrate! 🎉

You've contributed to Kubernetes infrastructure!

### Monitor the Deployment

- Check ArgoCD for Kubernetes changes
- Watch Slack for any alerts
- Verify changes worked as expected

### Follow Up

If issues arise:
1. Notify #sig-k8s-infra immediately
2. Prepare a fix or revert
3. Learn from the experience

---

## Recognition

Contributors are recognized in:
- Git history (permanent record)
- [DevStats](https://k8s.devstats.cncf.io/) (contribution metrics)
- Community acknowledgments
- [kubernetes/k8s.io contributors page](https://github.com/kubernetes/k8s.io/graphs/contributors)

---

**Next Steps:**
- Review [Making Changes](../03-development/making-changes.md) for technical details
- Check [Review Process](review-process.md) to understand code review
- Browse [good first issues](https://github.com/kubernetes/k8s.io/labels/good%20first%20issue)
