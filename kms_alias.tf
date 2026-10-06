# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_kms_alias" "this" {
  region        = var.region
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}
