locals {
  prefix_name = "${var.projet}-${var.env}"
}

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "k3s" {
  name               = "${local.prefix_name}-k3s-node-role"
  description        = "Role IAM attribué à l'EC2 hébergeant K3s et ses workloads"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
}

data "aws_iam_policy_document" "workload_permissions" {
  # --- Permissions S3 : Niveau Bucket (Listing) ---
  statement {
    sid    = "AllowS3BucketListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.app.arn
    ]
  }

  statement {
    sid    = "AllowS3ObjectOperations"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.app.arn}/*"
    ]
  }

  # --- Permissions SQS : Consommation et traitement des messages ---
  statement {
    sid    = "AllowSQSMessageProcessing"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = [
      aws_sqs_queue.app.arn
    ]
  }
}

resource "aws_iam_policy" "workload_policy" {
  name        = "${local.prefix_name}-workload-policy"
  description = "Politique stricte autorisant les opérations S3 et SQS des microservices"
  policy      = data.aws_iam_policy_document.workload_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach_workload_policy" {
  role       = aws_iam_role.k3s.name
  policy_arn = aws_iam_policy.workload_policy.arn
}

resource "aws_iam_instance_profile" "k3s_instance_profile" {
  name = "${local.prefix_name}-k3s-instance-profile"
  role = aws_iam_role.k3s.name
}
