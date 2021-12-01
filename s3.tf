resource "aws_s3_bucket" "geff_bucket" {
  bucket = "${replace(local.geff_prefix, "_", "-")}-bucket" # Only hiphens + lower alphanumeric are allowed for bucket name
  acl    = "private"
}

resource "aws_s3_bucket_object" "geff_meta_folder" {
  bucket = aws_s3_bucket.geff_bucket.id
  key    = "meta/"
}

resource "random_string" "random" {
  length  = 5
  special = false
}

resource "aws_sns_topic" "geff_bucket_sns" {
  name = "${local.s3_sns_topic_name}_${random_string.random.result}"
}

data "aws_iam_policy_document" "geff_s3_sns_topic_policy_doc" {
  policy_id = local.s3_sns_policy_name

  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    resources = [aws_sns_topic.geff_bucket_sns.arn]
    actions   = ["SNS:Publish"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = concat(
        [aws_s3_bucket.geff_bucket.arn],
        var.data_bucket_arns
      )
    }
  }

  statement {
    sid       = "SNSSubscribe"
    effect    = "Allow"
    resources = [aws_sns_topic.geff_bucket_sns.arn]
    actions   = ["sns:Subscribe"]

    principals {
      type        = "AWS"
      identifiers = [snowflake_storage_integration.geff_storage_integration.storage_aws_iam_user_arn]
    }
  }
}

resource "aws_sns_topic_policy" "geff_s3_sns_topic_policy" {
  arn    = aws_sns_topic.geff_bucket_sns.arn
  policy = data.aws_iam_policy_document.geff_s3_sns_topic_policy_doc.json
}

resource "aws_s3_bucket_notification" "geff_s3_bucket_notification" {
  bucket = aws_s3_bucket.geff_bucket.id

  topic {
    topic_arn = aws_sns_topic.geff_bucket_sns.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.geff_s3_sns_topic_policy]
}

resource "aws_s3_bucket_notification" "geff_s3_pipline_bucket_notification" {
  for_each = toset(local.pipeline_bucket_ids)

  bucket = each.key

  topic {
    topic_arn = aws_sns_topic.geff_bucket_sns.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.geff_s3_sns_topic_policy]
}

