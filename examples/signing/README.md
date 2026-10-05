# Signing key

An elliptic curve key pair (`ECC_NIST_P256`) for digital signatures. The private key never leaves AWS KMS: you send data to KMS and it returns a signature. Anyone with the public key can check the signature, without AWS credentials.

Asymmetric keys cannot rotate automatically, so the example sets `enable_key_rotation = false`.

## Run it

```shell
terraform init
terraform apply
```

Sign a message and verify the signature:

```shell
KEY=alias/example-signing
SIG=$(aws kms sign --key-id $KEY --message fileb://<(printf hello) \
  --message-type RAW --signing-algorithm ECDSA_SHA_256 --query Signature --output text)
aws kms verify --key-id $KEY --message fileb://<(printf hello) --message-type RAW \
  --signing-algorithm ECDSA_SHA_256 --signature fileb://<(echo "$SIG" | base64 -d) \
  --query SignatureValid
```

`aws kms get-public-key --key-id alias/example-signing` returns the public key, for checking signatures elsewhere.

Remove it with `terraform destroy`. AWS deletes the key 7 days later.

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

Default: `"example-signing"`

### Outputs

The following outputs are exported:

#### <a name="output_kms_key"></a> [kms_key](#output_kms_key)

Description: ARN and alias of the key
<!-- END_TF_DOCS -->
