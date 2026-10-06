# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "bypass_policy_lockout_safety_check" {
  description = <<-EOT
    Skip the AWS check that stops a key policy from locking out the principal that sets it. Leave this `false`: a key whose policy nobody can change cannot be managed or deleted, and only AWS Support can recover it.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "custom_key_store_id" {
  description = <<-EOT
    The ID of a custom key store, such as an AWS CloudHSM key store (`cks-1234567890abcdef0`), to create the key in. `null`, the default, creates the key in AWS KMS itself. Keys in a custom key store must be symmetric encryption keys and cannot rotate automatically, so set `enable_key_rotation = false`. Changing this replaces the key.
  EOT
  type        = string
  default     = null
}

variable "customer_master_key_spec" {
  description = <<-EOT
    The type of key. Changing it replaces the key.

    - `SYMMETRIC_DEFAULT` (the default) - A 256-bit symmetric key for encryption. AWS services that encrypt your data need this type.
    - `RSA_2048`, `RSA_3072`, `RSA_4096` - RSA key pairs, for `ENCRYPT_DECRYPT` or `SIGN_VERIFY`.
    - `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521` - Elliptic curve key pairs, for `SIGN_VERIFY` or `KEY_AGREEMENT`.
    - `ECC_SECG_P256K1` - An elliptic curve key pair, for `SIGN_VERIFY`.
    - `HMAC_224`, `HMAC_256`, `HMAC_384`, `HMAC_512` - Keys for hash-based message authentication codes (HMAC), for `GENERATE_VERIFY_MAC`.
    - `ML_DSA_44`, `ML_DSA_65`, `ML_DSA_87` - Post-quantum signing key pairs, for `SIGN_VERIFY`. They need a newer AWS provider than the module's minimum, 6.0.

    Only `SYMMETRIC_DEFAULT` keys can rotate automatically, so every other type needs `enable_key_rotation = false`.
  EOT
  type        = string
  default     = "SYMMETRIC_DEFAULT"
  nullable    = false

  validation {
    condition = (
      var.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? var.key_usage == "ENCRYPT_DECRYPT" :
      startswith(var.customer_master_key_spec, "RSA_") ? contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage) :
      startswith(var.customer_master_key_spec, "ECC_NIST_") ? contains(["SIGN_VERIFY", "KEY_AGREEMENT"], var.key_usage) :
      startswith(var.customer_master_key_spec, "ECC_SECG_") ? var.key_usage == "SIGN_VERIFY" :
      startswith(var.customer_master_key_spec, "HMAC_") ? var.key_usage == "GENERATE_VERIFY_MAC" :
      startswith(var.customer_master_key_spec, "ML_DSA_") ? var.key_usage == "SIGN_VERIFY" :
      true
    )
    error_message = "key_usage does not fit customer_master_key_spec: SYMMETRIC_DEFAULT keys are ENCRYPT_DECRYPT; RSA keys ENCRYPT_DECRYPT or SIGN_VERIFY; ECC_NIST keys SIGN_VERIFY or KEY_AGREEMENT; ECC_SECG_P256K1 and ML_DSA keys SIGN_VERIFY; HMAC keys GENERATE_VERIFY_MAC."
  }
}

variable "deletion_window_in_days" {
  description = <<-EOT
    How many days, from 7 to 30, AWS waits before deleting the key after it is destroyed. During the wait the key cannot be used, and the deletion can be canceled with `aws kms cancel-key-deletion`. After it, everything encrypted under the key can never be decrypted again.
  EOT
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30 && floor(var.deletion_window_in_days) == var.deletion_window_in_days
    error_message = "deletion_window_in_days must be a whole number from 7 to 30."
  }
}

variable "description" {
  description = <<-EOT
    A description of the key, shown in the AWS KMS console, such as `Encrypts the course materials bucket`. Up to 8,192 characters. `null`, the default, leaves it empty.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.description == null || length(coalesce(var.description, " ")) <= 8192
    error_message = "description must be at most 8,192 characters."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-kms_key#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "enable_kafka" {
  description = <<-EOT
    Let Amazon Managed Streaming for Apache Kafka (Amazon MSK), through the service principal `kafka.amazonaws.com`, encrypt and decrypt with the key, for Kafka clusters encrypted with it. The statement has no condition that limits it to your account or clusters. Works only with symmetric encryption keys (`SYMMETRIC_DEFAULT`).
  EOT
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = !var.enable_kafka || var.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "enable_kafka works only with customer_master_key_spec = \"SYMMETRIC_DEFAULT\"."
  }
}

variable "enable_key_rotation" {
  description = <<-EOT
    Rotate the key's cryptographic material automatically once a year. AWS keeps every earlier version, so data encrypted before a rotation can still be decrypted. Only symmetric encryption keys (`SYMMETRIC_DEFAULT`) created in AWS KMS can rotate: set this to `false` for any other key type, or a key in a custom key store.
  EOT
  type        = bool
  default     = true
  nullable    = false

  validation {
    condition     = !var.enable_key_rotation || (var.customer_master_key_spec == "SYMMETRIC_DEFAULT" && var.custom_key_store_id == null)
    error_message = "enable_key_rotation works only for SYMMETRIC_DEFAULT keys outside a custom key store. Set enable_key_rotation = false for this key."
  }
}

