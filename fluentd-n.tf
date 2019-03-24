data "template_file" "userdata-fluentd-n" {
  template = "${file("userdata-template/fluentd-n.tpl")}"

  vars {
    aws_network_type         = "${var.aws_network_type}"
    region                   = "${var.region}"
    config_s3_bucket         = "${var.config_s3_bucket}"
    environment              = "${var.environment}"
    resource_s3_bucket       = "${var.resource_s3_bucket}"
    maintenance_service_name = "fluentd"
  }
}

resource "aws_instance" "fluentd_v2" {
  count                       = "${contains(var.optional_resources, "log_aggregator") ? 2 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${element(aws_subnet.private.*.id, count.index%2)}"
  vpc_security_group_ids      = ["${aws_security_group.fluentd-n-ingress.id}"]
  associate_public_ip_address = false
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.fluentd-n.name}"

  user_data                   = "${data.template_file.userdata-fluentd-n.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = false
  }

  tags {
    "Name"                    = "${var.region}-fluentd-${format("%02d", count.index + 1)}"
    "Service"                 = "default"
    "Segment"                 = "private"
    "Role"                    = "fluentd"
    "Env"                     = "${var.environment}"
    "Country"                 = "jp"
    "Cost"                    = "hogehoge"
  }

  volume_tags {
    "Name"                    = "${var.region}-fluentd-${format("%02d", count.index + 1)}"
    "Service"                 = "default"
    "Segment"                 = "private"
    "Role"                    = "fluentd"
    "Env"                     = "${var.environment}"
    "Country"                 = "jp"
    "Cost"                    = "hogehoge"
  }

  lifecycle {
    ignore_changes = [
      "user_data",
      "ami",
      "key_name",
      "root_block_device.0.volume_type",
      "vpc_security_group_ids",
      "ebs_optimized"
    ]
  }

}

resource "aws_security_group" "fluentd-n-ingress" {
  count       = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name        = "fluentd-n-ingress"
  description = "fluentd Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  tags {
    "Name"    = "fluentd-n-ingress"
    "Service" = "default"
  }
}

resource "aws_security_group_rule" "fluentd-n-egress-rule" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-tcp24224-service" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["10.${var.second_octet}.0.0/16"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-udp24224-service" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "udp"
  cidr_blocks       = ["10.${var.second_octet}.0.0/16"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-tcp24224-maintenance" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-udp24224-maintenance" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "udp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-tcp24224-class_b" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["172.0.0.0/12"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-udp24224-class_b" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "udp"
  cidr_blocks       = ["172.0.0.0/12"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-tcp24224-class_a" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-udp24224-class_a" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_security_group_rule" "fluentd-n-ingress-rule-tcp22" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-v2-ingress"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [
    "${aws_vpc.default-vpc.cidr_block}"
  ]
  security_group_id = "${aws_security_group.fluentd-n-ingress.id}"
}

resource "aws_iam_instance_profile" "fluentd-n" {
  count = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name  = "${var.region}-fluentd-n"
  role  = "${aws_iam_role.fluentd-n.name}"
}

resource "aws_iam_role" "fluentd-n" {
  count              = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name               = "${var.region}-fluentd-n"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

data "template_file" "write_datalake_s3_landing_policy" {
  template = "${file("./policy/iam_write_datalake_s3.json.tpl")}"

  vars {
    datalake_landing_bucekt = "${ var.region == "ap-northeast-1" ? format("arn:aws:s3:::fr-%s-data-lake-landing", var.environment ) : format("arn:aws:s3:::fr-%s-data-lake-landing-%s", var.environment, var.region ) }"
  }
}

resource "aws_iam_policy" "write-datalake-s3-landing" {
  count  = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name   = "${var.region}-WriteDatalakeS3Landing"
  policy = "${data.template_file.write_datalake_s3_landing_policy.rendered}"
}

resource "aws_iam_policy" "write-service-log-bucket" {
  count  = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name   = "${var.region}-WriteServiceLogBucket"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "WriteServiceLogBucket",
      "Effect": "Allow",
      "Action":[
        "s3:Put*",
        "s3:Get*",
        "s3:List*"
      ],
      "Resource":[
        "arn:aws:s3:::${var.region}-log-${var.environment}",
        "arn:aws:s3:::${var.region}-log-${var.environment}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ReadResourceS3Config-fluentd-n-attach" {
  count      = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on = [ "aws_iam_role.fluentd-n", "aws_iam_policy.r_src_s3_cnf" ]
  role       = "${aws_iam_role.fluentd-n.name}"
  policy_arn = "${aws_iam_policy.r_src_s3_cnf.arn}"
}

resource "aws_iam_role_policy_attachment" "write-datalake-s3-landing-fluentd-n-attach" {
  count      = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on = [ "aws_iam_role.fluentd-n", "aws_iam_policy.write-datalake-s3-landing" ]
  role       = "${aws_iam_role.fluentd-n.name}"
  policy_arn = "${aws_iam_policy.write-datalake-s3-landing.arn}"
}

resource "aws_iam_role_policy_attachment" "write-service-log-bucket-fluentd-n-attach" {
  count      = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on = [ "aws_iam_role.fluentd-n", "aws_iam_policy.write-service-log-bucket" ]
  role       = "${aws_iam_role.fluentd-n.name}"
  policy_arn = "${aws_iam_policy.write-service-log-bucket.arn}"
}

resource "aws_vpc_endpoint_service" "log_aggregator" {
  count                       = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  depends_on                  = ["aws_lb.log_aggregator_internal_nlb"]
  acceptance_required         = false
  network_load_balancer_arns  = [
    "${aws_lb.log_aggregator_internal_nlb.arn}"
  ]
}

output "vpc_endpoint_service_name_log_aggregator" {
  value = "${aws_vpc_endpoint_service.log_aggregator.*.service_name}"
}
