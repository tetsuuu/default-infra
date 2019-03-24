resource "aws_instance" "jenkins" {
  ami                         = "${var.ec2_ami}"
  ebs_optimized               = false
  instance_type               = "m5.large"
  monitoring                  = false
  key_name                    = "${var.common_key}"
  subnet_id                   = "${aws_subnet.public.0.id}"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-ingress.id}"]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = "${aws_iam_instance_profile.jenkins.name}"
  disable_api_termination     = true

  user_data                   = "${file("userdata/jenkins.sh")}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.jenkins_root_block_device_volume_size}"
    delete_on_termination = "${var.jenkins_root_block_device_delete_on_termination}"
  }

  tags {
    "Service" = "default"
    "Name"    = "${var.region}-jenkins"
  }

  lifecycle {
    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
      "key_name",
      "root_block_device.0.volume_type",
      "root_block_device.0.volume_size",
      "subnet_id",
      "vpc_security_group_ids",
      "ebs_optimized"
    ]
  }

}

resource "aws_alb_target_group_attachment" "jenkins" {
  count            = 1
  target_group_arn = "${aws_alb_target_group.jenkins.arn}"
  target_id        = "${aws_instance.jenkins.id}"
  port             = 8080
}


resource "aws_security_group" "jenkins-ingress" {
  name        = "jenkins-ingress"
  description = "jenkins Security Group"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
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
    "Name"    = "jenkins-ingress"
    "Service" = "default"
  }
}

resource "aws_iam_instance_profile" "jenkins-docker-build" {
  name = "${var.region}-jenkins-docker-build"
  role = "${aws_iam_role.jenkins-docker-build.name}"
}

resource "aws_iam_role" "jenkins-docker-build" {
  name = "${var.region}-jenkins-docker-build"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins-docker-build" {
    role       = "${aws_iam_role.jenkins-docker-build.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.region}-jenkins"
  role = "${aws_iam_role.jenkins.name}"
}

resource "aws_iam_role" "jenkins" {
  name               = "${var.region}-jenkins"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins-read-s3" {
  depends_on = ["aws_iam_policy.r_s3_cnf"]
  role       = "${aws_iam_role.jenkins.id}"
  policy_arn = "${aws_iam_policy.r_s3_cnf.arn}"
}

resource "aws_iam_role_policy_attachment" "jenkins-power-user-access" {
  role       = "${aws_iam_role.jenkins.id}"
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins-iam-readonly" {
  role       = "${aws_iam_role.jenkins.id}"
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins-iam-pass-role" {
  depends_on = ["aws_iam_policy.allow_iam_default_role"]
  role       = "${aws_iam_role.jenkins.id}"
  policy_arn = "${aws_iam_policy.allow_iam_default_role.arn}"
}

resource "aws_iam_role_policy_attachment" "jenkins-iam-spotfleettagging" {
  role        = "${aws_iam_role.jenkins.id}"
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
