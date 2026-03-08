# Reading Terraform Code

**In this guide:** Practical tips for understanding Terraform configurations in this repository.

**Time to read:** ~12 minutes

**Prerequisites:** [Terraform Basics](../01-getting-started/terraform-basics.md)

---

## Before You Start

Reading Terraform is different from reading application code:
- **Declarative, not imperative**: It describes WHAT exists, not HOW to create it
- **Order doesn't matter** (mostly): Terraform figures out dependencies automatically
- **Implicit relationships**: Resources reference each other, creating dependency graphs

## Reading Strategy

### 1. Start with the README
Most Terraform directories have a README explaining:
- What infrastructure this manages
- Prerequisites for applying it
- Special considerations

### 2. Identify the Entry Point
Look for these files first:
- `main.tf` - Primary resource definitions
- `terraform.tf` - Backend and Terraform config
- `providers.tf` - Provider configuration (AWS, GCP, etc.)
- `variables.tf` - Input parameters

### 3. Follow the Data Flow
```
variables.tf → main.tf → outputs.tf
    ↓            ↓           ↓
  Inputs    Resources    Outputs
```

### 4. Trace Dependencies
When you see a reference like `aws_vpc.main.id`, find the `aws_vpc` resource named `main` to understand what it provides.

## Understanding Resource Blocks

### Anatomy of a Resource

```hcl
resource "aws_s3_bucket" "artifacts" {
  bucket = "k8s-artifacts-${var.environment}"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "sig-k8s-infra"
  }
}
```

**Reading this:**
1. **Type**: `aws_s3_bucket` - Creates an S3 bucket in AWS
2. **Name**: `artifacts` - How this resource is referenced elsewhere
3. **Bucket name**: Uses string interpolation with a variable
4. **Tags**: Metadata attached to the resource

**Key questions to ask:**
- What cloud resource is this? (S3 bucket)
- What's it called? (k8s-artifacts-${var.environment})
- Is it referenced by other resources? (Search for `aws_s3_bucket.artifacts`)
- Does it depend on other resources? (Look for references to other resources)

### Understanding Dependencies

Terraform automatically determines order based on references:

```hcl
# Created first - no dependencies
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Created second - depends on VPC
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # References VPC above
  cidr_block = "10.0.1.0/24"
}

# Created third - depends on subnet
resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id  # References subnet above
  # ...
}
```

**Reading order:**
1. Find resources with NO references to other resources (roots)
2. Follow references to see what depends on what
3. Terraform handles the execution order automatically

### Explicit Dependencies

Sometimes you need to force ordering:

```hcl
resource "aws_iam_role" "build" {
  name = "prow-build-role"
  # ...
}

resource "aws_iam_role_policy_attachment" "build" {
  role       = aws_iam_role.build.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"

  # Ensure role exists before attaching policy
  depends_on = [aws_iam_role.build]
}
```

The `depends_on` makes dependencies explicit when Terraform can't infer them.

## Reading Variables

### Variable Declarations

```hcl
variable "environment" {
  type        = string
  description = "Environment name (prod, staging, dev)"
  default     = "dev"
}

variable "instance_count" {
  type = number
}

variable "enable_monitoring" {
  type    = bool
  default = true
}
```

**Reading this:**
- `environment` - Optional (has default), string type
- `instance_count` - Required (no default), number type
- `enable_monitoring` - Optional boolean that defaults to true

### Variable Usage

Variables are referenced with `var.`:

```hcl
resource "aws_instance" "app" {
  count         = var.instance_count
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"

  tags = {
    Environment = var.environment
  }
}
```

**Trace where values come from:**
1. Check `variables.tf` for defaults
2. Look for `*.tfvars` files (variable value files)
3. Environment variables: `TF_VAR_<name>`
4. Command-line flags: `-var="name=value"`

## Reading Modules

### Module Calls

```hcl
module "build_cluster" {
  source = "./modules/eks-cluster"

  cluster_name = "prow-build"
  region       = "us-east-1"
  node_count   = 3

  tags = local.common_tags
}
```

