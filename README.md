# Terraform module for AWS KMS keys

Creates an AWS Key Management Service (KMS) key and an alias for it, with a key policy that says who may manage the key and who may use it.

The defaults are the settings most keys should have. A key created with only the required inputs is a symmetric encryption key that only its own AWS account can use, through IAM policies, and its key material rotates automatically once a year.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Key type | Symmetric encryption (`SYMMETRIC_DEFAULT`, `ENCRYPT_DECRYPT`) | `customer_master_key_spec`, `key_usage` |
| Alias | `alias/<name>` | `name` |
| Automatic rotation | On, once a year | `enable_key_rotation` |
| Who may manage the key | The key's own account, through IAM policies | `policy.administrator_account_ids`, `policy.administrator_arns` |
| Who may use the key | The key's own account, through IAM policies | `policy.user_account_ids`, `policy.user_arns`, `policy.user_organization_ids` |
| Access for AWS services | None | `enable_kafka`, `policy.source_policy_documents` |
| Waiting period before deletion | 7 days | `deletion_window_in_days` |
| Multi-Region primary key | Off | `multi_region` |
| Custom key store | None: the key is in AWS KMS | `custom_key_store_id` |

## Usage

```hcl
module "kms_key" {
  source  = "AutomateTheCloud/kms_key/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Course Materials"
    environment = "Production"
  }

  name        = "course-materials"
  description = "Encrypts the course materials bucket"
}
```

`details` and `name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on the key, and `name` becomes the alias `alias/course-materials`.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the key somewhere else without configuring another provider, set `region`:

```hcl
module "kms_key_us_west_2" {
  source  = "AutomateTheCloud/kms_key/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Backups", environment = "Production" }
  name    = "backups"
}
```

Because `region` is an ordinary input, one module block can create a key in each of several Regions with `for_each`. Each is a separate key with its own key material; to use the same key material in several Regions, see [multi-Region keys](#multi-region-keys).

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the key belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a key in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the key, the bucket it encrypts, its DNS zone and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_key" {
  source  = "AutomateTheCloud/kms_key/aws"
  version = "~> 1.0"

  details = local.details
  name    = "web-site-production"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_key.metadata.kms_key.arn` for the key's ARN, or `module.site_key.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`.

- [Basic key](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/basic): a symmetric encryption key with the module's defaults.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/complete): a key with one IAM role that manages it and another that uses it.
- [CloudWatch Logs](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/cloudwatch-logs): a key that one CloudWatch Logs log group is encrypted with, using a narrowly scoped statement for the service.
- [Signing key](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/signing): an elliptic curve key pair for digital signatures.

## Things to know

### Replacing a key loses data

Changing `customer_master_key_spec`, `key_usage`, `multi_region` or `custom_key_store_id` replaces the key: Terraform creates the new key, moves the alias to it, and then schedules the old key for deletion. Anything still encrypted under the old key can never be decrypted once it is deleted. Before applying a plan that says the key "must be replaced", re-encrypt your data, or cancel the plan.

### Deleting a key

AWS does not delete a key at once. When the key is destroyed, AWS disables it and deletes it after `deletion_window_in_days`, 7 days by default. Until then you can get it back with `aws kms cancel-key-deletion --key-id <key ID>`, and then enable it again with `aws kms enable-key`. The alias is deleted at once.

### Who can use the key

The key policy always contains the AWS default statement that gives the key's own account full control of the key. That statement does not let anyone in the account use the key by itself: it lets the account's IAM policies grant access. A role in the account can use the key if its IAM policy allows it, whether or not the role is listed in `policy`.

`policy.administrator_arns` and `policy.user_arns` grant access in the key policy itself, so the roles and users listed need no IAM policy for the key. Other accounts listed in `policy.user_account_ids` still have to give their own roles and users access with IAM policies.

`policy.user_organization_ids` reaches further than it looks. In the key's own account, if that account is in the organization, it lets every role and user use the key without any IAM policy, because the key policy alone is enough there. In the organization's other accounts, IAM policies must also allow it. Use it for a key that is meant for the whole organization, and list roles in `policy.user_arns` when only some should use it.

Every role, user and account named in the policy must exist. AWS rejects a key policy that names a principal it cannot find. If a role named in the policy is deleted and created again with the same name, the policy no longer applies to it: AWS stores the old role's internal ID, and shows it in the policy in place of the ARN.

### Letting AWS services use the key

