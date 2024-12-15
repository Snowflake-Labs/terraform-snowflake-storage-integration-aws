# This file contains the following IAM resources:
# 1. Role, Role Policy for Storage Integration

# ---------------------------------------------
# 1. Role, Role Policy for Storage Integration.
# ---------------------------------------------
resource "aws_iam_role" "s3_reader" {
  name = local.s3_reader_role_name
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = local.storage_integration_user_arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = local.storage_integration_external_id
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_reader_policy_doc" {
  # Write logs to cloudwatch
  statement {
    sid       = "S3ReadWritePerms"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.geff_bucket.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
  }

  statement {
    sid       = "S3ListPerms"
    effect    = "Allow"
    resources = [aws_s3_bucket.geff_bucket.arn]

    actions = ["s3:ListBucket"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.data_bucket_arns

    content {
      sid       = "S3ReadWritePerms${statement.key}"
      effect    = "Allow"
      resources = ["${statement.value}/*"]

      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.data_bucket_arns

    content {
      sid       = "S3ListPerms${statement.key}"
      effect    = "Allow"
      resources = [statement.value]

      actions = ["s3:ListBucket"]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["*"]
      }
    }
  }
}

resource "aws_iam_role_policy" "s3_reader" {
  name = local.s3_bucket_policy_name
  role = aws_iam_role.s3_reader.id

  policy = data.aws_iam_policy_document.s3_reader_policy_doc.json
}
