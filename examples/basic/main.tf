# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A symmetric encryption key with an alias, and nothing else. Only this account can use
# it, through IAM policies, and its key material rotates once a year.

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
  description = "Alias for the key, without the alias/ prefix"
  type        = string
  default     = "example-basic"
}

module "kms_key" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Key"
    environment = "Development"
  }

  name        = var.name
  description = "Example key with the module's defaults"
}

output "kms_key" {
  description = "ARN and alias of the key"
  value = {
    arn   = module.kms_key.metadata.kms_key.arn
    alias = module.kms_key.metadata.kms_alias.name
  }
}
