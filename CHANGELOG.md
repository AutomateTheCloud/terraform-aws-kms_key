# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An AWS KMS key and its alias, with secure defaults: a symmetric encryption key that only its own account can use, through IAM policies, with automatic yearly rotation.
- Every key type AWS KMS offers: RSA and elliptic curve key pairs, HMAC keys, and key agreement, with checks that the key type, its usage and rotation fit together.
- A key policy with separate key administrators and key users, by account, IAM role or user, and AWS Organization, with the actions each key type allows, access for Amazon MSK through `enable_kafka`, and your own statements through `policy.source_policy_documents`.
- Multi-Region primary keys, custom key stores, and the deletion waiting period.
- `region`, to create the key in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic key, separate administrators and users, a CloudWatch Logs log group, and a signing key.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-kms_key/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-kms_key/releases/tag/v1.0.0
