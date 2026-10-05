# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `kms_key` - The key's `arn`, `key_id` (also in `id`), `policy`, `region`, its settings (`customer_master_key_spec`, `key_usage`, `enable_key_rotation`, `rotation_period_in_days`, `multi_region`, `deletion_window_in_days`, `description`, `is_enabled`, `custom_key_store_id`, `xks_key_id`, `bypass_policy_lockout_safety_check`), `tags` and `tags_all`. Use the `arn` when another account or service needs to name the key.
    - `kms_alias` - The alias's `name` (`alias/<name>`, also in `id`), `arn`, `region`, `target_key_id`, `target_key_arn` and `name_prefix`.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    kms_key   = local.output_resources.kms_key
    kms_alias = local.output_resources.kms_alias
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference any deprecated attributes, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    kms_key = {
      arn                                = aws_kms_key.this.arn
      bypass_policy_lockout_safety_check = aws_kms_key.this.bypass_policy_lockout_safety_check
      custom_key_store_id                = aws_kms_key.this.custom_key_store_id
      customer_master_key_spec           = aws_kms_key.this.customer_master_key_spec
      deletion_window_in_days            = aws_kms_key.this.deletion_window_in_days
      description                        = aws_kms_key.this.description
      enable_key_rotation                = aws_kms_key.this.enable_key_rotation
      id                                 = aws_kms_key.this.id
      is_enabled                         = aws_kms_key.this.is_enabled
      key_id                             = aws_kms_key.this.key_id
      key_usage                          = aws_kms_key.this.key_usage
      multi_region                       = aws_kms_key.this.multi_region
      policy                             = aws_kms_key.this.policy
      region                             = aws_kms_key.this.region
      rotation_period_in_days            = aws_kms_key.this.rotation_period_in_days
      tags                               = aws_kms_key.this.tags
      tags_all                           = aws_kms_key.this.tags_all
      xks_key_id                         = aws_kms_key.this.xks_key_id
    }

    kms_alias = {
      arn            = aws_kms_alias.this.arn
      id             = aws_kms_alias.this.id
      name           = aws_kms_alias.this.name
      name_prefix    = aws_kms_alias.this.name_prefix
      region         = aws_kms_alias.this.region
      target_key_arn = aws_kms_alias.this.target_key_arn
      target_key_id  = aws_kms_alias.this.target_key_id
    }
  }
}
