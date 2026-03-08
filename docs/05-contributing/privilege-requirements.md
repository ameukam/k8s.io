# Privilege Requirements & Approval Matrix

**Understanding what you can do and what requires approval from technical leads.**

---

## Overview

The k8s.io infrastructure follows the **principle of least privilege**. Most contributors work through Pull Requests without needing direct cloud access. This document clarifies what requires elevated privileges or technical lead approval.

---

## Contribution Levels

### Level 1: Anyone (No Special Access)

**What you can do:**
- Fork the repository
- Open Pull Requests
- Propose infrastructure changes
- Propose application changes
- Propose documentation improvements
- Comment on issues and PRs
- Review code (non-binding)

**What happens to your PR:**
- Automated checks run (Atlantis plan, CI tests)
- OWNERS review your changes
- If approved, OWNERS or automation merges
- Infrastructure changes applied by Atlantis (not you)

**No cloud credentials needed!**

---

### Level 2: Reviewers (in OWNERS files)

**Additional capabilities:**
- Give technical review (`/lgtm`)
- Request changes on PRs
- Help triage issues

**Requirements:**
- Regular contributor to the area
- Familiar with the codebase
- Added to OWNERS file by approvers

**Still cannot:**
- Merge PRs independently (`/approve` needed)
- Apply Terraform directly
- Access cloud consoles

---

### Level 3: Approvers (in OWNERS files)

**Additional capabilities:**
- Final approval (`/approve`) for merges
- Trigger `atlantis apply` after approval
- Merge PRs in their area

**Requirements:**
- Consistent high-quality contributions
- Deep knowledge of the area
- Trust from sig-k8s-infra leads

**Still cannot:**
- Create new cloud accounts
- Modify organization settings
- Access production credentials directly

---

### Level 4: SIG-K8s-Infra Members

**Additional capabilities:**
- Read-only cloud console access (limited)
- View monitoring and logs
- Debug production issues
- Access to some Google Groups

**Requirements:**
- Active contributor to infrastructure
- Approved by sig-k8s-infra leads
- Google Group membership

**Typical access:**
- GCP: Viewer roles in most projects
- AWS: EKSInfraViewer role for clusters
- Limited Secret Manager access

---

### Level 5: SIG-K8s-Infra Leads

**Full capabilities:**
- Create new cloud accounts/projects
- Modify organization settings
- Emergency production access
- Approve major architectural changes
- Manage OWNERS files
- Grant access to contributors

**Requirements:**
- Elected or appointed sig-k8s-infra leadership
- Years of infrastructure contributions
- Trusted by Kubernetes community

---

## Operations Requiring Approval

### ⚠️ Always Requires SIG Lead Approval

These operations **MUST** have explicit approval from sig-k8s-infra leads before proceeding:

| Operation | Why Lead Approval Needed | How to Request |
|-----------|-------------------------|----------------|
| **Create new AWS account** | Impacts billing, organization structure | Propose in sig-k8s-infra meeting |
| **Create new GCP project** | Requires org-admin permissions | Propose in sig-k8s-infra meeting |
| **Modify AWS Organizations** | Can affect all accounts | PR + meeting discussion |
| **Change core DNS** (kubernetes.io, k8s.io) | Affects all Kubernetes users | PR + thorough review + lead approval |
| **Create new cloud billing account** | Financial implications | Meeting discussion + community approval |
| **Grant org-level IAM permissions** | Security sensitive | Case-by-case review |
| **Delete production infrastructure** | Data loss risk | Emergency procedures only |
| **Modify Atlantis configuration** | Affects CI/CD pipeline | PR + security review |
| **Access production secrets** | Credential exposure risk | Justification + time-limited access |
| **Major architectural changes** | Affects entire project | RFC + sig-k8s-infra approval |

**Process:**
1. Write proposal/RFC
2. Present in sig-k8s-infra meeting
3. Get consensus from leads
4. Document decision
5. Proceed with implementation

---

### 📋 Requires OWNERS Approval (Standard PR Process)

These go through normal PR workflow but need `/approve` from area OWNERS:

| Operation | Approval Needed |
|-----------|-----------------|
| **Terraform infrastructure changes** | OWNERS in affected directory |
| **Kubernetes application updates** | Application OWNERS |
| **IAM role modifications** | Security-focused OWNERS |
| **Cost-impacting changes** | Cost-aware OWNERS + lead notification |
| **Production cluster changes** | Cluster OWNERS + careful review |
| **DNS record changes** | DNS OWNERS |
| **Policy changes** (OPA/Conftest) | Policy OWNERS |

**Process:**
1. Open PR
2. Atlantis runs `terraform plan`
3. OWNERS review changes
4. Get `/lgtm` from reviewer
5. Get `/approve` from OWNERS
6. Merge (or `atlantis apply` first for some)

---

### 🔒 Access Requiring Membership

These require Google Group membership or similar access grants:

| Access Type | Required Membership | Purpose |
|-------------|---------------------|---------|
| **GCP Console (Read)** | k8s-infra-gcp-org-viewers@ | View GCP resources |
| **AWS Console (Read)** | k8s-infra-aws-viewers@ | View AWS resources |
| **GCP Console (Admin)** | k8s-infra-gcp-org-admins@ | Emergency access |
| **AWS Console (Admin)** | k8s-infra-aws-admins@ | Emergency access |
| **Cost Dashboard Access** | sig-k8s-infra@ | View billing reports |
| **Prow Oncall Access** | k8s-infra-prow-oncall@ | Debugging CI/CD |
| **Secret Manager Access** | Case-by-case grants | Accessing sensitive data |

