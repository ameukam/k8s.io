/*
Copyright 2022 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

provider "aws" {
  profile = "default"
  region  = "us-west-2"
  alias   = "origin"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-northeast-1"
  alias  = "ap-northeast-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-northeast-2"
  alias  = "ap-northeast-2"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-northeast-3"
  alias  = "ap-northeast-3"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-south-1"
  alias  = "ap-south-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-southeast-1"
  alias  = "ap-southeast-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ap-southeast-2"
  alias  = "ap-southeast-2"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "ca-central-1"
  alias  = "ca-central-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "eu-north-1"
  alias  = "eu-north-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "eu-west-1"
  alias  = "eu-west-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "eu-west-2"
  alias  = "eu-west-2"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "eu-west-3"
  alias  = "eu-west-3"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "sa-east-1"
  alias  = "sa-east-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "us-west-1"
  alias  = "us-west-1"

  skip_get_ec2_platforms = true
}

provider "aws" {
  region = "us-west-2"
  alias  = "us-west-2"

  skip_get_ec2_platforms = true
}
