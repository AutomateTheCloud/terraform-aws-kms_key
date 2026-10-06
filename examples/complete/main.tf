# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A key with separate administrators and users. Two IAM roles are created here, so the
# example can be applied on its own: one manages the key and cannot use it, and one, for
# an application on AWS Lambda, uses it and cannot manage it.

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
  description = "Alias for the key, without the alias/ prefix, and prefix for the IAM roles"
  type        = string
  default     = "example-complete"
}

locals {
  details = {
    scope            = "Example"
    purpose          = "Complete Key"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }
}

data "aws_caller_identity" "current" {}

# Anyone in this account whose IAM policies allow it may assume the administrator role.
resource "aws_iam_role" "key_administrator" {
  name = "${var.name}-key-administrator"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { AWS = data.aws_caller_identity.current.account_id } }]
  })
}

resource "aws_iam_role" "application" {
  name = "${var.name}-application"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

module "kms_key" {
  source = "../../"

  details = local.details

  name                    = var.name
  description             = "Encrypts the example application's data"
  deletion_window_in_days = 30
  multi_region            = true

  policy = {
    administrator_arns = [aws_iam_role.key_administrator.arn]
    user_arns          = [aws_iam_role.application.arn]

    # To share the key with other accounts or a whole AWS Organization, list them here.
    # Each account must exist: AWS rejects a key policy that names one it cannot find.
    # user_account_ids      = ["123456789012"]
    # user_organization_ids = ["o-abcdefghij"]
  }
}

output "kms_key" {
  description = "ARN, alias and policy of the key"
  value = {
    arn    = module.kms_key.metadata.kms_key.arn
    alias  = module.kms_key.metadata.kms_alias.name
    policy = jsondecode(module.kms_key.metadata.kms_key.policy)
  }
}
