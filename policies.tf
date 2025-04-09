data "aws_iam_policy_document" "scp-ec2-instance-type" {
  statement {
    effect    = "Deny"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringNotEquals"
      variable = "ec2:InstanceType"
      values   = ["t2.micro", "t2.nano"]
    }
  }
}

data "aws_iam_policy_document" "scp-prevent-vpc-deletion" {
  statement {
    sid    = "DenyVPCDeletion"
    effect = "Deny"

    actions = [
      "ec2:DeleteVpc"
    ]

    resources = [
      "*"
    ]
  }
}