variable "key_usage" {
  description = <<-EOT
    What the key is used for: `ENCRYPT_DECRYPT` (the default), `SIGN_VERIFY`, `GENERATE_VERIFY_MAC` or `KEY_AGREEMENT`. It must fit `customer_master_key_spec`. Changing it replaces the key.
  EOT
  type        = string
  default     = "ENCRYPT_DECRYPT"
  nullable    = false

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"], var.key_usage)
    error_message = "key_usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, GENERATE_VERIFY_MAC or KEY_AGREEMENT."
  }
}

variable "multi_region" {
  description = <<-EOT
    Create a multi-Region primary key, which can later be copied to other Regions as replica keys with the same key material. Replicas are not created by this module. A key cannot be converted later: changing this replaces the key.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "name" {
  description = <<-EOT
    The key's alias, without the `alias/` prefix, such as `course-materials`. The module creates the alias `alias/<name>`, which applications and other AWS services can use in place of the key ID. Up to 250 characters of letters, numbers, `/`, `_` and `-`. It must be unique in the account and Region, and must not begin with `aws/`, which is reserved for AWS managed keys.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_-]{1,250}$", var.name)) && !startswith(lower(var.name), "aws/") && !startswith(var.name, "alias/")
    error_message = "name must be 1-250 characters of letters, numbers, /, _ and -, without the alias/ prefix, and must not begin with aws/."
  }
}

variable "policy" {
  description = <<-EOT
    Who may manage and use the key. The key policy always lets the key's own account control the key through IAM policies, which is the AWS default; nothing outside the account has access unless it is listed here.

    - `administrator_account_ids` - (Optional) 12-digit IDs of other AWS accounts that may manage the key: change its policy, tags and rotation, disable it, and schedule its deletion. They cannot use it to encrypt or decrypt.
    - `administrator_arns` - (Optional) ARNs of IAM roles or users that may manage the key, with the same permissions.
    - `user_account_ids` - (Optional) 12-digit IDs of other AWS accounts that may use the key. Each account still needs IAM policies for its own roles and users.
    - `user_arns` - (Optional) ARNs of IAM roles or users that may use the key.
    - `user_organization_ids` - (Optional) AWS Organization IDs (`o-xxxxxxxxxx`). Every role and user in every account of these organizations may use the key. In other accounts, their own IAM policies must also allow it; in the key's own account, if it is in one of these organizations, the key policy alone is enough, so every role and user there can use the key without an IAM policy.
    - `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the key policy, for anything the options above do not cover, such as letting an AWS service use the key. Statement IDs (`Sid`) must be unique across the whole policy. See the [CloudWatch Logs example](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/cloudwatch-logs).

    "Use" means the operations the key type allows: encrypt, decrypt and generate data keys for symmetric keys; encrypt and decrypt, or sign and verify, for RSA keys; sign and verify, or derive shared secrets, for elliptic curve keys; generate and verify MACs for HMAC keys. Users of a symmetric key listed in `user_account_ids` and `user_arns` may also create grants for AWS resources, which services such as Amazon EBS need.

    Every role, user and account listed must exist when the policy is applied. AWS rejects a key policy that names a principal it cannot find.
  EOT
  type = object({
    administrator_account_ids = optional(list(string), [])
    administrator_arns        = optional(list(string), [])
    user_account_ids          = optional(list(string), [])
    user_arns                 = optional(list(string), [])
    user_organization_ids     = optional(list(string), [])
    source_policy_documents   = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for id in concat(var.policy.administrator_account_ids, var.policy.user_account_ids) : can(regex("^[0-9]{12}$", id))
    ])
    error_message = "policy.administrator_account_ids and policy.user_account_ids must contain 12-digit AWS account IDs."
  }

  validation {
    condition = alltrue([
      for arn in concat(var.policy.administrator_arns, var.policy.user_arns) : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:(role|user)/.+$", arn))
    ])
    error_message = "policy.administrator_arns and policy.user_arns must contain IAM role or user ARNs, such as arn:aws:iam::123456789012:role/example."
  }

  validation {
    condition     = alltrue([for id in var.policy.user_organization_ids : can(regex("^o-[a-z0-9]{10,32}$", id))])
    error_message = "policy.user_organization_ids must contain AWS Organization IDs (o-xxxxxxxxxx)."
  }

  validation {
    condition     = alltrue([for doc in var.policy.source_policy_documents : can(jsondecode(doc).Statement[0])])
    error_message = "Each of policy.source_policy_documents must be a JSON policy document with a non-empty Statement list."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the key and its alias in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}
