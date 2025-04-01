resource "aws_kms_key" "this" {
  description                        = var.description
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  custom_key_store_id                = var.custom_key_store_id
  customer_master_key_spec           = var.customer_master_key_spec
  deletion_window_in_days            = var.deletion_window_in_days
  enable_key_rotation                = var.enable_key_rotation
  key_usage                          = var.key_usage
  multi_region                       = var.multi_region

  policy = jsonencode(jsondecode(data.aws_iam_policy_document.kms_key-this.json))

  tags = merge(
    local.tags
  )
  provider = aws.this
}

data "aws_iam_policy_document" "kms_key-this" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.owner_list
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = length(local.share_list) > 0 ? [1] : []
    content {
      sid    = "Allow Use of the Key"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = local.share_list
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:GetKeyPolicy",
        "kms:ReEncrypt*",
      ]
      resources = [
        "*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(local.share_list) > 0 ? [1] : []
    content {
      sid    = "Allow Attachment of Persistent Resources"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = local.share_list
      }
      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]
      resources = [
        "*"
      ]
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_share_with_organization ? [1] : []
    content {
      sid    = "Allow Use of the Key with Organization"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:GetKeyPolicy",
        "kms:ReEncrypt*",
      ]
      resources = [
        "*"
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [data.aws_organizations_organization.this[0].arn]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_sns_publish ? [1] : []
    content {
      sid    = "Allow Publish from SNS"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt",
      ]
      resources = [
        "*"
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.this.account_id]
      }
    }
  }

  provider = aws.this
}
