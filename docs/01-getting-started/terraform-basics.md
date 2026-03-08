# Terraform Basics

**In this guide:** Learn Terraform fundamentals from scratch - what it is, why we use it, and how to read Terraform code.

**Time to read:** ~15 minutes

**Prerequisites:** None! This starts from zero.

---

## What is Terraform?

Terraform is an **infrastructure-as-code** (IaC) tool. Instead of clicking through cloud provider web consoles to create resources, you write code that describes what infrastructure you want, and Terraform creates it for you.

### Why Infrastructure as Code?

**Without IaC (manual approach):**
```
1. Log into AWS console
2. Click "Create S3 bucket"
3. Type name: "k8s-artifacts-prod"
4. Click through 6 configuration screens
5. Hope you remembered all the settings
6. Repeat for 50 more buckets
7. Forget what you created 6 months later
```

**With IaC (Terraform approach):**
```hcl
resource "aws_s3_bucket" "artifacts" {
  bucket = "k8s-artifacts-prod"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
  }
}
```

**Benefits:**
- **Reproducible**: Run the same code, get the same infrastructure every time
- **Version controlled**: Track changes in git like application code
- **Documented**: The code IS the documentation of what exists
- **Reviewable**: Team members can review infrastructure changes before they happen
- **Automated**: CI/CD can apply infrastructure changes automatically

## Core Concepts

### 1. Resources

A **resource** is something you want to create in a cloud provider - like an S3 bucket, a virtual machine, or a DNS record.

```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "example-bucket-name"
}
```

**Anatomy:**
- `resource` - Terraform keyword
- `"aws_s3_bucket"` - Resource type (AWS provider, S3 bucket)
- `"my_bucket"` - Local name (how you reference this in your code)
- `{ ... }` - Configuration block

### 2. Providers

A **provider** is a plugin that knows how to talk to a cloud service (AWS, GCP, Azure, etc.).

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Before Terraform can create AWS resources, you need to configure the AWS provider.

### 3. State

Terraform needs to remember what infrastructure it has created. It stores this in a **state file** (usually `terraform.tfstate`).

**Think of state like a database:**
```
State file contains:
- "We created S3 bucket 'k8s-artifacts-prod' with ID xyz123"
- "We created EC2 instance 'build-server' with IP 10.0.1.5"
- "These resources depend on each other in this order"
```

**Why state matters:**
- **Prevents duplicates**: Running `terraform apply` twice won't create duplicate resources
- **Tracks relationships**: Knows which resources depend on others
- **Enables updates**: Compares desired state (your code) with actual state (what exists)
- **Allows deletion**: Knows what to delete when you remove code

**State storage:**
- **Local**: State file on your computer (bad for teams)
- **Remote**: State file in cloud storage like S3 (good for teams)

In this repository, state is stored remotely so multiple people can work on the infrastructure.

### 4. Modules

A **module** is a reusable package of Terraform code. Like a function in programming.

**Without modules (repetitive):**
```hcl
resource "aws_s3_bucket" "bucket1" {
  bucket = "app1-logs"
  versioning { enabled = true }
  encryption { enabled = true }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "app2-logs"
  versioning { enabled = true }
  encryption { enabled = true }
}
```

**With modules (DRY):**
```hcl
module "app1_logs" {
  source = "./modules/secure-bucket"
  name   = "app1-logs"
}

module "app2_logs" {
  source = "./modules/secure-bucket"
  name   = "app2-logs"
}
```

The `modules/secure-bucket` directory contains reusable bucket configuration.

### 5. Variables

Variables let you parameterize your Terraform code.

**Input variables** - Configuration you pass in:
```hcl
variable "environment" {
  type    = string
  default = "staging"
}

resource "aws_s3_bucket" "data" {
  bucket = "myapp-${var.environment}-data"
  # Creates "myapp-staging-data" or "myapp-production-data"
}
```

**Output values** - Information to expose:
```hcl
output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}
```

Outputs are useful when other modules need information from this module.

### 6. Data Sources

A **data source** queries existing infrastructure without creating anything.

```hcl
data "aws_vpc" "existing" {
  default = true
}

resource "aws_subnet" "new" {
  vpc_id = data.aws_vpc.existing.id  # Use existing VPC's ID
}
```

**Use cases:**
- Reference resources created outside Terraform
- Look up AMI IDs, availability zones, etc.
- Share information between separate Terraform configurations

## Terraform Workflow

### The Plan-Apply Cycle

Terraform has two main commands:

#### 1. `terraform plan`
**What it does:** Shows what Terraform WOULD do, without actually doing it.

