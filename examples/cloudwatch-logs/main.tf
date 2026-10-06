# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A key that encrypts one CloudWatch Logs log group. The key policy lets the CloudWatch
# Logs service use the key only for that log group, through a statement passed in
# policy.source_policy_documents.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "name" {
  description = "Alias for the key, without the alias/ prefix, and name of the log group"
  type        = string
  default     = "example-cloudwatch-logs"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  # Built from its parts, because the key must exist before the log group.
  log_group_arn = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.name}"
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt*",
      "kms:Describe*",
      "kms:Encrypt*",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = [local.log_group_arn]
    }
  }
}

module "kms_key" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Log Encryption"
    environment = "Development"
  }

  name        = var.name
  description = "Encrypts the ${var.name} log group"

  policy = {
    source_policy_documents = [data.aws_iam_policy_document.cloudwatch_logs.json]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.name
  kms_key_id        = module.kms_key.metadata.kms_key.arn
  retention_in_days = 30
}

output "log_group" {
  description = "Name of the log group and ARN of the key that encrypts it"
  value = {
    name    = aws_cloudwatch_log_group.this.name
    kms_key = module.kms_key.metadata.kms_key.arn
  }
}
