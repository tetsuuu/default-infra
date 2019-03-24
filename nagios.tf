resource "aws_instance" "nagios" {
  count                       = "${var.region != "ap-south-1" ? 1 : 0}"
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m3.medium"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.nagios-ingress.id}"]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "nagios"

  user_data                   = "${file("userdata/nagios-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  tags {
      "Service" = "maintenance"
      "Name" = "${var.region}-nagios"
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

resource "aws_alb_target_group_attachment" "nagios" {
  count            = "${var.region != "ap-south-1" ? 1 : 0}"
  target_group_arn = "${aws_alb_target_group.nagios.arn}"
  target_id        = "${aws_instance.nagios.id}"
  port             = 80
}

resource "aws_security_group" "nagios-ingress" {
  count       = "${var.region != "ap-south-1" ? 1 : 0}"
  name        = "nagios-ingress"
  description = "nagios Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${aws_vpc.default-vpc.cidr_block}"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
  }

  ingress {
    from_port         = 24224
    to_port           = 24224
    protocol          = "tcp"
    cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  }

  ingress {
    from_port         = 24224
    to_port           = 24224
    protocol          = "udp"
    cidr_blocks       = ["${aws_vpc.default-vpc.cidr_block}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    "Name" = "nagios-ingress"
    "Service" = "default"
  }
}