```bash
$ terraform plan

Terraform will perform the following actions:

  # aws_s3_bucket.artifacts will be created
  + resource "aws_s3_bucket" "artifacts" {
      + bucket = "k8s-artifacts-prod"
      + id     = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Think of it as:** Git diff for infrastructure

#### 2. `terraform apply`
**What it does:** Actually creates/modifies/destroys infrastructure to match your code.

```bash
$ terraform apply

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.artifacts: Creating...
aws_s3_bucket.artifacts: Creation complete after 2s [id=k8s-artifacts-prod]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Think of it as:** Git push for infrastructure

### Safe Workflow

```
1. Make changes to .tf files
2. Run `terraform plan` - review what will change
3. If changes look good, run `terraform apply`
4. If not, modify .tf files and plan again
```

**Always plan before applying!** Terraform can delete production infrastructure if you tell it to.

## Reading Terraform Code

Let's break down a real example:

```hcl
# This is a comment

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket for storing artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "k8s-artifacts-prod"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Output the bucket name for use elsewhere
output "artifacts_bucket_name" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "Name of the artifacts S3 bucket"
}
```

**Key observations:**

1. **Comments use `#`** - Explain intent, not just what the code does

2. **Blocks have structure:**
   ```hcl
   block_type "type_label" "name_label" {
     argument = value
   }
   ```

3. **References use dot notation:**
   ```hcl
   aws_s3_bucket.artifacts.id
   # ^resource_type  ^name   ^attribute
   ```

4. **Resources of same type can depend on each other:**
   - `aws_s3_bucket_versioning` references `aws_s3_bucket.artifacts.id`
   - Terraform knows to create bucket before configuring versioning

## Common Terraform Files

You'll see these files in Terraform directories:

| File | Purpose |
|------|---------|
| `main.tf` | Primary resource definitions |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value definitions |
| `versions.tf` | Required Terraform/provider versions |
| `terraform.tf` | Terraform configuration (state backend, etc.) |
| `providers.tf` | Provider configurations |
| `data.tf` | Data source queries |

**Note:** These are conventions, not requirements. You can name files anything ending in `.tf`.

## HCL Syntax Basics

Terraform uses **HCL** (HashiCorp Configuration Language). It's like JSON but more human-friendly.

### Basic Types

```hcl
# String
name = "kubernetes"

# Number
count = 3

# Boolean
enabled = true

# List
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Map (object)
tags = {
  Environment = "prod"
  Team        = "sig-k8s-infra"
}
```

### Expressions

```hcl
# String interpolation
bucket_name = "logs-${var.environment}"

# Conditional
instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"

# For each
instance_ids = [for i in aws_instance.servers : i.id]
```

### Functions

Terraform has built-in functions:

```hcl
# String manipulation
upper("kubernetes")  # "KUBERNETES"
lower("PROD")        # "prod"

# Collections
length(["a", "b", "c"])  # 3
concat([1, 2], [3, 4])   # [1, 2, 3, 4]

# Filesystem
file("config.yaml")      # Read file contents

# Encoding
jsonencode({a = "b"})    # {"a":"b"}
```

## What Terraform Doesn't Do

Important limitations to understand:

❌ **Configuration management** - Terraform creates infrastructure, but doesn't configure what runs inside VMs (use Ansible/Chef for that)

❌ **Application deployment** - Terraform sets up infrastructure, but doesn't deploy application code (use CI/CD for that)

❌ **Real-time monitoring** - Terraform describes desired state, but doesn't monitor running resources (use monitoring tools for that)

✅ **What Terraform DOES:** Provision and manage infrastructure resources declaratively

## Key Takeaways

1. **Terraform is declarative**: You describe what you want, not how to create it
2. **State is crucial**: Terraform tracks what it has created
3. **Always plan before apply**: Review changes before making them
4. **Resources are the building blocks**: Each resource is one piece of infrastructure
5. **Modules enable reuse**: Package common patterns into reusable modules

## Common Beginner Questions

**Q: What happens if I delete a resource from my .tf file?**
A: Terraform will destroy that resource in the cloud on the next `apply`. Be careful!

**Q: Can I import existing infrastructure into Terraform?**
A: Yes! Use `terraform import` to bring existing resources under Terraform management.

**Q: What if two people run `terraform apply` at the same time?**
A: Terraform uses state locking (with remote state) to prevent this. One person will get a lock, the other will wait.

**Q: How do I handle secrets like passwords?**
A: Never put secrets in .tf files! Use environment variables, secret management services, or tools like Terraform Cloud.

**Q: Do I need to understand every resource type?**
A: No! Start with reading what's already there. Look up unfamiliar resource types in the provider documentation.

---

**Next Steps:**
- Read [Repository Overview](repository-overview.md) to see how Terraform organizes Kubernetes infrastructure
- Check [Reading Terraform](../03-development/reading-terraform.md) for tips on understanding existing code
