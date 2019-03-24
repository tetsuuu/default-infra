data "aws_route53_zone" "root_zone" {
  name = "${var.delegate_domain}."
}

resource "aws_route53_record" "bastion" {
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "bs.${var.region}.${var.delegate_domain}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.bastion-n.public_ip}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "fluentd" {
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "fluent.${var.region}.${var.delegate_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.maintenance-alb.dns_name}"
    zone_id                = "${aws_alb.maintenance-alb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "jenkins.${var.region}.${var.delegate_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.maintenance-alb.dns_name}"
    zone_id                = "${aws_alb.maintenance-alb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "nagios" {
  count   = "${var.region != "ap-south-1" ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "nagios.${var.region}.${var.delegate_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.maintenance-alb.dns_name}"
    zone_id                = "${aws_alb.maintenance-alb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "nagios-n" {
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "nagios-n.${var.region}.${var.delegate_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.maintenance-alb.dns_name}"
    zone_id                = "${aws_alb.maintenance-alb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_zone" "internal" {
  name = "${var.region}.maintenance"

  vpc {
    vpc_id = "${aws_vpc.default-vpc.id}"
  }

  lifecycle {
    ignore_changes = ["vpc"]
  }
}

resource "aws_route53_record" "jenkins_internal" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "jenkins.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.jenkins.private_ip}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins_slave_internal" {
  count      = "${contains(var.optional_resources, "jenkins_slave") ? var.jenkins_slave_count : 0}"
  depends_on = ["aws_instance.jenkins-slave"]
  zone_id    = "${aws_route53_zone.internal.zone_id}"
  name       = "jenkins-slave-${format("%02d", count.index +1)}.${var.region}.maintenance"
  type       = "A"
  ttl        = "30"

  records = [
    "${element(aws_instance.jenkins-slave.*.private_ip, count.index)}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins_slave_build_internal" {
  count      = "${contains(var.optional_resources, "jenkins_slave_build") ? var.jenkins_slave_build_count : 0}"
  depends_on = ["aws_instance.jenkins-slave-build"]
  zone_id    = "${aws_route53_zone.internal.zone_id}"
  name       = "jenkins-slave-build-${format("%02d", count.index +1)}.${var.region}.maintenance"
  type       = "A"
  ttl        = "30"

  records = [
    "${element(aws_instance.jenkins-slave-build.*.private_ip, count.index)}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins_slave_plan_internal" {
  count   = "${contains(var.optional_resources, "jenkins_slave_plan") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "jenkins-slave-plan-01.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.jenkins-slave-plan.private_ip}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins_slave_apply_internal" {
  count   = "${contains(var.optional_resources, "jenkins_slave_apply") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "jenkins-slave-apply-01.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.jenkins-slave-apply.private_ip}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "nexus" {
  count   = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.root_zone.zone_id}"
  name    = "nexus.${var.region}.${var.delegate_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.maintenance-alb.dns_name}"
    zone_id                = "${aws_alb.maintenance-alb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "nexus_internal" {
  count   = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "nexus.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.nexus.private_ip}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "fluentd_01_internal" {
  depends_on = ["aws_route53_record.log_aggregator_internal"]
  count      = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  zone_id    = "${aws_route53_zone.internal.zone_id}"
  name       = "fluentd-01.${var.region}.maintenance"
  type       = "CNAME"
  ttl        = "30"

  records = [
    "${aws_route53_record.log_aggregator_internal.fqdn}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ldap_slave_internal" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "ldap.${var.region}.maintenance"
  type    = "A"

  alias {
    name                   = "${aws_lb.ldap-internal-nlb.dns_name}"
    zone_id                = "${aws_lb.ldap-internal-nlb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "jenkins-slave-serverspec-internal" {
  count   = "${contains(var.optional_resources, "jenkins_slave_serverspec") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "jenkins-slave-serverspec.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.jenkins-slave-serverspec.private_ip}",
  ]
}

resource "aws_route53_record" "nagios-n-01-internal" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "nagios-n-01.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.nagios-n-01.private_ip}",
  ]
}

resource "aws_route53_record" "nagios-n-02-internal" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "nagios-n-02.${var.region}.maintenance"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.nagios-n-02.private_ip}",
  ]
}

resource "aws_route53_record" "nagios_log_internal" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "nagios-log.${var.region}.maintenance"
  type    = "A"

  alias {
    name                   = "${aws_lb.nagios-log-internal-nlb.dns_name}"
    zone_id                = "${aws_lb.nagios-log-internal-nlb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "log_aggregator_internal" {
  count   = "${contains(var.optional_resources, "log_aggregator") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "log-aggregator.${var.region}.maintenance"
  type    = "A"

  alias {
    name                   = "${aws_lb.log_aggregator_internal_nlb.dns_name}"
    zone_id                = "${aws_lb.log_aggregator_internal_nlb.zone_id}"
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