**Reading this:**
1. **Source**: Where the module code lives (`./modules/eks-cluster/`)
2. **Inputs**: Values passed to the module (cluster_name, region, etc.)
3. **Module outputs**: Referenced elsewhere as `module.build_cluster.<output_name>`

### Understanding Module Structure

When you see a module call, navigate to the source directory:

```
modules/eks-cluster/
├── main.tf        # Module resources
├── variables.tf   # Module inputs (what you pass in)
├── outputs.tf     # Module outputs (what it returns)
└── README.md      # Module documentation
```

**Reading a module:**
1. Read `README.md` for overview
2. Check `variables.tf` to see what inputs it needs
3. Check `outputs.tf` to see what information it exposes
4. Read `main.tf` to understand what resources it creates

### Module Outputs

Modules expose information via outputs:

```hcl
# Inside module: modules/eks-cluster/outputs.tf
output "cluster_id" {
  value = aws_eks_cluster.main.id
}

# Using module output: main.tf
resource "aws_iam_role" "nodes" {
  # ...
}

resource "aws_eks_node_group" "main" {
  cluster_name = module.build_cluster.cluster_id  # Using module output
  # ...
}
```

## Reading Data Sources

Data sources query existing infrastructure:

```hcl
# Look up existing VPC
data "aws_vpc" "existing" {
  default = true
}

# Look up available zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Use in resources
resource "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.existing.id
  availability_zone = data.aws_availability_zones.available.names[0]
  # ...
}
```

**Key distinction:**
- **Resources** (`resource`): Terraform creates and manages
- **Data sources** (`data`): Terraform only reads, doesn't manage

**Reference syntax:**
- Resources: `aws_vpc.existing.id`
- Data sources: `data.aws_vpc.existing.id`

## Understanding Locals

Locals are computed values used within a configuration:

```hcl
locals {
  common_tags = {
    ManagedBy   = "terraform"
    Project     = "k8s-infra"
    Environment = var.environment
  }

  cluster_name = "prow-${var.environment}-${var.region}"

  # Conditional logic
  use_spot_instances = var.environment != "prod"
}

resource "aws_instance" "app" {
  tags = local.common_tags  # Reference local value
  # ...
}
```

**Why use locals:**
- **DRY**: Define once, use many times
- **Computed values**: Combine variables and logic
- **Readability**: Give complex expressions meaningful names

## Reading Terraform Configuration

### Backend Configuration

