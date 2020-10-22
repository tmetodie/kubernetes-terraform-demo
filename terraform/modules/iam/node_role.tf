data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "logs" {
  bucket = var.s3_log_bucket
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "eks_nodes_policy_doc" {
  statement {
    effect = "Allow"
    resources = [
      data.aws_s3_bucket.logs.arn,
      "${data.aws_s3_bucket.logs.arn}/*"
    ]
    actions = ["s3:*"]
  }
}

resource "aws_iam_policy" "eks_nodes_policy" {
  name        = "${var.naming}-s3-logs-policy"
  policy      = data.aws_iam_policy_document.eks_nodes_policy_doc.json
  path        = "/${var.naming}/eks/"
}

resource "aws_iam_role" "eks_node" {
  name               = "${var.naming}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
  tags               = var.common_tags
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.naming}-eks-node-role"
  role = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "elb" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_logs" {
  role       = aws_iam_role.eks_node.name
  policy_arn = aws_iam_policy.eks_nodes_policy.arn
}

resource "aws_s3_bucket_policy" "b" {
  bucket = data.aws_s3_bucket.logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.elb_account_id}:root"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "${data.aws_s3_bucket.logs.arn}/web/alb_logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "${data.aws_s3_bucket.logs.arn}/api/alb_logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "${data.aws_s3_bucket.logs.arn}/web/alb_logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "${data.aws_s3_bucket.logs.arn}/api/alb_logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${data.aws_s3_bucket.logs.arn}"
    }
  ]
}
POLICY
}