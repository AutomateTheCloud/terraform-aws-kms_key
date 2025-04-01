data "aws_organizations_organization" "this" {
  count    = (var.enable_share_with_organization ? 1 : 0)
  provider = aws.this
}