Apart from `enable_kafka`, the module has no switches for particular AWS services. Which service needs which permissions, and for which of your resources, depends on the service, so write the statement yourself and pass it in `policy.source_policy_documents`. Limit each statement to your own resources with a condition, such as `kms:EncryptionContext:aws:logs:arn` for one log group or `aws:SourceAccount` for your account. Without one, the service could be asked to use your key on behalf of someone else's resource. The [CloudWatch Logs example](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/cloudwatch-logs) shows a statement for one log group.

`enable_kafka` adds a statement for Amazon MSK (`kafka.amazonaws.com`) without such a condition. Turn it on only for a key that is meant for your Kafka clusters.

Many services, such as Amazon S3 and Amazon EBS, need no statement: they use the key with the permissions of the role or user that asks them to, through grants.

### Key types and rotation

Only symmetric encryption keys (`SYMMETRIC_DEFAULT`) in AWS KMS can rotate automatically. For any other key type, or a key in a custom key store, set `enable_key_rotation = false`; the module rejects the combination otherwise. Rotation keeps every earlier version of the key material, so data encrypted before a rotation can still be decrypted.

After you turn rotation on or off, the next plan can show `rotation_period_in_days` changing in the `metadata` output, with no change to the key: the AWS provider records the value before AWS has updated it. `terraform apply -refresh-only` records the current value.

### Multi-Region keys

`multi_region = true` creates a multi-Region primary key. Its key material can be copied to other Regions as replica keys, with `aws_kms_replica_key`, which this module does not create. A key cannot be made multi-Region later.

### Cost

