# Complete

A key with separate administrators and users, which is how most shared keys should be set up. The example creates two IAM roles so that it can be applied on its own:

- `<name>-key-administrator` may manage the key (its policy, tags, rotation and deletion) but cannot encrypt or decrypt with it. Anyone in the account whose IAM policies allow it may assume this role.
- `<name>-application`, a role for an AWS Lambda function, may use the key but cannot manage it.

The key is also a multi-Region primary key, waits 30 days before it is deleted, and carries an extra `CostCenter` tag. Comments in `main.tf` show how to share it with other accounts or an AWS Organization.

## Run it

```shell
terraform init
terraform apply
```

The `kms_key` output shows the key policy the module wrote. Remove everything with `terraform destroy`. AWS deletes the key 30 days later; until then, `aws kms cancel-key-deletion` brings it back.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_name"></a> [name](#input_name)

Description: Alias for the key, without the alias/ prefix, and prefix for the IAM roles

Type: `string`

Default: `"example-complete"`

### Outputs

The following outputs are exported:

#### <a name="output_kms_key"></a> [kms_key](#output_kms_key)

Description: ARN, alias and policy of the key
<!-- END_TF_DOCS -->
