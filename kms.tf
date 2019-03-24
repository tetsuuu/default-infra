data "aws_iam_policy_document" "kms_key_policy" {
  "statement" {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:root"]
    }
    actions = [ "kms:*" ]
    resources = [ "*" ]
  }

  "statement" {
    sid = "Allow access for Key Administrators"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [ "${data.aws_iam_user.kms_admin.*.arn}" ]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = [ "*" ]
  }

  "statement" {
    sid = "Allow use of the key"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [ "${data.aws_iam_user.kms_admin.*.arn}" ]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [ "*" ]
  }

  "statement" {
    sid = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [ "${data.aws_iam_user.kms_admin.*.arn}" ]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [ "*" ]
    condition {
      test = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [ "true" ]
    }
  }
}

resource "aws_kms_key" "hookurl_encryption" {
  description = "Encrypt/Decrypt slack Hook URL"
  policy = "${data.aws_iam_policy_document.kms_key_policy.json}"
}

resource "aws_kms_alias" "hookurl_encryption" {
  name = "alias/${var.region}-cloudwatch-alarm-to-slack"
  target_key_id = "${aws_kms_key.hookurl_encryption.key_id}"
}

resource "aws_kms_grant" "hookurl_encryption_lambda" {
  count             = "${var.slack_webhook_url != "" ? 1 : 0}"
  name              = "${var.region}-cloudwatch-alarm-to-slack-lambda"
  grantee_principal = "${aws_iam_role.container_deploy_error_notification_role.arn}"
  key_id            = "${aws_kms_key.hookurl_encryption.key_id}"
  operations        = ["Encrypt", "Decrypt"]
}

resource "aws_kms_grant" "hookurl_encryption_user" {
  count             = "${length(var.kms_administrators)}"
  name              = "${var.region}-cloudwatch-alarm-to-slack-Administrator-${format( "%02d", count.index + 1 )}"
  grantee_principal = "${element(data.aws_iam_user.kms_admin.*.arn, count.index )}"
  key_id            = "${aws_kms_key.hookurl_encryption.key_id}"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}
