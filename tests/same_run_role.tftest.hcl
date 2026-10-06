# Copyright 2026 Automate the Cloud Inc.
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
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test-key" }
  }
}

variables {
  name = "test-key"
}

run "plans_with_unknown_role_arn" {
  command = plan
  module {
    source = "./tests/fixtures/same_run_role"
  }
}

run "applies_with_role_in_policy" {
  command = apply
  module {
    source = "./tests/fixtures/same_run_role"
  }
  assert {
    condition     = contains(jsondecode(output.metadata.kms_key.policy).Statement[2].Principal.AWS, "arn:aws:iam::111111111111:role/test-key")
    error_message = "The same-run role was not added as a key user."
  }
}
