# Review Process

**What to expect during code review and how to be an effective reviewer/reviewee.**

---

## Overview

All changes to k8s.io infrastructure go through peer review before merging. This ensures quality, catches mistakes, and shares knowledge across the team.

**Review goals:**
- Verify technical correctness
- Ensure security and safety
- Maintain code quality and consistency
- Share knowledge and context
- Catch issues before they reach production

---

## Review Timeline

**Typical timeline:**
- **Hours to days** for small/urgent changes
- **Days to week** for significant infrastructure changes
- **Week+** for major architectural changes

**Factors affecting speed:**
- Size and complexity of change
- Availability of reviewers
- Whether it's urgent (outage, security)
- Time zone differences

**Be patient!** Reviewers are volunteers with other responsibilities.

---

## Who Reviews Your PR

### Automatic Assignment

When you open a PR, reviewers are automatically assigned based on:
- **OWNERS files** in directories you modified
- **Previous contributors** to those files
- **Prow bot** handles automatic assignment

### OWNERS File Structure

```yaml
# Example: infra/aws/terraform/prow-build-cluster/OWNERS
approvers:
  - alice
  - bob
  - sig-k8s-infra-leads

reviewers:
  - carol
  - dave
  - team-infra

labels:
  - area/infra
  - sig/k8s-infra
```

**Roles:**
- **Reviewers** - Can give technical review (`/lgtm`)
- **Approvers** - Can approve for merge (`/approve`)

### You Need Both

```
/lgtm     (Looks Good To Me) - Technical review
+
/approve  (Final approval) - Owner approval
=
Auto-merge enabled
```

---

## What Reviewers Check

### 1. Does It Work?

- **Syntax:** Is the code valid?
- **Logic:** Does it do what it claims?
- **Dependencies:** Are all requirements met?
- **Testing:** Has it been tested?

### 2. Is It Safe?

- **Security:** Any vulnerabilities introduced?
- **Secrets:** No credentials committed?
- **Permissions:** Following least privilege?
- **Blast radius:** What breaks if this fails?

### 3. Is It Maintainable?

- **Clarity:** Is the code easy to understand?
- **Documentation:** Are changes explained?
- **Consistency:** Follows existing patterns?
- **Comments:** Why (not just what) explained?

### 4. Is It Necessary?

- **Scope:** Is this the minimal change needed?
- **Over-engineering:** Adding unnecessary complexity?
- **Alternatives:** Is there a simpler approach?

### 5. Does It Follow Policy?

- **OPA policies:** Passing conftest checks?
- **Standards:** Following Kubernetes community norms?
- **Legal/licensing:** No licensing issues?

---

## Common Review Feedback

### "Can you add a comment explaining why?"

**What they mean:** Code is unclear about intent.

**Response:**
```hcl
# Before
count = 0

# After
# Temporarily disabled pending security review
# See: https://github.com/kubernetes/k8s.io/issues/12345
count = 0
```

### "This could break production X"

**What they mean:** Change has unintended consequences.

**Response:**
- Ask for clarification
- Test the scenario they're concerned about
- Either fix the issue or explain why it's safe

### "Have you tested this?"

**What they mean:** Not confident this works as claimed.

**Response:**
```markdown
Tested in canary environment:
1. Applied changes: `make apply PROW_ENV=canary`
2. Verified: `kubectl get nodes` shows 3 nodes
3. Monitored: No errors in logs for 2 hours
4. Rollback tested: `terraform destroy` successful

Ready for production.
```

### "This duplicates code in module X"

**What they mean:** Should use existing abstraction.

**Response:**
```markdown
Good catch! Refactored to use module X:

```hcl
module "bucket" {
  source = "../../modules/s3-bucket"
  # ...
}
```

Much cleaner, thanks!
```

### "Can you split this PR?"

**What they mean:** PR too large to review effectively.

**Response:**
1. Close current PR
2. Create separate PRs for independent changes
3. Link PRs in descriptions
4. Merge in logical order

