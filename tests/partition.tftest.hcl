# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Regression: the old module wrote principal ARNs as "arn:aws:...", which is wrong in
# AWS GovCloud (US) and China.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-gov-west-1", description = "AWS GovCloud (US-West)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws-us-gov" }
  }
}

variables {
  details = { scope = "Test", purpose = "Partition", environment = "test" }
  name    = "test-key"
}

run "principals_use_the_partition" {
  command = plan
  variables {
    policy = {
      administrator_account_ids = ["222222222222"]
      user_account_ids          = ["123456789012"]
      user_arns                 = ["arn:aws-us-gov:iam::111111111111:role/app"]
    }
  }
  assert {
    condition = alltrue([
      jsondecode(aws_kms_key.this.policy).Statement[0].Principal.AWS == "arn:aws-us-gov:iam::111111111111:root",
      jsondecode(aws_kms_key.this.policy).Statement[1].Principal.AWS == ["arn:aws-us-gov:iam::222222222222:root"],
      jsondecode(aws_kms_key.this.policy).Statement[2].Principal.AWS == ["arn:aws-us-gov:iam::123456789012:root", "arn:aws-us-gov:iam::111111111111:role/app"],
    ])
    error_message = "Principal ARNs must use the partition: ${aws_kms_key.this.policy}"
  }
}
