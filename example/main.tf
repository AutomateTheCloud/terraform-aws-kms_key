terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: KMS Key
module "kms_key" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope       = "Demo"
    purpose     = "KMS Key"
    environment = "prd"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  name = "demo-key"
  description = "Demo - KMS Key"

  policy = {
    owner = {
      account_ids = ["075803088721"]
      roles       = ["arn:aws:iam::712396368398:role/saml_transition/saml_transition-Administrator"]
    }
    share = {
      account_ids = ["237678820401"]
      roles       = ["arn:aws:iam::487851776281:role/saml_transition/saml_transition-Administrator"]
    }
  }

  # bypass_policy_lockout_safety_check = false
  # custom_key_store_id = null
  # customer_master_key_spec = "SYMMETRIC_DEFAULT"
  # deletion_window_in_days = 7
  # enable_key_rotation = true
  # key_usage = "ENCRYPT_DECRYPT"
  # multi_region = false
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.kms_key.metadata
}