### "Needs rebase"

**What they mean:** PR has conflicts with main branch.

**Response:**
```bash
git fetch upstream
git rebase upstream/main
git push --force-with-lease origin your-branch
```

---

## Responding to Feedback

### DO ✅

**1. Say thank you**
- Reviewers donated their time
- Even if you disagree with feedback

**2. Ask clarifying questions**
```markdown
Can you elaborate on the security concern?
I'm not familiar with that edge case.
```

**3. Acknowledge and commit to fix**
```markdown
Good point! I'll:
1. Add encryption to the bucket
2. Update tests
3. Push changes by end of day
```

**4. Explain your reasoning**
```markdown
I considered approach X, but chose Y because:
- Performance: Y is 10x faster
- Maintenance: Y follows existing patterns
- Testing: Y is easier to test

Open to alternatives if you see issues with Y.
```

**5. Update the PR**
- Make requested changes
- Push new commits
- Comment when ready for re-review

**6. Mark conversations resolved**
- After addressing feedback
- Helps reviewers track progress

### DON'T ❌

**1. Take feedback personally**
- Review is about code, not you
- Assume positive intent
- Everyone wants the project to succeed

**2. Argue defensively**
```markdown
❌ "This is how I always do it"
❌ "The old code was worse"
❌ "This is good enough"

✅ "I see your point. Let me refactor."
✅ "Good catch! I missed that."
✅ "Interesting approach. Which would you prefer?"
```

**3. Ignore feedback**
- Address every comment
- If you disagree, explain why respectfully
- Don't merge without addressing concerns

**4. Force push without warning**
```bash
❌ git push --force

✅ git push --force-with-lease  # Safer
✅ Comment: "Force pushed to rebase"
```

**Why:** Force push loses review context if not communicated.

**5. Add unrelated changes**
- Keep PR focused
- If you spot other issues, open separate PRs
- Easier to review, safer to merge

---

## Becoming a Reviewer

### When You're Ready

You don't need to be an expert to review!

**You can review when you:**
- Understand the code being changed
- Know what the code should do
- Can spot basic issues (syntax, logic, security)

**You don't need to:**
- Understand every line of the entire codebase
- Be a Terraform/Kubernetes expert
- Have written similar code before

### How to Add Yourself

1. Contribute regularly
2. Build trust with maintainers
3. Ask to be added to OWNERS file
4. Start with `reviewers:` list
5. Eventually move to `approvers:` list

### Good Review Practices

**DO:**
- Review promptly (within 48 hours)
- Be specific in feedback
- Explain *why*, not just *what*
- Suggest solutions, don't just criticize
- Praise good work

**DON'T:**
- Nitpick trivial style issues
- Block PRs for personal preferences
- Review outside your expertise without disclaimer
- Approve without reading carefully

---

## Review Examples

### Good Review Comments

**Specific and actionable:**
```markdown
Line 45: This S3 bucket should have versioning enabled to
prevent accidental data loss.

Suggested fix:
```hcl
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}
```
```

**Educational:**
```markdown
This works, but consider using a module instead for consistency:

```hcl
module "bucket" {
  source = "../../modules/secure-bucket"
  name   = "artifacts"
}
```

This module includes versioning, encryption, and public access
blocking by default. See modules/secure-bucket/README.md.
```

**Acknowledging good work:**
```markdown
Nice use of locals to DRY up the tag definitions! This makes it
much easier to maintain consistent tags.

One small suggestion: consider extracting the common_tags to a
separate file (locals.tf) since they might be useful for future
resources too.
```

### Poor Review Comments

**Vague:**
```markdown
❌ "This doesn't look right"

✅ "Line 23: This IAM policy grants * permissions which is too
broad. Can we restrict to specific actions needed?"
```

**Unnecessarily harsh:**
```markdown
❌ "Why would you do it this way? This is terrible."

✅ "Have you considered approach X? It might be simpler because..."
```

**Bikeshedding:**
```markdown
❌ "Rename variable from 'cnt' to 'count'"
(when it's clear and used only once)

✅ Save energy for significant issues
```

