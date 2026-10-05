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
  details = { scope = "Test", purpose = "Validation", environment = "test" }
  name    = "test-key"
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

run "name_rejects_alias_prefix" {
  command = plan
  variables { name = "alias/test-key" }
  expect_failures = [var.name]
}

run "name_rejects_aws_prefix" {
  command = plan
  variables { name = "aws/test-key" }
  expect_failures = [var.name]
}

run "name_rejects_bad_characters" {
  command = plan
  variables { name = "test key" }
  expect_failures = [var.name]
}

run "name_allows_slashes" {
  command = plan
  variables { name = "team/app_key-1" }
  assert {
    condition     = aws_kms_alias.this.name == "alias/team/app_key-1"
    error_message = "Unexpected alias name."
  }
}

run "deletion_window_too_short" {
  command = plan
  variables { deletion_window_in_days = 6 }
  expect_failures = [var.deletion_window_in_days]
}

run "deletion_window_too_long" {
  command = plan
  variables { deletion_window_in_days = 31 }
  expect_failures = [var.deletion_window_in_days]
}

run "description_too_long" {
  command = plan
  variables { description = format("%8193s", "x") }
  expect_failures = [var.description]
}

run "key_usage_unknown" {
  command = plan
  variables { key_usage = "ENCRYPT" }
  expect_failures = [var.key_usage]
}

run "spec_and_usage_mismatch" {
  command = plan
  variables {
    customer_master_key_spec = "HMAC_256"
    key_usage                = "ENCRYPT_DECRYPT"
    enable_key_rotation      = false
  }
  expect_failures = [var.customer_master_key_spec]
}

run "symmetric_key_signing_rejected" {
  command = plan
  variables { key_usage = "SIGN_VERIFY" }
  expect_failures = [var.customer_master_key_spec]
}

# Only symmetric keys in AWS KMS rotate; the default rotation must be turned off for others.
run "rotation_rejected_for_asymmetric_key" {
  command = plan
  variables {
    customer_master_key_spec = "RSA_2048"
    key_usage                = "SIGN_VERIFY"
  }
  expect_failures = [var.enable_key_rotation]
}

run "rotation_rejected_in_custom_key_store" {
  command = plan
  variables { custom_key_store_id = "cks-1234567890abcdef0" }
  expect_failures = [var.enable_key_rotation]
}

run "custom_key_store_without_rotation" {
  command = plan
  variables {
    custom_key_store_id = "cks-1234567890abcdef0"
    enable_key_rotation = false
  }
  assert {
    condition     = aws_kms_key.this.custom_key_store_id == "cks-1234567890abcdef0"
    error_message = "custom_key_store_id was not passed through."
  }
}

run "kafka_requires_symmetric_key" {
  command = plan
  variables {
    customer_master_key_spec = "RSA_2048"
    enable_key_rotation      = false
    enable_kafka             = true
  }
  expect_failures = [var.enable_kafka]
}

run "policy_account_id_invalid" {
  command = plan
  variables { policy = { user_account_ids = ["12345"] } }
  expect_failures = [var.policy]
}

run "policy_administrator_account_id_invalid" {
  command = plan
  variables { policy = { administrator_account_ids = ["arn:aws:iam::222222222222:root"] } }
  expect_failures = [var.policy]
}

run "policy_arn_invalid" {
  command = plan
  variables { policy = { user_arns = ["arn:aws:s3:::bucket"] } }
  expect_failures = [var.policy]
}

run "policy_organization_id_invalid" {
  command = plan
  variables { policy = { user_organization_ids = ["arn:aws:organizations::111111111111:organization/o-abcdefghij"] } }
  expect_failures = [var.policy]
}

run "policy_source_document_invalid" {
  command = plan
  variables { policy = { source_policy_documents = ["{}"] } }
  expect_failures = [var.policy]
}

run "policy_duplicate_sid_rejected" {
  command = plan
  variables {
    policy = {
      source_policy_documents = [jsonencode({
        Version   = "2012-10-17"
        Statement = [{ Sid = "EnableIAMUserPermissions", Effect = "Allow", Principal = { AWS = "*" }, Action = "kms:*", Resource = "*" }]
      })]
    }
  }
  expect_failures = [aws_kms_key.this]
}
