resource "aws_alb" "maintenance-alb" {
  idle_timeout    = 60
  internal        = false
  name            = "maintenance-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = false

  tags {
    "Service" = "default"
    "Name"    = "maintenance-alb"
  }
}

resource "aws_alb_listener" "jenkins" {
  depends_on        = ["aws_alb.maintenance-alb", "aws_acm_certificate_validation.jenkins"]
  load_balancer_arn = "${aws_alb.maintenance-alb.id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "${aws_acm_certificate_validation.jenkins.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.jenkins.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "nagios" {
  count             = "${var.region != "ap-south-1" ? 1 : 0}"
  load_balancer_arn = "${aws_alb.maintenance-alb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.nagios.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "nagios" {
  count        = "${var.region != "ap-south-1" ? 1 : 0}"
  depends_on   = ["aws_alb_target_group.nagios"]
  listener_arn = "${aws_alb_listener.jenkins.arn}"
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.nagios.arn}"
  }

  condition {
    field  = "host-header"
    values = ["nagios.${var.region}.${var.delegate_domain}"]
  }
}

resource "aws_alb_listener_rule" "nagios-n" {
  depends_on   = ["aws_alb_target_group.nagios-n"]
  listener_arn = "${aws_alb_listener.jenkins.arn}"
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.nagios-n.arn}"
  }

  condition {
    field  = "host-header"
    values = ["nagios-n.${var.region}.${var.delegate_domain}"]
  }
}

resource "aws_alb_target_group" "jenkins" {
  name     = "jenkins"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default-vpc.id}"

  health_check {
    matcher = "200,403"
  }
}

resource "aws_alb_target_group" "nagios" {
  count    = "${var.region != "ap-south-1" ? 1 : 0}"
  name     = "nagios"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default-vpc.id}"

  health_check {
    matcher = "200,403"
  }
}

resource "aws_alb_target_group" "nagios-n" {
  name     = "nagios-n"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default-vpc.id}"

  health_check {
    matcher = "200,403"
  }
}

resource "aws_alb_listener_rule" "nexus" {
  count        = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  depends_on   = ["aws_alb_target_group.nexus"]
  listener_arn = "${aws_alb_listener.jenkins.arn}"
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.nexus.arn}"
  }

  condition {
    field  = "host-header"
    values = ["nexus.${var.region}.${var.delegate_domain}"]
  }
}

resource "aws_alb_listener_certificate" "nexus" {
  count           = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  depends_on      = ["aws_alb_listener.jenkins", "aws_acm_certificate_validation.nexus"]
  listener_arn    = "${aws_alb_listener.jenkins.arn}"
  certificate_arn = "${aws_acm_certificate.nexus.arn}"
}

resource "aws_alb_target_group" "nexus" {
  count    = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  name     = "nexus"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default-vpc.id}"

  health_check {
    path    = "/nexus/"
    matcher = "200,403"
  }
}

resource "aws_alb_target_group_attachment" "nexus" {
  count            = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  target_group_arn = "${aws_alb_target_group.nexus.arn}"
  target_id        = "${aws_instance.nexus.id}"
  port             = 8081
}

resource "aws_security_group" "alb" {
  name        = "default-alb"
  description = "Security grup for maintenance LB"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Name"    = "defailt-alb-ingress"
    "Service" = "default"
  }
}

resource "aws_security_group_rule" "maintenance-alb-ingress-443" {
  depends_on        = ["aws_security_group.alb"]
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb.id}"

  cidr_blocks = [
    "${var.remote_maintenance_cidr_blocks}",
    "${var.remote_maintenance_cidr_blocks_nttd}",
    "${var.remote_maintenance_cidr_blocks_central_jenkins}",
    "${var.remote_maintenance_cidr_blocks_qburst}",
  ]
}

resource "aws_security_group_rule" "maintenance-alb-ingress-80" {
  depends_on        = ["aws_security_group.alb"]
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb.id}"

  cidr_blocks = [
    "${var.remote_maintenance_cidr_blocks}",
    "${var.remote_maintenance_cidr_blocks_aism}",
  ]
}

resource "aws_lb_listener_certificate" "nagios-certificate" {
  count           = "${var.region != "ap-south-1" ? 1 : 0}"
  depends_on      = ["aws_alb.maintenance-alb", "aws_alb_listener.jenkins", "aws_acm_certificate_validation.nagios"]
  listener_arn    = "${aws_alb_listener.jenkins.arn}"
  certificate_arn = "${aws_acm_certificate.nagios.arn}"
}

resource "aws_lb_listener_certificate" "nagios-n-certificate" {
  depends_on      = ["aws_alb.maintenance-alb", "aws_alb_listener.jenkins", "aws_acm_certificate_validation.nagios-n"]
  listener_arn    = "${aws_alb_listener.jenkins.arn}"
  certificate_arn = "${aws_acm_certificate.nagios-n.arn}"
}
