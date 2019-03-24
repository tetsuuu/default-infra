resource "aws_lb" "ldap-internal-nlb" {
  name                             = "ldap-internal-nlb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = ["${aws_subnet.private.*.id}"]
  idle_timeout                     = 60
  enable_deletion_protection       = false

  # TODO add access_logs
  #access_logs {
  #  bucket = "${aws_s3_bucket.log-bucket}"
  #}
  tags {
    "Name"    = "ldap-internal-nlb"
    "Service" = "default"
    "Segment" = "private"
    "Role"    = "ldap-slave-nlb"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }
}
resource "aws_lb_listener" "ldap-slave" {
  load_balancer_arn = "${aws_lb.ldap-internal-nlb.id}"
  port              = "389"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.ldap-slave.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "ldap-slave" {
  name     = "ldap-slave"
  port     = 389
  protocol = "TCP"
  vpc_id   = "${aws_vpc.default-vpc.id}"
}

resource "aws_lb_target_group_attachment" "ldap-slave-01" {
  depends_on       = ["aws_lb_target_group.ldap-slave"]
  target_group_arn = "${aws_lb_target_group.ldap-slave.arn}"
  target_id        = "${aws_instance.ldap-slave-01.id}"
  port             = 389
}

resource "aws_lb_target_group_attachment" "ldap-slave-02" {
  depends_on       = ["aws_lb_target_group.ldap-slave"]
  target_group_arn = "${aws_lb_target_group.ldap-slave.arn}"
  target_id        = "${aws_instance.ldap-slave-02.id}"
  port             = 389
}

resource "aws_lb" "nagios-log-internal-nlb" {
  name                             = "nagios-log-internal-nlb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = ["${aws_subnet.private.*.id}"]
  idle_timeout                     = 60
  enable_deletion_protection       = false

  tags {
    "Name"    = "nagios-log-internal-nlb"
    "Service" = "default"
    "Segment" = "private"
    "Role"    = "nagios-log-nlb"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }
}
resource "aws_lb_listener" "nagios-log" {
  load_balancer_arn = "${aws_lb.nagios-log-internal-nlb.id}"
  port              = "24224"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nagios-log.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "nagios-log" {
  name     = "nagios-log"
  port     = 24224
  protocol = "TCP"
  vpc_id   = "${aws_vpc.default-vpc.id}"
}

resource "aws_lb_target_group_attachment" "nagios-log-01" {
  depends_on       = ["aws_lb_target_group.nagios-log"]
  target_group_arn = "${aws_lb_target_group.nagios-log.arn}"
  target_id        = "${aws_instance.nagios-n-01.id}"
  port             = 24224
}

resource "aws_lb_target_group_attachment" "nagios-log-02" {
  depends_on       = ["aws_lb_target_group.nagios-log"]
  target_group_arn = "${aws_lb_target_group.nagios-log.arn}"
  target_id        = "${aws_instance.nagios-v2-02.id}"
  port             = 24224
}

resource "aws_lb" "log_aggregator_internal_nlb" {
  count                            = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name                             = "log-aggregator-internal-nlb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = ["${concat(aws_subnet.private.*.id, compact(split(",", length(aws_subnet.private_privatelink_extend.*.id) > 0 ? join(",", aws_subnet.private_privatelink_extend.*.id) : "" ) ) )}"]
  idle_timeout                     = 60
  enable_deletion_protection       = false

  tags {
    "Name"    = "log-aggregator-internal-nlb"
    "Service" = "default"
    "Segment" = "private"
    "Role"    = "log-aggregator-nlb"
    "Env"     = "${var.environment}"
    "Country" = "jp"
    "Cost"    = "hogehoge"
  }
}

resource "aws_lb_listener" "log_aggregator" {
  count             = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  load_balancer_arn = "${aws_lb.log_aggregator_internal_nlb.id}"
  port              = "24224"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.log_aggregator.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "log_aggregator" {
  count        = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  name         = "log-aggregator-ip"
  port         = 24224
  protocol     = "TCP"
  vpc_id       = "${aws_vpc.default-vpc.id}"
  target_type  = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "log_aggregator" {
  count            = "${aws_instance.fluentd_v2.count}"
  depends_on       = ["aws_lb_target_group.log_aggregator", "aws_instance.fluentd_v2"]
  target_group_arn = "${aws_lb_target_group.log_aggregator.arn}"
  target_id        = "${element(aws_instance.fluentd_v2.*.private_ip, count.index)}"
  port             = 24224
}