AWS charges a monthly fee for each key, and rotations can add to it. Requests to use the key are charged too. See [AWS KMS pricing](https://aws.amazon.com/kms/pricing/).

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-kms_key/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-kms_key/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-kms_key#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The key's alias, without the `alias/` prefix, such as `course-materials`. The module creates the alias `alias/<name>`, which applications and other AWS services can use in place of the key ID. Up to 250 characters of letters, numbers, `/`, `_` and `-`. It must be unique in the account and Region, and must not begin with `aws/`, which is reserved for AWS managed keys.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_bypass_policy_lockout_safety_check"></a> [bypass_policy_lockout_safety_check](#input_bypass_policy_lockout_safety_check)

Description: Skip the AWS check that stops a key policy from locking out the principal that sets it. Leave this `false`: a key whose policy nobody can change cannot be managed or deleted, and only AWS Support can recover it.

Type: `bool`

Default: `false`

#### <a name="input_custom_key_store_id"></a> [custom_key_store_id](#input_custom_key_store_id)

Description: The ID of a custom key store, such as an AWS CloudHSM key store (`cks-1234567890abcdef0`), to create the key in. `null`, the default, creates the key in AWS KMS itself. Keys in a custom key store must be symmetric encryption keys and cannot rotate automatically, so set `enable_key_rotation = false`. Changing this replaces the key.

Type: `string`

Default: `null`

#### <a name="input_customer_master_key_spec"></a> [customer_master_key_spec](#input_customer_master_key_spec)

Description: The type of key. Changing it replaces the key.

- `SYMMETRIC_DEFAULT` (the default) - A 256-bit symmetric key for encryption. AWS services that encrypt your data need this type.
- `RSA_2048`, `RSA_3072`, `RSA_4096` - RSA key pairs, for `ENCRYPT_DECRYPT` or `SIGN_VERIFY`.
- `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521` - Elliptic curve key pairs, for `SIGN_VERIFY` or `KEY_AGREEMENT`.
- `ECC_SECG_P256K1` - An elliptic curve key pair, for `SIGN_VERIFY`.
- `HMAC_224`, `HMAC_256`, `HMAC_384`, `HMAC_512` - Keys for hash-based message authentication codes (HMAC), for `GENERATE_VERIFY_MAC`.
- `ML_DSA_44`, `ML_DSA_65`, `ML_DSA_87` - Post-quantum signing key pairs, for `SIGN_VERIFY`. They need a newer AWS provider than the module's minimum, 6.0.

Only `SYMMETRIC_DEFAULT` keys can rotate automatically, so every other type needs `enable_key_rotation = false`.

Type: `string`

Default: `"SYMMETRIC_DEFAULT"`

#### <a name="input_deletion_window_in_days"></a> [deletion_window_in_days](#input_deletion_window_in_days)

Description: How many days, from 7 to 30, AWS waits before deleting the key after it is destroyed. During the wait the key cannot be used, and the deletion can be canceled with `aws kms cancel-key-deletion`. After it, everything encrypted under the key can never be decrypted again.

Type: `number`

Default: `7`

#### <a name="input_description"></a> [description](#input_description)

Description: A description of the key, shown in the AWS KMS console, such as `Encrypts the course materials bucket`. Up to 8,192 characters. `null`, the default, leaves it empty.

Type: `string`

Default: `null`

#### <a name="input_enable_kafka"></a> [enable_kafka](#input_enable_kafka)

Description: Let Amazon Managed Streaming for Apache Kafka (Amazon MSK), through the service principal `kafka.amazonaws.com`, encrypt and decrypt with the key, for Kafka clusters encrypted with it. The statement has no condition that limits it to your account or clusters. Works only with symmetric encryption keys (`SYMMETRIC_DEFAULT`).

Type: `bool`

Default: `false`

#### <a name="input_enable_key_rotation"></a> [enable_key_rotation](#input_enable_key_rotation)

Description: Rotate the key's cryptographic material automatically once a year. AWS keeps every earlier version, so data encrypted before a rotation can still be decrypted. Only symmetric encryption keys (`SYMMETRIC_DEFAULT`) created in AWS KMS can rotate: set this to `false` for any other key type, or a key in a custom key store.

Type: `bool`

Default: `true`

#### <a name="input_key_usage"></a> [key_usage](#input_key_usage)

Description: What the key is used for: `ENCRYPT_DECRYPT` (the default), `SIGN_VERIFY`, `GENERATE_VERIFY_MAC` or `KEY_AGREEMENT`. It must fit `customer_master_key_spec`. Changing it replaces the key.

Type: `string`

Default: `"ENCRYPT_DECRYPT"`

#### <a name="input_multi_region"></a> [multi_region](#input_multi_region)

Description: Create a multi-Region primary key, which can later be copied to other Regions as replica keys with the same key material. Replicas are not created by this module. A key cannot be converted later: changing this replaces the key.

Type: `bool`

Default: `false`

#### <a name="input_policy"></a> [policy](#input_policy)

Description: Who may manage and use the key. The key policy always lets the key's own account control the key through IAM policies, which is the AWS default; nothing outside the account has access unless it is listed here.

- `administrator_account_ids` - (Optional) 12-digit IDs of other AWS accounts that may manage the key: change its policy, tags and rotation, disable it, and schedule its deletion. They cannot use it to encrypt or decrypt.
- `administrator_arns` - (Optional) ARNs of IAM roles or users that may manage the key, with the same permissions.
- `user_account_ids` - (Optional) 12-digit IDs of other AWS accounts that may use the key. Each account still needs IAM policies for its own roles and users.
- `user_arns` - (Optional) ARNs of IAM roles or users that may use the key.
- `user_organization_ids` - (Optional) AWS Organization IDs (`o-xxxxxxxxxx`). Every role and user in every account of these organizations may use the key. In other accounts, their own IAM policies must also allow it; in the key's own account, if it is in one of these organizations, the key policy alone is enough, so every role and user there can use the key without an IAM policy.
- `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the key policy, for anything the options above do not cover, such as letting an AWS service use the key. Statement IDs (`Sid`) must be unique across the whole policy. See the [CloudWatch Logs example](https://github.com/AutomateTheCloud/terraform-aws-kms_key/tree/main/examples/cloudwatch-logs).

"Use" means the operations the key type allows: encrypt, decrypt and generate data keys for symmetric keys; encrypt and decrypt, or sign and verify, for RSA keys; sign and verify, or derive shared secrets, for elliptic curve keys; generate and verify MACs for HMAC keys. Users of a symmetric key listed in `user_account_ids` and `user_arns` may also create grants for AWS resources, which services such as Amazon EBS need.

Every role, user and account listed must exist when the policy is applied. AWS rejects a key policy that names a principal it cannot find.

Type:

```hcl
object({
    administrator_account_ids = optional(list(string), [])
    administrator_arns        = optional(list(string), [])
    user_account_ids          = optional(list(string), [])
    user_arns                 = optional(list(string), [])
    user_organization_ids     = optional(list(string), [])
    source_policy_documents   = optional(list(string), [])
  })
```

Default: `{}`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the key and its alias in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `kms_key` - The key's `arn`, `key_id` (also in `id`), `policy`, `region`, its settings (`customer_master_key_spec`, `key_usage`, `enable_key_rotation`, `rotation_period_in_days`, `multi_region`, `deletion_window_in_days`, `description`, `is_enabled`, `custom_key_store_id`, `xks_key_id`, `bypass_policy_lockout_safety_check`), `tags` and `tags_all`. Use the `arn` when another account or service needs to name the key.
- `kms_alias` - The alias's `name` (`alias/<name>`, also in `id`), `arn`, `region`, `target_key_id`, `target_key_arn` and `name_prefix`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-kms_key/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-kms_key/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
