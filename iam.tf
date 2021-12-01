# This file contains the following IAM resources:
# 1. Role  and Policy attachment for the role that the api gateway will assume.
# 2. Role, Role Policy and Policy attachment for the role that the external function will assume.
# 3. Lambda Assume Role, Assume Role Policy and other Permissions Policy.
# 4. Role, Role Policy for Storage Integration

# ----------------------------------------------------------------------------
# 1. Role and Policy attachment for the role that the api gateway will assume.
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "geff_api_gateway_assume_role_policy_doc" {
  count = var.storage_only ? 0 : 1

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "geff_api_gateway_assume_role" {
  count = var.storage_only ? 0 : 1

  name               = local.api_gw_logger_role_name
  assume_role_policy = data.aws_iam_policy_document.geff_api_gateway_assume_role_policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "gateway_logger_policy_attachment" {
  count = var.storage_only ? 0 : 1

  role       = aws_iam_role.geff_api_gateway_assume_role[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway" {
  count               = var.storage_only ? 0 : 1
  cloudwatch_role_arn = aws_iam_role.geff_api_gateway_assume_role[0].arn
}

# -----------------------------------------------------------------------------------------------
# 2. Role, Role Policy and Policy attachment for the role that the external function will assume.
# -----------------------------------------------------------------------------------------------
resource "aws_iam_role" "gateway_caller" {
  count = var.storage_only ? 0 : 1

  name = local.api_gw_caller_role_name
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_api_integration.geff_api_integration[0].api_aws_external_id
          }
        }
        Effect = "Allow"
        Principal = {
          AWS = snowflake_api_integration.geff_api_integration[0].api_aws_iam_user_arn
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "gateway_caller_policy" {
  count = var.storage_only ? 0 : 1

  name = "${var.prefix}_invoke_api_gateway_policy"
  role = aws_iam_role.gateway_caller[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "execute-api:Invoke"
        Resource = "${aws_api_gateway_rest_api.ef_to_lambda[0].execution_arn}/*/*/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------
# 3. Lambda Assume Role, Assume Role Policy and other Permissions Policy.
# -----------------------------------------------------------------------
data "aws_iam_policy_document" "geff_lambda_assume_role_policy_doc" {
  count = var.storage_only ? 0 : 1

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "geff_lambda_assume_role" {
  count = var.storage_only ? 0 : 1

  name               = "${local.geff_prefix}_lambda"
  assume_role_policy = data.aws_iam_policy_document.geff_lambda_assume_role_policy_doc[0].json
}

data "aws_iam_policy_document" "geff_lambda_policy_doc" {
  count = var.storage_only ? 0 : 1

  # Write logs to cloudwatch
  statement {
    sid       = "WriteCloudWatchLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_function_name}:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  # Write metrics to cloudwatch
  statement {
    sid       = "WriteCloudWatchMetrics"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "cloudwatch:PutMetricData",
    ]

    condition {
      test     = "StringLike"
      variable = "cloudwatch:namespace"

      values = [
        var.aws_cloudwatch_metric_namespace
      ]
    }
  }

  statement {
    sid       = "EcrScanImages"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:DescribeImageScanFindings",
      "ecr:StartImageScan",
    ]
  }

  # Write to S3
  statement {
    sid       = "WriteToS3"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.geff_bucket.arn}/*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
  }

  # Invoke a child lambda
  statement {
    sid       = "InvokeLambda"
    effect    = "Allow"
    resources = [aws_lambda_function.geff_lambda[0].arn]
    actions = [
      "lambda:InvokeFunction"
    ]
  }
}

resource "aws_iam_role_policy" "geff_lambda_policy" {
  count = var.storage_only ? 0 : 1

  name   = "${local.geff_prefix}_lambda_policy"
  role   = aws_iam_role.geff_lambda_assume_role[0].id
  policy = data.aws_iam_policy_document.geff_lambda_policy_doc[0].json
}

data "aws_iam_policy" "geff_lambda_vpc_policy" {
  count = var.deploy_lambda_in_vpc && !var.storage_only ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

resource "aws_iam_role_policy_attachment" "geff_lambda_vpc_policy_attachment" {
  count = var.deploy_lambda_in_vpc && !var.storage_only ? 1 : 0

  role       = aws_iam_role.geff_lambda_assume_role[0].name
  policy_arn = data.aws_iam_policy.geff_lambda_vpc_policy[0].arn
}

# ---------------------------------------------
# 4. Role, Role Policy for Storage Integration.
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
          AWS = snowflake_storage_integration.geff_storage_integration.storage_aws_iam_user_arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_storage_integration.geff_storage_integration.storage_aws_external_id
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
  name = "${var.prefix}_rw_to_s3_bucket_policy"
  role = aws_iam_role.s3_reader.id

  policy = data.aws_iam_policy_document.s3_reader_policy_doc.json
}
