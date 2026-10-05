# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  account_root_arn = "arn:${local.aws.partition}:iam::${local.aws.account.id}:root"

  administrator_principals = concat(
    [for account in var.policy.administrator_account_ids : "arn:${local.aws.partition}:iam::${account}:root"],
    var.policy.administrator_arns,
  )

  user_principals = concat(
    [for account in var.policy.user_account_ids : "arn:${local.aws.partition}:iam::${account}:root"],
    var.policy.user_arns,
  )

  # The operations each key type allows, as in the default key policy the AWS KMS console
  # writes for key users.
  key_type = (
    var.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? "SYMMETRIC_DEFAULT" :
    var.key_usage == "SIGN_VERIFY" ? "SIGN_VERIFY" :
    var.key_usage == "GENERATE_VERIFY_MAC" ? "GENERATE_VERIFY_MAC" :
    var.key_usage == "KEY_AGREEMENT" ? "KEY_AGREEMENT" :
    "ASYMMETRIC_ENCRYPT_DECRYPT"
  )
  key_user_actions = {
    SYMMETRIC_DEFAULT          = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
    ASYMMETRIC_ENCRYPT_DECRYPT = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GetPublicKey", "kms:ReEncrypt*"]
    SIGN_VERIFY                = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign", "kms:Verify"]
    GENERATE_VERIFY_MAC        = ["kms:DescribeKey", "kms:GenerateMac", "kms:VerifyMac"]
    KEY_AGREEMENT              = ["kms:DeriveSharedSecret", "kms:DescribeKey", "kms:GetPublicKey"]
  }[local.key_type]

  # Key administrators manage the key but cannot use it, as in the console's default policy.
  key_administrator_actions = [
    "kms:CancelKeyDeletion",
    "kms:Create*",
    "kms:Delete*",
    "kms:Describe*",
    "kms:Disable*",
    "kms:Enable*",
    "kms:Get*",
    "kms:List*",
    "kms:Put*",
    "kms:Revoke*",
    "kms:RotateKeyOnDemand",
    "kms:ScheduleKeyDeletion",
    "kms:TagResource",
    "kms:UntagResource",
    "kms:Update*",
  ]

  # Every statement the key policy can contain. Only the first is always present.
  kms_key_policy_statements = concat(
    # The key's own account controls the key through IAM policies. Without this statement,
    # nobody in the account could manage the key unless the policy named them.
    [{
      Sid       = "EnableIAMUserPermissions"
      Effect    = "Allow"
      Principal = { AWS = local.account_root_arn }
      Action    = "kms:*"
      Resource  = "*"
    }],

    [for s in [{
      Sid       = "AllowKeyAdministrators"
      Effect    = "Allow"
      Principal = { AWS = local.administrator_principals }
      Action    = local.key_administrator_actions
      Resource  = "*"
    }] : s if length(local.administrator_principals) > 0],

    [for s in [{
      Sid       = "AllowKeyUse"
      Effect    = "Allow"
      Principal = { AWS = local.user_principals }
      Action    = local.key_user_actions
      Resource  = "*"
    }] : s if length(local.user_principals) > 0],

    # Grants let AWS services, such as Amazon EBS, use the key on a user's behalf. Only
    # symmetric encryption keys work with those services.
    [for s in [{
      Sid       = "AllowGrantsForAWSResources"
      Effect    = "Allow"
      Principal = { AWS = local.user_principals }
      Action    = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
      Resource  = "*"
      Condition = { Bool = { "kms:GrantIsForAWSResource" = "true" } }
    }] : s if length(local.user_principals) > 0 && local.key_type == "SYMMETRIC_DEFAULT"],

    [for s in [{
      Sid       = "AllowOrganizationKeyUse"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = local.key_user_actions
      Resource  = "*"
      Condition = { StringEquals = { "aws:PrincipalOrgID" = var.policy.user_organization_ids } }
    }] : s if length(var.policy.user_organization_ids) > 0],

    [for s in [{
      Sid       = "AllowKafka"
      Effect    = "Allow"
      Principal = { Service = "kafka.amazonaws.com" }
      Action    = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey", "kms:ReEncrypt*"]
      Resource  = "*"
    }] : s if var.enable_kafka],

    # Statements from the caller's own policy documents
    flatten([for doc in var.policy.source_policy_documents : jsondecode(doc).Statement]),
  )

  kms_key_policy_sids = compact([for s in local.kms_key_policy_statements : try(s.Sid, "")])
}
