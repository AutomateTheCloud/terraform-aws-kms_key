locals {
  owner_list_arns = formatlist("arn:aws:iam::%s:root", concat(try(var.policy.owner.account_ids, []), [data.aws_caller_identity.this.account_id]))
  owner_list      = concat(local.owner_list_arns, try(var.policy.owner.roles, []))

  share_list_arns = formatlist("arn:aws:iam::%s:root", try(var.policy.share.account_ids, []))
  share_list      = concat(local.share_list_arns, try(var.policy.share.roles, []))
}
