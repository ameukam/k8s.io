locals {
  cluster_version = "1.23"
  region          = "us-east-2"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  name            = "prow-build"
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  provider = aws.prow
  name     = module.eks_blueprints.eks_cluster_id
}

data "aws_availability_zones" "available" {
  provider = aws.prow
}


module "vpc" {
  providers = {
    aws = aws.prow
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "k8s-infra-aws-prow-build-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  public_subnet_ipv6_prefixes  = [0, 1, 2]
  private_subnet_ipv6_prefixes = [3, 4, 5]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = true

  enable_dns_hostnames            = true
  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  create_egress_only_igw          = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }
}

data "aws_ami" "latest_ubuntu" {
  provider = aws.prow

  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${local.cluster_version}/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "eks_blueprints" {
  providers = {
    aws = aws.prow
  }

  source = "github.com/aws-ia/terraform-aws-eks-blueprints"
  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  # EKS CONTROL PLANE VARIABLES
  create_eks      = true
  cluster_version = local.cluster_version
  cluster_name    = local.name

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  self_managed_node_groups = {
    self_mg1 = {
      node_group_name = "self_mg1"
      subnet_type     = "private"
      subnet_ids      = module.vpc.private_subnets
      eni_delete        = true
      public_ip = false

      custom_ami_id = data.aws_ami.latest_ubuntu.image_id
      instance_type = "m5ad.4xlarge"
      launch_template_os = "bottlerocket"
      desired_size  = 3
      max_size      = 5
      min_size      = 1
      capacity_type = "ON_DEMAND"

      format_mount_nvme_dis = true

      enable_metadata_options = false
      enable_monitoring      = true

      kubelet_extra_args = "--max-pods=110"
      bootstrap_extra_args = "--use-max-pods false --container-runtime containerd"
      block_device_mappings = [
        {
          device_name = "/dev/xvda" # mount point to /
          volume_type = "gp3"
          volume_size = 100
        }
	]
    }
  }
}
