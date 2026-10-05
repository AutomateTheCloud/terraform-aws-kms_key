# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
}

variables {
  details = { scope = "Test", purpose = "Policy", environment = "test" }
  name    = "test-key"
}

run "administrators" {
  command = plan
  variables {
    policy = {
      administrator_account_ids = ["222222222222"]
      administrator_arns        = ["arn:aws:iam::111111111111:role/KeyAdmin"]
    }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Sid == "AllowKeyAdministrators"
    error_message = "Missing the administrators statement."
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Principal.AWS == ["arn:aws:iam::222222222222:root", "arn:aws:iam::111111111111:role/KeyAdmin"]
    error_message = "Unexpected administrator principals."
  }
  assert {
    condition = alltrue([
      contains(jsondecode(aws_kms_key.this.policy).Statement[1].Action, "kms:ScheduleKeyDeletion"),
      contains(jsondecode(aws_kms_key.this.policy).Statement[1].Action, "kms:Put*"),
      !contains(jsondecode(aws_kms_key.this.policy).Statement[1].Action, "kms:Decrypt"),
      !contains(jsondecode(aws_kms_key.this.policy).Statement[1].Action, "kms:*"),
    ])
    error_message = "Administrators must manage the key without using it."
  }
  assert {
    condition     = length(jsondecode(aws_kms_key.this.policy).Statement) == 2
    error_message = "Administrators alone must not add use statements."
  }
}

run "users_symmetric" {
  command = plan
  variables {
    policy = {
      user_account_ids = ["222222222222"]
      user_arns        = ["arn:aws:iam::111111111111:user/app"]
    }
  }
  assert {
    condition = [for s in jsondecode(aws_kms_key.this.policy).Statement : s.Sid] == [
      "EnableIAMUserPermissions", "AllowKeyUse", "AllowGrantsForAWSResources",
    ]
    error_message = "Unexpected statements."
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Action == ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
    error_message = "Unexpected actions for a symmetric key."
  }
  assert {
    condition = alltrue([
      jsondecode(aws_kms_key.this.policy).Statement[1].Principal.AWS == ["arn:aws:iam::222222222222:root", "arn:aws:iam::111111111111:user/app"],
      jsondecode(aws_kms_key.this.policy).Statement[2].Principal.AWS == ["arn:aws:iam::222222222222:root", "arn:aws:iam::111111111111:user/app"],
      jsondecode(aws_kms_key.this.policy).Statement[2].Condition.Bool["kms:GrantIsForAWSResource"] == "true",
    ])
    error_message = "Unexpected user principals or grant condition."
  }
}

# Regression: the old module gave every key the symmetric actions, so a shared signing
# key could not be used to sign.
run "users_sign_verify" {
  command = plan
  variables {
    customer_master_key_spec = "ECC_NIST_P256"
    key_usage                = "SIGN_VERIFY"
    enable_key_rotation      = false
    policy                   = { user_account_ids = ["222222222222"] }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Action == ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign", "kms:Verify"]
    error_message = "Unexpected actions for a signing key."
  }
  assert {
    condition     = length(jsondecode(aws_kms_key.this.policy).Statement) == 2
    error_message = "Grants are only for symmetric keys."
  }
}

run "users_rsa_encrypt" {
  command = plan
  variables {
    customer_master_key_spec = "RSA_2048"
    enable_key_rotation      = false
    policy                   = { user_arns = ["arn:aws:iam::111111111111:role/app"] }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Action == ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GetPublicKey", "kms:ReEncrypt*"]
    error_message = "Unexpected actions for an RSA encryption key."
  }
}

run "users_hmac" {
  command = plan
  variables {
    customer_master_key_spec = "HMAC_256"
    key_usage                = "GENERATE_VERIFY_MAC"
    enable_key_rotation      = false
    policy                   = { user_arns = ["arn:aws:iam::111111111111:role/app"] }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Action == ["kms:DescribeKey", "kms:GenerateMac", "kms:VerifyMac"]
    error_message = "Unexpected actions for an HMAC key."
  }
}

run "users_key_agreement" {
  command = plan
  variables {
    customer_master_key_spec = "ECC_NIST_P384"
    key_usage                = "KEY_AGREEMENT"
    enable_key_rotation      = false
    policy                   = { user_arns = ["arn:aws:iam::111111111111:role/app"] }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Action == ["kms:DeriveSharedSecret", "kms:DescribeKey", "kms:GetPublicKey"]
    error_message = "Unexpected actions for a key agreement key."
  }
}

# Regression: the old module compared aws:PrincipalOrgID with the organization's ARN,
# which never matches, so the organization statement granted nothing.
run "organization_users" {
  command = plan
  variables {
    policy = { user_organization_ids = ["o-abcdefghij"] }
  }
  assert {
    condition = jsondecode(aws_kms_key.this.policy).Statement[1] == {
      Sid       = "AllowOrganizationKeyUse"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
      Resource  = "*"
      Condition = { StringEquals = { "aws:PrincipalOrgID" = ["o-abcdefghij"] } }
    }
    error_message = "Unexpected organization statement: ${jsonencode(jsondecode(aws_kms_key.this.policy).Statement[1])}"
  }
}

run "kafka" {
  command = plan
  variables { enable_kafka = true }
  assert {
    condition = jsondecode(aws_kms_key.this.policy).Statement[1] == {
      Sid       = "AllowKafka"
      Effect    = "Allow"
      Principal = { Service = "kafka.amazonaws.com" }
      Action    = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey", "kms:ReEncrypt*"]
      Resource  = "*"
    }
    error_message = "Unexpected Kafka statement."
  }
  assert {
    condition     = length(jsondecode(aws_kms_key.this.policy).Statement) == 2
    error_message = "Unexpected statement count."
  }
}

run "source_policy_documents" {
  command = plan
  variables {
    policy = {
      source_policy_documents = [jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "AllowCloudWatchLogs"
          Effect    = "Allow"
          Principal = { Service = "logs.us-east-1.amazonaws.com" }
          Action    = ["kms:Encrypt*", "kms:Decrypt*"]
          Resource  = "*"
        }]
      })]
    }
  }
  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[1].Sid == "AllowCloudWatchLogs" && jsondecode(aws_kms_key.this.policy).Statement[1].Principal.Service == "logs.us-east-1.amazonaws.com"
    error_message = "The caller's statement was not added."
  }
  assert {
    condition     = length(jsondecode(aws_kms_key.this.policy).Statement) == 2
    error_message = "Unexpected statement count."
  }
}

run "every_option_together" {
  command = plan
  variables {
    enable_kafka = true
    policy = {
      administrator_arns    = ["arn:aws:iam::111111111111:role/KeyAdmin"]
      user_arns             = ["arn:aws:iam::111111111111:role/app"]
      user_organization_ids = ["o-abcdefghij"]
      source_policy_documents = [jsonencode({
        Statement = [{ Sid = "Extra", Effect = "Allow", Principal = { AWS = "arn:aws:iam::111111111111:role/app" }, Action = "kms:ListAliases", Resource = "*" }]
      })]
    }
  }
  assert {
    condition = [for s in jsondecode(aws_kms_key.this.policy).Statement : s.Sid] == [
      "EnableIAMUserPermissions", "AllowKeyAdministrators", "AllowKeyUse", "AllowGrantsForAWSResources", "AllowOrganizationKeyUse", "AllowKafka", "Extra",
    ]
    error_message = "Unexpected statements."
  }
}
