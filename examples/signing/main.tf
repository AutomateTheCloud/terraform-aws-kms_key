# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An elliptic curve key pair for digital signatures. The private key never leaves AWS
# KMS; anyone with the public key can check a signature. Asymmetric keys cannot rotate
# automatically, so rotation is turned off.

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
  default     = "example-signing"
}

module "kms_key" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Signing Key"
    environment = "Development"
  }

  name                     = var.name
  description              = "Signs release artifacts"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  enable_key_rotation      = false
}

output "kms_key" {
  description = "ARN and alias of the key"
  value = {
    arn   = module.kms_key.metadata.kms_key.arn
    alias = module.kms_key.metadata.kms_alias.name
  }
}