```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "k8s-infra-terraform-state"
    key            = "prow-build-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Reading this:**
- **State storage**: S3 bucket with encryption
- **State locking**: DynamoDB table prevents concurrent applies
- **Terraform version**: Requires 1.0 or later
- **Provider version**: AWS provider ~> 5.0 (major version 5.x)

### Provider Configuration

```hcl
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "k8s-infra"
    }
  }
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}
```

**Reading this:**
- **Default provider**: Uses `var.region`
- **Default tags**: Automatically applied to all resources
- **Aliased provider**: For multi-region deployments

**Using aliased providers:**
```hcl
resource "aws_s3_bucket" "west_coast" {
  provider = aws.us-west-2  # Use the aliased provider
  bucket   = "k8s-artifacts-west"
}
```

## Common Patterns in This Repository

### 1. Environment-Based Naming

```hcl
resource "aws_s3_bucket" "artifacts" {
  bucket = "k8s-${var.environment}-artifacts"
  # Creates: k8s-prod-artifacts, k8s-staging-artifacts, etc.
}
```

### 2. Conditional Resource Creation

```hcl
resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0
  # Creates 1 instance if enabled, 0 if disabled
  # ...
}
```

### 3. Dynamic Blocks

```hcl
resource "aws_security_group" "app" {
  name = "app-sg"

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

**Reading dynamic blocks:**
- Loops over `var.allowed_ports` list
- Creates one `ingress` block per port
- `ingress.value` is the current loop item

### 4. For Expressions

```hcl
locals {
  instance_ids = [for instance in aws_instance.app : instance.id]
  # Creates list: ["i-abc123", "i-def456", "i-ghi789"]

  instance_map = {
    for instance in aws_instance.app : instance.id => instance.private_ip
  }
  # Creates map: {"i-abc123" = "10.0.1.5", "i-def456" = "10.0.1.6"}
}
```

### 5. Lifecycle Rules

```hcl
resource "aws_instance" "app" {
  # ...

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [tags]
  }
}
```

**Reading lifecycle:**
- `create_before_destroy` - Create replacement before destroying old
- `prevent_destroy` - Fail if trying to destroy (protection)
- `ignore_changes` - Don't detect drift for these attributes

## Debugging Terraform Code

### Understanding Terraform Plan Output

```
Terraform will perform the following actions:

  # aws_s3_bucket.artifacts will be created
  + resource "aws_s3_bucket" "artifacts" {
      + bucket = "k8s-prod-artifacts"
      + id     = (known after apply)
    }

  # aws_s3_bucket.logs must be replaced
-/+ resource "aws_s3_bucket" "logs" {
      ~ bucket = "k8s-logs" -> "k8s-prod-logs" # forces replacement
      + id     = (known after apply)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

**Symbols:**
- `+` - Will create
- `-` - Will destroy
- `~` - Will update in-place
- `-/+` - Will destroy then recreate (replacement)
- `(known after apply)` - Value determined during apply

### Finding Why Something is Being Replaced

Look for `# forces replacement` comments in the plan:

```
~ bucket = "old-name" -> "new-name" # forces replacement
```

Certain attributes can't be changed without recreating the resource. AWS resources have different rules about what can be updated in-place.

## Tips for Reading Unfamiliar Code

### 1. Start Small
Don't try to understand an entire configuration at once. Pick one resource and understand it fully.

### 2. Use the Terraform Registry
For unfamiliar resource types, search the [Terraform Registry](https://registry.terraform.io):
- Find the provider (e.g., `hashicorp/aws`)
- Search for the resource type (e.g., `aws_s3_bucket`)
- Read documentation and examples

### 3. Trace One Flow
Pick one resource you're interested in (e.g., an S3 bucket) and trace:
- Where are its inputs defined? (variables)
- What resources does it depend on? (references)
- What resources depend on it? (search for references to it)
- What outputs expose it? (outputs)

### 4. Draw the Graph
For complex configurations, sketch the dependency graph:
```
VPC → Subnet → Instance
        ↓
   Security Group
```

### 5. Use `terraform graph`
Generate a visual dependency graph:
```bash
terraform graph | dot -Tpng > graph.png
```

Requires GraphViz installed (`brew install graphviz` on Mac).

## Common Gotchas

### 1. Count vs For_Each
```hcl
# Count - accessed by index
resource "aws_instance" "app" {
  count = 3
  # Reference: aws_instance.app[0], aws_instance.app[1], aws_instance.app[2]
}

# For_each - accessed by key
resource "aws_instance" "app" {
  for_each = toset(["web", "api", "worker"])
  # Reference: aws_instance.app["web"], aws_instance.app["api"]
}
```

### 2. Implicit vs Explicit Dependencies
Terraform usually figures out dependencies, but sometimes you need `depends_on`:
```hcl
resource "aws_iam_role_policy" "example" {
  # Implicit dependency - Terraform sees the reference
  role = aws_iam_role.example.id

  # Explicit dependency - forces ordering even without reference
  depends_on = [aws_iam_role.example]
}
```

### 3. Sensitive Values
```hcl
variable "db_password" {
  sensitive = true
}
```

Sensitive values are hidden in output: `(sensitive value)` instead of actual value.

## Checklist for Understanding a Configuration

- [ ] Read README or comments explaining purpose
- [ ] Check `terraform.tf` for backend and version requirements
- [ ] Check `providers.tf` for provider configuration
- [ ] Read `variables.tf` to understand inputs
- [ ] Identify root resources (no dependencies)
- [ ] Trace dependencies between resources
- [ ] Check `outputs.tf` for exposed values
- [ ] Look for modules and understand their purpose
- [ ] Note any lifecycle rules or special configurations

---

**Next Steps:**
- Learn about [Common Patterns](common-patterns.md) specific to this repository
- Practice by reading actual configurations in `infra/` directories
- Try [Making Changes](making-changes.md) to practice hands-on
