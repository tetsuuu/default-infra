resource "aws_instance" "bastion" {
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "t3.micro"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion-ingress.id}"]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "bastion"
  disable_api_termination     = false

  user_data                   = "${file("userdata/bastion-${var.environment}.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.bastion_root_block_device_volume_size}"
    delete_on_termination = "${var.bastion_root_block_device_delete_on_termination}"
  }

  tags {
    "Service" = "default"
    "Name" = "${var.region}-bastion"
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

resource "aws_security_group" "bastion-ingress" {
    name        = "bastion-ingress"
    description = "Bastion Security Group"
    vpc_id      = "${aws_vpc.default-vpc.id}"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = [
          //TODO
          "0.0.0.0/32"
        ]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "Name" = "bastion-ingress"
        "Service" = "default"
    }
}
