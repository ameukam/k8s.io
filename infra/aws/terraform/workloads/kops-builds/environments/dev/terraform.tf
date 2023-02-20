terraform {
  backend "s3" {
    bucket  = "k8s-infra-aws-prow-build-tf-state"
    region  = "us-east-2"
    key     = "dev/terraform.state"
    profile = "k8s-infra-test-account"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.61.0"
    }
  }
}
