# AWS - KMS Key - Terraform Module
Terraform module for creating KMS Keys (AutomateTheCloud model)
***

## Usage
```hcl
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
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `bypass_policy_lockout_safety_check` | Bypass Policy Lockout Safety Check | `bool` | `false` |
| `custom_key_store_id` | Custom Key Store ID | `string` | |
| `customer_master_key_spec` | Customer Master Key Spec (SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, HMAC_256, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1) | `string` | `SYMMETRIC_DEFAULT` |
| `deletion_window_in_days` | Deletion Window in Days (7 to 30) | `number` | `7` |
| `description` | Description | `string` | |
| `enable_key_rotation` | Enable Key Rotation | `bool` | `true` |
| `enable_share_with_organization` | Share the with the AWS Organization | `bool` | `false` |
| `enable_sns_publish` | Enable SNS Publish capabilities | `bool` | `false` |
| `key_usage` | Key Usage (ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC) | `string` | `ENCRYPT_DECRYPT` |
| `multi_region` | Multi Region | `bool` | `false` |
| `name` | Name (Alias) | `string` | |
| `policy` | Policy (TODO - Policy) | `any` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#additional-tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `kms.key` | KMS Key |
| `kms.alias` | KMS Alias |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