**Request process:**
1. Ask in #sig-k8s-infra Slack
2. Explain why you need access
3. Leads approve/deny
4. Access granted (time-limited if appropriate)

---

## What You Should Never Do

### 🚫 Prohibited Actions (Even for Leads)

1. **Commit secrets to git**
   - Use Secret Manager / Secrets Operator
   - Secrets in git = security incident

2. **Make manual changes in cloud consoles**
   - Everything must be in Terraform
   - Exception: Emergency troubleshooting (document afterward)

3. **Share credentials**
   - Each person has their own access
   - No sharing API keys, passwords, SSH keys

4. **Bypass code review**
   - Even emergency fixes need PR (can be post-merge)
   - Document why review was bypassed

5. **Apply Terraform without plan review**
   - Always `terraform plan` first
   - Have someone else review plan output

6. **Modify production state files directly**
   - Extreme danger
   - State corruption = infrastructure loss
   - Only under expert guidance

7. **Delete backups**
   - S3 versioning exists for a reason
   - Terraform state backups are sacred

8. **Disable safety features**
   - `prevent_destroy = true` is there for a reason
   - Permission boundaries protect against escalation
   - Don't remove without discussion

---

## Emergency Procedures

### When Lead Access IS Needed

**Legitimate emergencies:**
- Production outage affecting Kubernetes users
- Security incident requiring immediate action
- CI/CD pipeline completely broken
- Data loss prevention

**Emergency process:**
1. Announce in #sig-k8s-infra Slack
2. Explain the emergency
3. Leads grant temporary elevated access
4. Fix the issue
5. Document actions taken
6. Create follow-up PR with fix
7. Postmortem (what went wrong, how to prevent)

### When to Escalate

**Escalate to sig-k8s-infra leads when:**
- Unsure if you have permission for an action
- Change affects multiple teams
- Security implications unclear
- Cost impact > $1000/month
- Irreversible operations (deletions)
- Architecture decisions

**Don't be afraid to ask!** Better to ask than:
- Break production
- Make unauthorized changes
- Create security issues
- Waste money on wrong approach

---

## Getting More Access

### Path to Increased Privileges

**1. Start Contributing (Level 1)**
- Open PRs with good descriptions
- Respond to review feedback
- Fix issues in your area of interest

**2. Become a Regular Reviewer (Level 2)**
- Review others' PRs
- Provide helpful feedback
- Show domain expertise
- Ask to be added to OWNERS as reviewer

**3. Become an Approver (Level 3)**
- Consistent high-quality reviews
- Show good judgment
- Understand implications of changes
- Propose to add yourself as approver (with sponsor)

**4. Join SIG-K8s-Infra (Level 4)**
- Active participation in sig meetings
- Regular infrastructure contributions
- Request membership in sig-k8s-infra meetings

**5. Become a Lead (Level 5)**
- Years of community contribution
- Demonstrated leadership
- Election or appointment by community

**Timeline:**
- Level 1 → Level 2: 3-6 months of consistent contributions
- Level 2 → Level 3: 6-12 months as reviewer
- Level 3 → Level 4: Usually happens naturally
- Level 4 → Level 5: Years of service

---

## Access Verification

### How to Check Your Access Level

**Check Google Group membership:**
```bash
# Visit
https://groups.google.com/a/kubernetes.io/

# Check if you're in:
# - sig-k8s-infra@kubernetes.io
# - k8s-infra-gcp-org-viewers@kubernetes.io
# - k8s-infra-prow-oncall@kubernetes.io
```

**Check OWNERS files:**
```bash
# Find files listing you
git grep "your-github-username" "**/OWNERS"
```

**Test cloud access:**
```bash
# GCP
gcloud projects list

# AWS
aws sts get-caller-identity
```

---

## FAQ

**Q: I need access to debug an issue. How do I get it?**
A: Ask in #sig-k8s-infra Slack, explain what you need and why. Leads will grant time-limited access if appropriate.

**Q: Can I apply Terraform myself to speed up my PR?**
A: No. Atlantis handles all Terraform applies. This ensures audit trail and prevents accidents.

**Q: I found a security issue. Who do I tell?**
A: Email security@kubernetes.io (private list). Don't post publicly until fixed.

**Q: My PR needs urgent merge for production fix. Can I self-approve?**
A: No. Even urgent fixes need OWNERS approval. Ping in Slack for fast review.

**Q: I accidentally committed a secret. What do I do?**
A: 1) Immediately revoke the secret, 2) Notify #sig-k8s-infra, 3) Rewrite git history, 4) Investigate if used maliciously.

**Q: The docs say I need lead approval but leads aren't responding. What do I do?**
A: Ping in multiple sig meetings, post in #sig-k8s-infra Slack, be patient. If truly urgent, contact Kubernetes steering committee.

---

## Additional Resources

- **Slack:** #sig-k8s-infra on Kubernetes Slack
- **Meetings:** [SIG-K8s-Infra schedule](https://github.com/kubernetes/community/tree/master/sig-k8s-infra#meetings)
- **Mailing List:** sig-k8s-infra@kubernetes.io
- **OWNERS Files:** Check directories you're modifying for current approvers

---

**Remember:** The privilege system exists to protect production infrastructure while enabling community contributions. When in doubt, ask!
