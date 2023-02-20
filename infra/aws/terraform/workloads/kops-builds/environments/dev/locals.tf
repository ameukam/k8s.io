locals {
  prefix          = "k8s-infra-kops"
  partition       = cidrsubnets(aws_vpc_ipam_preview_next_cidr.main.cidr, 2, 2, 2)
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = cidrsubnets(local.partition[0], 2, 2, 2)
  public_subnets  = cidrsubnets(local.partition[1], 2, 2, 2)
}

output "cidrs" {
  value = local.partition
}

output "private_networks" {
  value = local.private_subnets
}

output "public_networks" {
  value = local.public_subnets
}

output "azs" {
  value = local.azs
}
