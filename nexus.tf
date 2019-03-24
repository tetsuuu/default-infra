data "template_file" "nexus-userdata" {
  count    = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  template = "${file("./userdata-template/nexus.tpl")}"

  vars {
    resource_s3_bucket = "${var.resource_s3_bucket}"
  }
}

resource "aws_instance" "nexus" {
  depends_on                  = ["aws_nat_gateway.public"]
  count                       = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.nexus-sg.id}"]
  associate_public_ip_address = false
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.nexus.name}"
  disable_api_termination     = true

  user_data                   = "${data.template_file.nexus-userdata.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.nexus_root_block_device_volume_size}"
    delete_on_termination = "${var.nexus_root_block_device_delete_on_termination}"
  }

  tags {
    "Name"    = "${var.region}-nexus"
    "Service" = "default"
    "Segment" = "private"
    "Role"    = "nexus"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }

  volume_tags {
    "Name"    = "${var.region}-nexus"
    "Service" = "default"
    "Segment" = "private"
    "Role"    = "nexus"
    "Env"     = "${var.environment}"
    "Country" = "gl"
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

resource "aws_security_group" "nexus-sg" {
  count       = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  name        = "nexus-sg"
  description = "nexus Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
    cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name"    = "nexus-sg"
    "Service" = "maintenance"
  }
}

resource "aws_iam_instance_profile" "nexus" {
  count = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  name  = "${var.region}-nexus"
  role  = "${aws_iam_role.nexus.name}"
}

resource "aws_iam_role" "nexus" {
  count              = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  name               = "${var.region}-nexus"
  assume_role_policy = "${file("./policy/iam_assumerole.json")}"
}

resource "aws_iam_role_policy_attachment" "nexus-read-resources3config-attach" {
  count      = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  depends_on = ["aws_iam_role.nexus", "aws_iam_policy.r_src_s3_cnf"]
  role       = "${aws_iam_role.nexus.name}"
  policy_arn = "${aws_iam_policy.r_src_s3_cnf.arn}"
}
