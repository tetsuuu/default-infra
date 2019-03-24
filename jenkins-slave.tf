data "template_file" "jenkins-slave-serverspec" {
  template = "${file("./userdata-template/jenkins-slave-serverspec.tpl")}"

  vars {
    resource_s3_config = "${var.resource_s3_bucket}"
  }
}

resource "aws_instance" "jenkins-slave" {
  count                       = "${contains(var.optional_resources, "jenkins_slave") ? var.jenkins_slave_count : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  //  associate_public_ip_address = false TODO tfbugs: always changed to true
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.jenkins.name}"

  user_data                   = "${file("userdata/jenkins-slave-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = "false"
  }

  tags {
    "Service" = "default"
    "Name"    = "${var.region}-jenkins-slave-${format("%02d", count.index +1)}"
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

resource "aws_instance" "jenkins-slave-build" {
  count                       = "${contains(var.optional_resources, "jenkins_slave_build") ? var.jenkins_slave_build_count : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  //  associate_public_ip_address = false TODO tfbugs: always changed to true
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "jenkins-slave-build"

  user_data                   = "${file("userdata/jenkins-slave-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = "false"
  }

  tags {
    "Service" = "default"
    "Name"    = "${var.region}-jenkins-slave-build-${format("%02d", count.index +1)}"
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

resource "aws_instance" "jenkins-slave-plan" {
  count                       = "${contains(var.optional_resources, "jenkins_slave_plan") ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  //  associate_public_ip_address = false TODO tfbugs: always changed to true
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "jenkins-slave-plan"

  user_data                   = "${file("userdata/jenkins-slave-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "false"
  }

  tags {
    "Service" = "default"
    "Name"    = "${var.region}-jenkins-slave-plan-01"
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

resource "aws_instance" "jenkins-slave-apply" {
  count                       = "${contains(var.optional_resources, "jenkins_slave_apply") ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  //  associate_public_ip_address = false TODO tfbugs: always changed to true
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "jenkins-slave-apply"

  user_data                   = "${file("userdata/jenkins-slave-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "false"
  }

  tags {
    "Service" = "default"
    "Name"    = "${var.region}-jenkins-slave-apply-01"
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

resource "aws_security_group" "jenkins-slave-ingress" {
  name        = "jenkins-slave-ingress"
  description = "jenkins Slave Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

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
    "Name"    = "jenkins-slave-ingress"
    "Service" = "default"
  }

  lifecycle {
    ignore_changes = [
      "user_data",
      "ami",
      "key_name",
      "root_block_device.0.volume_type",
      "subnet_id",
      "vpc_security_group_ids",
      "ebs_optimized"
    ]
  }
}

resource "aws_instance" "jenkins-slave-serverspec" {
  depends_on                  = ["aws_nat_gateway.public"]
  count                       = "${contains(var.optional_resources, "jenkins_slave_serverspec") ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.private.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  associate_public_ip_address = false
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.jenkins.name}"

  user_data                   = "${data.template_file.jenkins-slave-serverspec.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = "false"
  }

  tags {
    "Name" = "${var.region}-jenkins-slave-serverspec"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "jenkins-slave"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-jenkins-slave-serverspec"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "jenkins-slave"
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

resource "aws_instance" "jenkins-slave-unittest" {
  count                       = "${contains(var.optional_resources, "jenkins_slave_unittest") ? var.jenkins_slave_unittest_count : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-slave-ingress.id}"]
  //  associate_public_ip_address = false TODO tfbugs: always changed to true
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.jenkins.name}"

  user_data                   = "${file("userdata/jenkins-slave-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = "false"
  }

  tags {
    "Name" = "${var.region}-jenkins-slave-unittest"
    "Service" = "default"
    "Segment" = "private"
    "Role" = "jenkins-slave"
    "Env" = "${var.environment}"
    "Country" = "jp"
    "Cost" = "hogehoge"
  }

  volume_tags {
    "Name" = "${var.region}-jenkins-slave-unittest"
    "Service" = "default"
    "Segment" = "public"
    "Role" = "jenkins-slave"
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
