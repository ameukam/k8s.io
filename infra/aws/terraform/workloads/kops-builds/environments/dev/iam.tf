
data "aws_iam_policy_document" "prow_access" {
  provider = aws.prow

  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.k8s_prow.arn]
      type        = "Federated"
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test = "StringEquals"
      # GKE cluster hosting prow.k8s.io control plane
      variable = "container.googleapis.com/v1/projects/k8s-prow/locations/us-central1-f/clusters/prow:sub"
      values = [
        "system:serviceaccount:default:prow-controller-manager",
        "system:serviceaccount:default:sinker"
      ]
    }
  }
}

resource "aws_iam_openid_connect_provider" "k8s_prow" {
  provider = aws.prow

  url            = "https://container.googleapis.com/v1/projects/k8s-prow/locations/us-central1-f/clusters/prow"
  client_id_list = ["sts.amazonaws.com"]
  # Google Trust services
  thumbprint_list = ["08745487e891c19e3078c1f2a07e452950ef36f6"]
}

resource "aws_iam_role" "prow_access" {
  provider = aws.prow

  name               = "prow_access"
  assume_role_policy = data.aws_iam_policy_document.prow_access.json
}
