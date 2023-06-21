# terraform {
#   backend "s3" {
#     bucket = "s3Bucket"
#     key    = "production/xxx"
#     region = "us-east-1"
#   }
# }


locals {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

############## NAMESPACE for cloudwatch and fluentbit ##############
resource "kubernetes_namespace" "amazon-cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

################ serviceaccount ##############
resource "kubernetes_service_account" "cloudwatch" {
  metadata {
    name = "cloudwatch"
    namespace = kubernetes_namespace.amazon-cloudwatch.metadata[0].name
    annotations = { "eks.amazonaws.com/role-arn" = "${aws_iam_role.fluentbit.id}" }
  }
}

############## Cloudwatch Configmap  ##############

resource "kubernetes_config_map" "fluent-bit-cluster-info" {
  depends_on = [kubernetes_namespace.amazon-cloudwatch]
  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = kubernetes_namespace.amazon-cloudwatch.metadata[0].name
  }
  data = {
    "cluster.name" = "dataeng-stg-shared-eks"
    "logs.region"  = local.region
    "read.tail" = "On"
    "http.server" = "Off"
    "http.port" = "2020"
  }
}

resource "aws_iam_role" "fluentbit" {
  name                  = "fluentbit"
  force_detach_policies = true
  max_session_duration  = 3600
  path                  = "/"
  assume_role_policy    = jsonencode(
{
    Statement= [
      {
        Action= "sts:AssumeRoleWithWebIdentity"
        Condition= {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/${var.oidc_host_path}:aud"= "sts.amazonaws.com"
          }
        }
        Effect= "Allow"
        Principal= {
            Federated= "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${var.oidc_host_path}"
        }
      },
    ]
    Version= "2012-10-17"
}
)
}


resource "aws_iam_policy" "fluentbit" {
  name        = "fluentbit"
  path        = "/"
  description = "policy for EKS Service Account fluent-bit "
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fluentbit" {
  role       = aws_iam_role.fluentbit.name
  policy_arn = aws_iam_policy.fluentbit.arn
}


resource "helm_release" "fluentbit" {
  name       = "fluentbit"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.26"

  values = [
    templatefile(
      "${path.module}/yamls/fluentbit-values.yaml",
      {
        region                = var.region
        iam_role_arn          = aws_iam_role.fluentbit.arn
        cluster_name          = var.eks_cluster_name
        log_retention_in_days = var.log_retention_in_days
      }
    )
  ]
}
