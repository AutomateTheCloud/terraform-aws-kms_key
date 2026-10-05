# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A key whose user is an IAM role created in the same run, so the role's ARN is unknown
# until apply. The module must still plan.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "name" {
  type = string
}

resource "aws_iam_role" "app" {
  name = var.name
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

module "kms_key" {
  source = "../../.."

  details = { scope = "Test", purpose = "Same Run Role", environment = "test" }
  name    = var.name
  policy = {
    administrator_arns = [aws_iam_role.app.arn]
    user_arns          = [aws_iam_role.app.arn]
  }
}

output "metadata" {
  value = module.kms_key.metadata
}
