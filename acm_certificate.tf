resource "aws_acm_certificate" "jenkins" {
  domain_name       = "${aws_route53_record.jenkins.fqdn}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    "Service" = "default"
    "Env"     = "${var.environment}"
  }
}

resource "aws_route53_record" "cert-dns-validate-record-jenkins" {
  depends_on = ["aws_acm_certificate.jenkins"]
  name       = "${aws_acm_certificate.jenkins.domain_validation_options.0.resource_record_name}"
  type       = "${aws_acm_certificate.jenkins.domain_validation_options.0.resource_record_type}"
  zone_id    = "${data.aws_route53_zone.root_zone.zone_id}"
  records    = ["${aws_acm_certificate.jenkins.domain_validation_options.0.resource_record_value}"]
  ttl        = 60

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "jenkins" {
  depends_on              = ["aws_route53_record.cert-dns-validate-record-jenkins", "aws_acm_certificate.jenkins"]
  certificate_arn         = "${aws_acm_certificate.jenkins.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert-dns-validate-record-jenkins.fqdn}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "nagios" {
  count             = "${var.region != "ap-south-1" ? 1 : 0}"
  domain_name       = "${aws_route53_record.nagios.fqdn}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    "Service" = "default"
    "Env"     = "${var.environment}"
  }
}

resource "aws_route53_record" "cert-dns-validate-record-nagios" {
  count      = "${var.region != "ap-south-1" ? 1 : 0}"
  depends_on = ["aws_acm_certificate.nagios"]
  name       = "${aws_acm_certificate.nagios.domain_validation_options.0.resource_record_name}"
  type       = "${aws_acm_certificate.nagios.domain_validation_options.0.resource_record_type}"
  zone_id    = "${data.aws_route53_zone.root_zone.zone_id}"
  records    = ["${aws_acm_certificate.nagios.domain_validation_options.0.resource_record_value}"]
  ttl        = 60

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "nagios" {
  count                   = "${var.region != "ap-south-1" ? 1 : 0}"
  depends_on              = ["aws_acm_certificate.nagios", "aws_route53_record.cert-dns-validate-record-nagios"]
  certificate_arn         = "${aws_acm_certificate.nagios.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert-dns-validate-record-nagios.fqdn}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "nagios-n" {
  domain_name       = "${aws_route53_record.nagios-n.fqdn}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    "Service" = "default"
    "Env"     = "${var.environment}"
  }
}

resource "aws_route53_record" "cert-dns-validate-record-nagios-n" {
  depends_on = ["aws_acm_certificate.nagios-n"]
  name       = "${aws_acm_certificate.nagios-n.domain_validation_options.0.resource_record_name}"
  type       = "${aws_acm_certificate.nagios-n.domain_validation_options.0.resource_record_type}"
  zone_id    = "${data.aws_route53_zone.root_zone.zone_id}"
  records    = ["${aws_acm_certificate.nagios-n.domain_validation_options.0.resource_record_value}"]
  ttl        = 60

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "nagios-n" {
  depends_on              = ["aws_acm_certificate.nagios-n", "aws_route53_record.cert-dns-validate-record-nagios-n"]
  certificate_arn         = "${aws_acm_certificate.nagios-n.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert-dns-validate-record-nagios-n.fqdn}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "nexus" {
  count             = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  domain_name       = "${aws_route53_record.nexus.fqdn}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    "Service" = "default"
    "Env"     = "${var.environment}"
  }
}

resource "aws_route53_record" "cert-dns-validate-record-nexus" {
  count      = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  depends_on = ["aws_acm_certificate.nexus"]
  name       = "${aws_acm_certificate.nexus.domain_validation_options.0.resource_record_name}"
  type       = "${aws_acm_certificate.nexus.domain_validation_options.0.resource_record_type}"
  zone_id    = "${data.aws_route53_zone.root_zone.zone_id}"
  records    = ["${aws_acm_certificate.nexus.domain_validation_options.0.resource_record_value}"]
  ttl        = 60

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "nexus" {
  count                   = "${contains(var.optional_resources, "nexus") ? 1 : 0}"
  depends_on              = ["aws_acm_certificate.nexus", "aws_route53_record.cert-dns-validate-record-nexus"]
  certificate_arn         = "${aws_acm_certificate.nexus.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert-dns-validate-record-nexus.fqdn}"]

  lifecycle {
    create_before_destroy = true
  }
}
