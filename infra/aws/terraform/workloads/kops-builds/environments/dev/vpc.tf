resource "aws_vpc_ipam" "main" {
  provider    = aws.prow
  description = "${local.prefix}-${data.aws_region.current.name}-${var.env}-ipam"
  operating_regions {
    region_name = data.aws_region.current.name
  }

  tags = merge(var.tags, {
    "region" = "${var.region}"
  })
}

resource "aws_vpc_ipam_scope" "main" {
  provider    = aws.prow
  ipam_id     = aws_vpc_ipam.main.id
  description = "${local.prefix}-${data.aws_region.current.name}-${var.env}-ipam"
  tags = merge(var.tags, {
    "region" = "${var.region}"
  })
}

resource "aws_vpc_ipam_pool" "main" {
  provider       = aws.prow
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.main.private_default_scope_id
  locale         = data.aws_region.current.name
  tags = merge(var.tags, {
    "region" = "${var.region}"
  })
}


resource "aws_vpc_ipam_pool_cidr" "main" {
  provider     = aws.prow
  ipam_pool_id = aws_vpc_ipam_pool.main.id
  cidr         = var.vpc_cidr
}

resource "aws_vpc_ipam_preview_next_cidr" "main" {
  provider       = aws.prow
  ipam_pool_id   = aws_vpc_ipam_pool.main.id
  netmask_length = 18
}

module "vpc" {
  providers = {
    aws = aws.prow
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${local.prefix}-${var.env}-vpc"
  cidr = aws_vpc_ipam_preview_next_cidr.main.cidr

  ipv4_ipam_pool_id = aws_vpc_ipam_pool.main.id

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_retention_in_days = 30

  instance_tenancy = "dedicated"

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "vpc_endpoints_sg" {
  providers = { aws = aws.prow }
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"
  name = "${local.prefix}-${var.env}-vpc-endpoints"
  description = "Security group for VPC endpoint access"

  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {

      rule = "https-443-tcp"
      description = "VPC CIDR HTTPS"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)

    },

  ]

  egress_with_cidr_blocks = [

    {

      rule = "https-443-tcp"
      description = "All egress HTTPS"
      cidr_blocks = "0.0.0.0/0"

    },

  ]

  tags = var.tags

}

module "vpc_endpoints" {
  providers = { aws = aws.prow }

  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  version = "~> 3.0"

  vpc_id = module.vpc.vpc_id

  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  endpoints = merge({

    s3 = {
      service = "s3"
      service_type = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = merge(var.tags, {
        Name = "${local.prefix}-${var.env}-s3"
      })
    }

    },

    { for service in toset(["aps-workspaces", "autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"]) :
      replace(service, ".", "_") =>
      {
        service = service
        subnet_ids = module.vpc.private_subnets
        private_dns_enabled = true
        tags = { Name = "${local.prefix}-${var.env}-${service}" }
      }
  })

  tags = var.tags

}