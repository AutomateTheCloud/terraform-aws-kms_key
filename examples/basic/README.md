# Basic key

A symmetric encryption key with the alias `alias/example-basic`, and the module's defaults for everything else: only this account can use the key, through IAM policies, and its key material rotates once a year.

## Run it

```shell
terraform init
terraform apply
```

To choose another alias, add `-var 'name=<alias without alias/>'`. Aliases must be unique in the account and Region.

Remove it with `terraform destroy`. AWS deletes the key 7 days later; until then, `aws kms cancel-key-deletion` brings it back.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_name"></a> [name](#input_name)

Description: Alias for the key, without the alias/ prefix

Type: `string`

Default: `"example-basic"`

### Outputs

The following outputs are exported:

#### <a name="output_kms_key"></a> [kms_key](#output_kms_key)

Description: ARN and alias of the key
<!-- END_TF_DOCS -->
