data "template_file" "ldap-slave" {
  template = "${file("./userdata-template/ldap-slave.tpl")}"

  vars {
    AWS_NETWORK_TYPE = "${var.aws_network_type}"
    CONFIG_S3_BUCKET = "${var.config_s3_bucket}"
    RES_S3_BUCKET = "${var.resource_s3_bucket}"
    STAGE = "${var.environment}"

    ROOTPW = "${var.ldap_rootpw}"
    ROOTDN = "${var.ldap_rootdn}"
    LDAP_ADMIN_GROUP = "${var.ldap_admin_group}"
    MAINTENANCE_USER = "${var.maintenance_user}"
    JENKINS_HOST = "${var.region}-jenkins"
  }
}

# new ldap-slave exists on each regions per front / pet account
resource "aws_instance" "ldap-slave-01" {
  depends_on = [
    "aws_iam_role_policy_attachment.ldap-slave-read-resources3config-attach",
    "aws_iam_role_policy_attachment.ldap-slave-reads3config-attach",
    "aws_nat_gateway.public"
  ]
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "t3.micro"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.ldap-slave.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ldap-slave.name}"
  associate_public_ip_address = false
  source_dest_check           = true
  disable_api_termination     = false

  user_data = "${data.template_file.ldap-slave.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  tags {
    "Name" = "${var.region}-ldap-slave-01"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "ldap-slave"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-ldap-slave-01"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "ldap-slave"
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

resource "aws_instance" "ldap-slave-02" {
  depends_on = [
    "aws_iam_role_policy_attachment.ldap-slave-read-resources3config-attach",
    "aws_iam_role_policy_attachment.ldap-slave-reads3config-attach",
    "aws_nat_gateway.public"
  ]
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "t3.micro"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.1.id}"
  vpc_security_group_ids      = ["${aws_security_group.ldap-slave.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ldap-slave.name}"
  associate_public_ip_address = false
  source_dest_check           = true
  disable_api_termination     = false

  user_data = "${data.template_file.ldap-slave.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  tags {
    "Name" = "${var.region}-ldap-slave-02"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "ldap-slave"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-ldap-slave-02"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "ldap-slave"
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

resource "aws_security_group" "ldap-slave" {
  name        = "ldap-slave-sg"
  description = "LDAP-master Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  ingress {
    from_port       = 389
    to_port         = 389
    protocol        = "tcp"
    cidr_blocks     = ["${aws_vpc.default-vpc.cidr_block}"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${aws_vpc.default-vpc.cidr_block}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "ldap-slave-sg"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "ldap-slave"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }
}

resource "aws_iam_instance_profile" "ldap-slave" {
  name  = "${var.region}-ldap-slave"
  role  = "${aws_iam_role.ldap-slave.name}"
}

resource "aws_iam_role" "ldap-slave" {
  name               = "${var.region}-ldap-slave"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

resource "aws_iam_role_policy_attachment" "ldap-slave-reads3config-attach" {
  depends_on = ["aws_iam_role.ldap-slave", "aws_iam_policy.r_s3_cnf"]
  role       = "${aws_iam_role.ldap-slave.name}"
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:policy/${var.region}-ReadS3Config"
}

resource "aws_iam_role_policy_attachment" "ldap-slave-read-resources3config-attach" {
  depends_on = ["aws_iam_role.ldap-slave"]
  role       = "${aws_iam_role.ldap-slave.name}"
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:policy/${var.region}-ReadResourceS3Config"
}
