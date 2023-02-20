data "aws_availability_zones" "available" {

  provider = aws.prow
  state    = "available"

}

data "aws_caller_identity" "current" {
  provider = aws.prow
}

data "aws_region" "current" {
  provider = aws.prow
}
