# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
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
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
  name    = "test-key"
}

run "defaults_are_secure" {
  command = plan

  assert {
    condition = alltrue([
      aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT",
      aws_kms_key.this.key_usage == "ENCRYPT_DECRYPT",
      aws_kms_key.this.enable_key_rotation,
      !aws_kms_key.this.multi_region,
      !aws_kms_key.this.bypass_policy_lockout_safety_check,
      aws_kms_key.this.deletion_window_in_days == 7,
    ])
    error_message = "Unexpected key settings by default."
  }
  assert {
    condition = jsondecode(aws_kms_key.this.policy) == {
      Version = "2012-10-17"
      Statement = [{
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::111111111111:root" }
        Action    = "kms:*"
        Resource  = "*"
      }]
    }
    error_message = "By default the policy must only let the key's own account control the key: ${aws_kms_key.this.policy}"
  }
  assert {
    condition     = aws_kms_alias.this.name == "alias/test-key"
    error_message = "Unexpected alias name."
  }
  assert {
    condition     = aws_kms_key.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" })
    error_message = "The key must carry the details tags."
  }
}

run "metadata_output" {
  command = apply

  assert {
    condition = alltrue([
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
      output.metadata.kms_key.arn == aws_kms_key.this.arn,
      output.metadata.kms_key.key_id == aws_kms_key.this.key_id,
      output.metadata.kms_alias.name == "alias/test-key",
      output.metadata.kms_alias.target_key_id == aws_kms_key.this.key_id,
      output.metadata.details.purpose.abbr == "defaults",
    ])
    error_message = "Unexpected metadata output."
  }
}

run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "Web Site", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "web_site",
      output.metadata.details.purpose.machine == "website",
    ])
    error_message = "Unexpected abbreviations."
  }
}

run "additional_tags" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Tags", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition     = aws_kms_key.this.tags["CostCenter"] == "1234" && aws_kms_key.this.tags["Purpose"] == "Tags"
    error_message = "additional_tags were not applied."
  }
}

run "key_settings_pass_through" {
  command = plan
  variables {
    description             = "Test key"
    deletion_window_in_days = 30
    multi_region            = true
  }
  assert {
    condition = alltrue([
      aws_kms_key.this.description == "Test key",
      aws_kms_key.this.deletion_window_in_days == 30,
      aws_kms_key.this.multi_region,
    ])
    error_message = "Key settings were not passed through."
  }
}
