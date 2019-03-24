data "template_file" "userdata-bastion-log-n" {
  template = "${file("userdata-template/bastion-log-n.tpl")}"

  vars {
    resource_s3_bucket = "${var.resource_s3_bucket}"
    aws_network_type   = "${var.aws_network_type}"
    environment        = "${var.environment}"
    region             = "${var.region}"

    MAINTENANCE_USER = "${var.maintenance_user}"
    INSTANCE_NAME    = "${var.region}-bastion-log-n"

    LDAP_SERVER        = "ldap.${var.region}.default"
    ROOTDN             = "${var.ldap_rootdn}"
    ACCESS_ALLOW_GROUP = "${var.ldap_admin_group},default"
    ROOTPW             = "${var.ldap_rootpw}"

    MAINTENANCE_CIDR   = "${aws_vpc.default-vpc.cidr_block}"
  }
}

resource "aws_eip" "bastion_log" {
  count    = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  instance = "${aws_instance.bastion-log-n.id}"
  vpc      = "true"
}

resource "aws_volume_attachment" "bastion-log-n-log-volume" {
  count       = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  device_name = "/dev/xvdb"
  volume_id   = "${aws_ebs_volume.bastion-log-n-log-volume.id}"
  instance_id = "${aws_instance.bastion-log-n.id}"
  skip_destroy = true
}

resource "aws_instance" "bastion-log-n" {
  count                       = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.xlarge"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion-log-n-ingress.id}"]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "${var.region}-bastion-log-n"

  user_data = "${data.template_file.userdata-bastion-log-n.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  tags {
    "Name"    = "${var.region}-bastion-log-n"
    "Service" = "default"
    "Segment" = "public"
    "Role"    = "bastion"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }

  volume_tags {
    "Name"    = "${var.region}-bastion-log-n"
    "Service" = "default"
    "Segment" = "public"
    "Role"    = "bastion"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
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
      "ebs_optimized",
    ]
  }
}

resource "aws_ebs_volume" "bastion-log-n-log-volume" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  availability_zone = "${aws_subnet.public.0.availability_zone}"
  size              = 300
  type              = "gp2"

  tags {
    "Name"    = "${var.region}-bastion-log-n"
    "Service" = "default"
    "Segment" = "public"
    "Role"    = "bastion"
    "Brand"   = "fr"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }
}

resource "aws_security_group" "bastion-log-n-ingress" {
  count       = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  name        = "bastion-log-n-ingress"
  description = "bastion-log-n Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name"    = "bastion-log-n-ingress"
    "Service" = "default"
  }
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-tcp22-from-secure-bastion" {
  count             = "${contains(var.optional_resources, "bastion_log") && length(var.remote_maintenance_cidr_blocks_secure_bastion) > 0 ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.remote_maintenance_cidr_blocks_secure_bastion}"]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-tcp22" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [
    "${var.remote_maintenance_cidr_blocks}",
    "${var.remote_maintenance_cidr_blocks_nttd}",
    "${var.remote_maintenance_cidr_blocks_cn_anyconnect}",
    "${var.remote_maintenance_cidr_blocks_cn_cdc}"
  ]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-tcp24224" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-udp24224" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "udp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-tcp5666" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = 5666
  to_port           = 5666
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_security_group_rule" "bastion-log-n-ingress-rule-icmp" {
  count             = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on        = ["aws_security_group.bastion-log-n-ingress"]
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  security_group_id = "${aws_security_group.bastion-log-n-ingress.id}"
}

resource "aws_iam_instance_profile" "bastion-log-n" {
  count = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  name  = "${var.region}-bastion-log-n"
  role  = "${aws_iam_role.bastion-log-n.name}"
}

resource "aws_iam_role" "bastion-log-n" {
  count              = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  name               = "${var.region}-bastion-log-n"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

resource "aws_iam_role_policy_attachment" "bastion-log-n-read-resources3config-attach" {
  count      = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on = ["aws_iam_role.bastion-log-n", "aws_iam_policy.r_src_s3_cnf_blog"]
  role       = "${aws_iam_role.bastion-log-n.name}"
  policy_arn = "${aws_iam_policy.r_src_s3_cnf_blog.arn}"
}

resource "aws_iam_role_policy_attachment" "bastion-log-n-putmetrics" {
  count      = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  depends_on = ["aws_iam_role.bastion-log-n", "aws_iam_policy.r_src_s3_cnf"]
  role       = "${aws_iam_role.bastion-log-n.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_route53_record" "bastion-log" {
  count   = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "mng-log01.${var.region}.${var.delegate_domain}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_eip.bastion_log.public_ip}",
  ]
}

resource "aws_route53_record" "bastion_log_internal" {
  count   = "${contains(var.optional_resources, "bastion_log") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "bastion-log.${var.region}.default"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.bastion-log-n.private_ip}",
  ]
}
