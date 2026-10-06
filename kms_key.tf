# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_kms_key" "this" {
  region                             = var.region
  description                        = var.description
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  custom_key_store_id                = var.custom_key_store_id
  customer_master_key_spec           = var.customer_master_key_spec
  deletion_window_in_days            = var.deletion_window_in_days
  enable_key_rotation                = var.enable_key_rotation
  key_usage                          = var.key_usage
  multi_region                       = var.multi_region

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.kms_key_policy_statements
  })

  tags = local.tags

  lifecycle {
    # A change that replaces the key creates the new one, and moves the alias to it,
    # before the old one is scheduled for deletion.
    create_before_destroy = true

    precondition {
      condition     = length(local.kms_key_policy_sids) == length(distinct(local.kms_key_policy_sids))
      error_message = "Key policy statement IDs (Sid) must be unique. Check policy.source_policy_documents against the module's own statements: ${join(", ", local.kms_key_policy_sids)}."
    }
  }
}
