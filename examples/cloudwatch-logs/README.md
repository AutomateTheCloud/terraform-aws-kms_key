# CloudWatch Logs

A key that encrypts one Amazon CloudWatch Logs log group. CloudWatch Logs encrypts log data with the key itself, so the key policy has to let the service use it. The statement for that is written in the example and passed to the module in `policy.source_policy_documents`.

The statement is limited to one log group by the condition on `kms:EncryptionContext:aws:logs:arn`: CloudWatch Logs can use the key for this log group and no other, in this account or any other. The log group's ARN is built from its name, because the key has to exist before the log group can be created with it.

## Run it

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`. The log group and its logs are deleted at once; AWS deletes the key 7 days later.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_name"></a> [name](#input_name)

Description: Alias for the key, without the alias/ prefix, and name of the log group

Type: `string`

Default: `"example-cloudwatch-logs"`

### Outputs

The following outputs are exported:

#### <a name="output_log_group"></a> [log_group](#output_log_group)

Description: Name of the log group and ARN of the key that encrypts it
<!-- END_TF_DOCS -->
