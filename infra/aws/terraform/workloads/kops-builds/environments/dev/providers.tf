

provider "aws" {
  profile = "k8s-infra-test-account"
  region  = var.region
  alias   = "prow"
}