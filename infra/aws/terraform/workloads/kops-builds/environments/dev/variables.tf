variable "env" {
  type    = string
  default = "dev"
}

variable "eks_version" {
  type    = string
  default = "1.27"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "tags" {
  type = map(string)
  default = {
    "managed-by"    = "Terraform",
    "is-production" = "false",
    "group" = "sig-cluster-lifecycle",
    "subproject" = "kops"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR of the VPC"
  default     = "10.128.0.0/16"
}