---

## Handling Disagreements

### Respectful Disagreement

**Reviewer:** "I think we should use approach X"
**Author:** "I considered X, but chose Y because..."

**Resolution paths:**
1. Author convinces reviewer (Y is better)
2. Reviewer convinces author (X is better)
3. Compromise (parts of both X and Y)
4. Escalate to maintainer for decision

### When to Escalate

Escalate to SIG leads or maintainers when:
- Technical disagreement can't be resolved
- Security concern needs expert opinion
- Architectural decision affects multiple teams
- Policy interpretation unclear

**How to escalate:**
```markdown
@sig-k8s-infra-leads We've hit a decision point on this PR
and would appreciate guidance:

Context: [explain the situation]
Option A: [approach 1 with pros/cons]
Option B: [approach 2 with pros/cons]
Our perspectives: [summarize discussion]

Which direction should we take?
```

---

## Special Cases

### Urgent Changes (Outages)

**Fast-track process:**
1. Label PR: `/kind bug` and `/priority critical-urgent`
2. Ping reviewers in Slack: #sig-k8s-infra
3. Accept "LGTM" in Slack as approval
4. Follow up with formal review post-merge

**Still required:**
- Basic correctness check
- Security review
- Testing (even if brief)

**Never skip:**
- Peer review (even if quick)
- Testing in canary (if possible)

### Security Changes

**Extra scrutiny:**
- Additional security-focused reviewer
- Threat modeling discussion
- Testing for vulnerabilities
- Checking for compliance requirements

**May require:**
- Security SIG review
- Penetration testing
- Audit trail documentation

### Large Refactors

**Special considerations:**
- Break into smaller PRs when possible
- Provide migration plan
- Consider feature flags for gradual rollout
- Extra testing required

**Review focus:**
- Does refactor maintain existing behavior?
- Is there a rollback plan?
- Are risks documented?

---

## After Merge

### Monitor Your Changes

After PR merges:
- Watch ArgoCD deployments
- Monitor Slack for alerts
- Check logs and metrics
- Be available for questions

### Rollback if Needed

If problems arise:
- Communicate in Slack immediately
- Open revert PR or manual rollback
- Document issue in original PR
- File issue for proper fix

### Learn and Improve

After successful merge:
- Reflect on review feedback
- Update documentation if gaps found
- Share learnings with team

---

## Getting Help with Review

### Stuck in Review

If your PR isn't getting attention:

**After 2 business days:**
- Comment gentle ping on PR
- Check if reviewers are assigned

**After 4 business days:**
- Ping in #sig-k8s-infra Slack
- Ask if you need to add reviewers

**After 1 week:**
- Bring up in SIG meeting
- Ask maintainers for help

### Unclear Feedback

If review feedback is confusing:

**Ask for clarification:**
```markdown
@reviewer I want to make sure I understand your concern.
Are you suggesting that [interpretation]?
If so, would [proposed solution] address it?
```

**Jump on a call:**
```markdown
This might be easier to discuss synchronously. Can we schedule
a quick call? I'm available [times].
```

---

## Review Checklist

### For Authors

Before requesting review:
- [ ] Code is tested
- [ ] Terraform plan reviewed
- [ ] Documentation updated
- [ ] Commit messages clear
- [ ] PR description explains why
- [ ] Related issues linked
- [ ] CI checks passing

### For Reviewers

Before approving:
- [ ] Understand what change does
- [ ] Understand why change is needed
- [ ] Code is correct and safe
- [ ] Tests are adequate
- [ ] Documentation is updated
- [ ] Terraform plan is reasonable
- [ ] Security implications considered
- [ ] Rollback plan exists (for risky changes)

---

**Related:**
- [Contribution Workflow](contribution-workflow.md) - Full PR process
- [Making Changes](../03-development/making-changes.md) - How to make changes
- [Repository Overview](../01-getting-started/repository-overview.md) - Ownership model
