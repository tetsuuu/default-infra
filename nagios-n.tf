data "template_file" "nagios-n-01" {
  template = "${file("./userdata-template/nagios-n.tpl")}"

  vars {
    aws_network_type   = "${var.aws_network_type}"
    resource_s3_bucket = "${var.resource_s3_bucket}"
    maintenance_user   = "${var.maintenance_user}"
    nagiosadmin_pw     = "${var.nagiosadmin_pw}"
    dxc-support_pw     = "${var.dxc-support_pw}"
    environment        = "${var.environment}"
    region             = "${var.region}"
    slack_alert_ch     = "${var.slack_alert_ch}"
    nagios_host_no     = "02"
  }
}

data "template_file" "nagios-n-02" {
  template = "${file("./userdata-template/nagios-n.tpl")}"

  vars {
    aws_network_type   = "${var.aws_network_type}"
    resource_s3_bucket = "${var.resource_s3_bucket}"
    maintenance_user   = "${var.maintenance_user}"
    nagiosadmin_pw     = "${var.nagiosadmin_pw}"
    dxc-support_pw     = "${var.dxc-support_pw}"
    environment        = "${var.environment}"
    region             = "${var.region}"
    slack_alert_ch     = "${var.slack_alert_ch}"
    nagios_host_no     = "01"
  }
}

resource "aws_instance" "nagios-n-01" {
  depends_on                  = ["aws_nat_gateway.public"]
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.nagios-n-sg.id}"]
  associate_public_ip_address = false
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.nagios-n.name}"

  user_data                   = "${data.template_file.nagios-n-01.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = false
  }

  tags {
    "Name" = "${var.region}-nagios-n-01"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "nagios"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-nagios-n-01"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "nagios"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  lifecycle {
    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
      "key_name",
      "root_block_device.0.volume_type",
      "subnet_id",
      "vpc_security_group_ids",
      "ebs_optimized"
    ]
  }
}

resource "aws_instance" "nagios-n-02" {
  depends_on                  = ["aws_instance.nagios-n-01","aws_route53_record.nagios-n-01-internal","aws_nat_gateway.public"]
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.1.id}"
  vpc_security_group_ids      = ["${aws_security_group.nagios-n-sg.id}"]
  associate_public_ip_address = false
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.nagios-n.name}"

  user_data                   = "${data.template_file.nagios-n-02.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = false
  }

  tags {
    "Name" = "${var.region}-nagios-n-02"
    "Service" = "maintenance"
    "Segment" = "private"
    "Role" = "nagios"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-nagios-n-02"
    "Service" = "maintenance"
    "Segment" = "private"
    "Role" = "nagios"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  lifecycle {
    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
      "key_name",
      "root_block_device.0.volume_type",
      "subnet_id",
      "vpc_security_group_ids",
      "ebs_optimized"
    ]
  }
}

resource "aws_iam_instance_profile" "nagios-n" {
  name  = "${var.region}-nagios-n"
  role  = "${aws_iam_role.nagios-n.name}"
}

resource "aws_iam_role" "nagios-n" {
  name               = "${var.region}-nagios-n"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

resource "aws_iam_role_policy_attachment" "nagios-read-cloud-watch-attach" {
  depends_on = ["aws_iam_role.nagios-n"]
  role       = "${aws_iam_role.nagios-n.id}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "nagios-read-cloud-watch-logs-attach" {
  depends_on = ["aws_iam_role.nagios-n"]
  role       = "${aws_iam_role.nagios-n.id}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "nagios-read-resources3config-attach" {
  depends_on = ["aws_iam_role.nagios-n"]
  role       = "${aws_iam_role.nagios-n.name}"
  policy_arn = "${aws_iam_policy.r_src_s3_cnf.arn}"
}

resource "aws_iam_role_policy_attachment" "nagios-allow-ecs-list-tasks-attach" {
  depends_on = ["aws_iam_role.nagios-n", "aws_iam_policy.allow_ecs_list_tasks"]
  role       = "${aws_iam_role.nagios-n.name}"
  policy_arn = "${aws_iam_policy.allow_ecs_list_tasks.arn}"
}

resource "aws_iam_policy" "stop-nagios-instance-n-01" {
  depends_on = ["aws_instance.nagios-n-01"]
  name = "${var.region}-stop-nagios-instance-v2-01"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "getInstanceList",
      "Action": [
        "ec2:describe*"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Sid": "stopNagiosInstance",
      "Action": [
        "ec2:StopInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.self.account_id}:instance/${aws_instance.nagios-n-01.id}"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "stop-nagios-instance-n-02" {
  depends_on = ["aws_instance.nagios-n-02"]
  name = "${var.region}-stop-nagios-instance-v2-02"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "getInstanceList",
      "Action": [
        "ec2:describe*"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Sid": "stopNagiosInstance",
      "Action": [
        "ec2:StopInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.self.account_id}:instance/${aws_instance.nagios-n-02.id}"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "stop-nagios-instance-01-attach" {
  depends_on = ["aws_iam_policy.stop-nagios-instance-n-01"]
  role       = "${aws_iam_role.nagios-n.name}"
  policy_arn = "${aws_iam_policy.stop-nagios-instance-n-01.arn}"
}

resource "aws_iam_role_policy_attachment" "stop-nagios-instance-02-attach" {
  depends_on = ["aws_iam_policy.stop-nagios-instance-n-02"]
  role       = "${aws_iam_role.nagios-n.name}"
  policy_arn = "${aws_iam_policy.stop-nagios-instance-n-02.arn}"
}

resource "aws_alb_target_group_attachment" "nagios-n-01-attach" {
  target_group_arn = "${aws_alb_target_group.nagios-n.arn}"
  target_id        = "${aws_instance.nagios-n-01.id}"
  port             = 80
}

resource "aws_alb_target_group_attachment" "nagios-n-02-attach" {
  target_group_arn = "${aws_alb_target_group.nagios-n.arn}"
  target_id        = "${aws_instance.nagios-n-02.id}"
  port             = 80
}

resource "aws_security_group" "nagios-n-sg" {
  name        = "${var.region}-nagios-n-ingress"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  tags {
    "Name"    = "${var.region}-nagios-n-ingress"
    "Service" = "maintenance"
  }

}

resource "aws_security_group_rule" "nagios-n-egress-rule" {
  depends_on        = ["aws_security_group.nagios-n-sg"]
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nagios-n-sg.id}"
}

resource "aws_security_group_rule" "nagios-n-ingress-rule-tcp22" {
  depends_on        = ["aws_security_group.nagios-n-sg"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.nagios-n-sg.id}"
}

resource "aws_security_group_rule" "nagios-n-ingress-rule-tcp80" {
  depends_on               = ["aws_security_group.nagios-n-sg"]
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.nagios-n-sg.id}"
}

resource "aws_security_group_rule" "nagios-n-ingress-rule-tcp24224" {
  depends_on        = ["aws_security_group.nagios-n-sg"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.nagios-n-sg.id}"
}

resource "aws_security_group_rule" "nagios-n-ingress-rule-tcp5666" {
  depends_on        = ["aws_security_group.nagios-n-sg"]
  type              = "ingress"
  from_port         = 5666
  to_port           = 5666
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.nagios-n-sg.id}"
}
