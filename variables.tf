variable "bypass_policy_lockout_safety_check" {
  description = "Bypass Policy Lockout Safety Check"
  type        = bool
  default     = false
}

variable "custom_key_store_id" {
  description = "Custom Key Store ID"
  type        = string
  default     = null
}

variable "customer_master_key_spec" {
  description = "Customer Master Key Spec (SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, HMAC_256, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1)"
  type        = string
  default     = "SYMMETRIC_DEFAULT"
}

variable "deletion_window_in_days" {
  description = "Deletion Window in Days (7 to 30)"
  type        = number
  default     = 7
}

variable "description" {
  description = "Description"
  type        = string
  default     = null
}

variable "enable_key_rotation" {
  description = "Enable Key Rotation"
  type        = bool
  default     = true
}

variable "enable_share_with_organization" {
  description = "Enable share the with the AWS Organization (true/false)"
  type        = bool
  default     = false
}

variable "enable_sns_publish" {
  description = "Enable SNS Publish capabilities (true/false)"
  type        = bool
  default     = false
}

variable "key_usage" {
  description = "Key Usage (ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC)"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "multi_region" {
  description = "Multi Region"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name (Alias)"
  type        = string
  default     = null
}

variable "policy" {
  description = "Policy"
  type        = any
  default     = null
}