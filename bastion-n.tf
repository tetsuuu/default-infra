data "template_file" "userdata-bastion-n" {
  template = "${file("userdata-template/bastion-n.tpl")}"

  vars {
    aws_network_type   = "${var.aws_network_type}"
    region             = "${var.region}"
    config_s3_bucket   = "${var.config_s3_bucket}"
    environment        = "${var.environment}"
    resource_s3_bucket = "${var.resource_s3_bucket}"

    MAINTENANCE_USER   = "${var.maintenance_user}"
    INSTANCE_NAME      = "${var.region}-bastion-n"

    LDAP_SERVER        = "ldap.${var.region}.maintenance"
    ROOTDN             = "${var.ldap_rootdn}"
    ACCESS_ALLOW_GROUP = "${var.ldap_admin_group},default"
  }
}

resource "aws_instance" "bastion-n" {
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "t3.micro"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion-n.id}"]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "${var.region}-bastion-n"

  user_data = "${data.template_file.userdata-bastion-n.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  tags {
    "Name"    = "${var.region}-bastion-n"
    "Service" = "default"
    "Segment" = "public"
    "Role"    = "bastion"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }

  volume_tags {
    "Name"    = "${var.region}-bastion-n"
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
      "ebs_optimized"
    ]
  }
}

resource "aws_security_group" "bastion-n" {
  name        = "bastion-n-sg"
  description = "Bastion operation Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name"    = "bastion-n-sg"
    "Service" = "default"
  }
}

resource "aws_security_group_rule" "bastion-n-rule-tcp22" {
  description       = "SSH from default vpc"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.remote_maintenance_cidr_blocks}"]
  security_group_id = "${aws_security_group.bastion-n.id}"
}

resource "aws_iam_instance_profile" "bastion-n" {
  name = "${var.region}-bastion-n"
  role = "${aws_iam_role.bastion-n.name}"
}

resource "aws_iam_role" "bastion-n" {
  name               = "${var.region}-bastion-n"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

resource "aws_iam_role_policy_attachment" "bastion-n-read-resources3config-attach" {
  depends_on = ["aws_iam_role.bastion-n", "aws_iam_policy.r_src_s3_cnf"]
  role       = "${aws_iam_role.bastion-n.name}"
  policy_arn = "${aws_iam_policy.r_src_s3_cnf.arn}"
}
