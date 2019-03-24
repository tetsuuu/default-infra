resource "aws_iam_policy" "r_s3_cnf" {
  name   = "${var.region}-ReadS3Config"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadConfigBucket",
      "Effect": "Allow",
      "Action":[
        "s3:Get*",
        "s3:List*"
      ],
      "Resource":[
        "arn:aws:s3:::${var.config_s3_bucket}",
        "arn:aws:s3:::${var.config_s3_bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "rw_s3_cnf" {
  name   = "${var.region}-RWS3Config"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadConfigBucket",
      "Effect": "Allow",
      "Action":[
        "s3:Get*",
        "s3:Put*",
        "s3:List*"
      ],
      "Resource":[
        "arn:aws:s3:::${var.config_s3_bucket}",
        "arn:aws:s3:::${var.config_s3_bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "r_src_s3_cnf" {
  name   = "${var.region}-ReadResourceS3Config"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadConfigBucket",
      "Effect": "Allow",
      "Action":[
        "s3:Get*",
        "s3:List*"
      ],
      "Resource":[
        "arn:aws:s3:::${var.resource_s3_bucket}",
        "arn:aws:s3:::${var.resource_s3_bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "r_src_s3_cnf_blog" {
  name   = "${var.region}-ReadResourceS3ConfigBastionLog"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadConfigBucket",
      "Effect": "Allow",
      "Action":[
        "s3:GetObject"
      ],
      "Resource":[
        "arn:aws:s3:::${var.resource_s3_bucket}/terraform/resource/maintenance/bastion-log/*",
        "arn:aws:s3:::${var.resource_s3_bucket}/terraform/resource/maintenance/bastion-secure-log/*"
      ]
    },
    {
      "Sid": "AllowListConfigBucket",
      "Effect": "Allow",
      "Action":[
        "s3:ListBucket"
      ],
      "Resource":[
        "arn:aws:s3:::${var.resource_s3_bucket}"
      ],
      "Condition":{
        "StringLike":{
          "s3:prefix":[
            "terraform/resource/maintenance/bastion-log/*",
            "terraform/resource/maintenance/bastion-secure-log/*"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "rw_src_s3_cnf" {
  name   = "${var.region}-ReadWriteResourceS3Config"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadWriteResourcecBucket",
      "Effect": "Allow",
      "Action":[
        "s3:Get*",
        "s3:Put*",
        "s3:List*"
      ],
      "Resource":[
        "arn:aws:s3:::${var.resource_s3_bucket}",
        "arn:aws:s3:::${var.resource_s3_bucket}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "allow_ecs_list_tasks" {
  name   = "${var.region}-AllowEcsListTasks"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEcsListTasks",
      "Effect": "Allow",
      "Action": [
        "ecs:ListTasks"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "allow_iam_default_role" {
  name   = "${var.region}-AllowIamSet"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadConfigBucket",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:CreatePolicy",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:DetachRolePolicy",
        "iam:DeleteInstanceProfile",
        "iam:DeletePolicy",
        "iam:DeleteRole",
        "iam:UpdateRoleDescription",
        "iam:CreateInstanceProfile",
        "iam:CreatePolicyVersion",
        "iam:AddRoleToInstanceProfile",
        "iam:DeletePolicyVersion",
        "iam:UpdateAssumeRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
