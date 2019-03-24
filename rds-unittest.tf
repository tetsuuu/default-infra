resource "aws_db_subnet_group" "unittest" {
  count       = "${contains(var.optional_resources, "rds_unittest") ? 1 : 0}"
  name        = "${var.region}-unittest"
  description = "db subnet for unittest"
  subnet_ids  = ["${aws_subnet.private.*.id}"]
}

resource "aws_security_group" "unittest-postgres" {
  count       = "${contains(var.optional_resources, "rds_unittest") ? 1 : 0}"
  name        = "unittest-db-sg"
  description = "for unittest postgres"
  vpc_id      = "${aws_vpc.default-vpc.id}"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.jenkins-slave-ingress.id}","${aws_security_group.jenkins-ingress.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "unittest-postgres" {
  count                      = "${contains(var.optional_resources, "rds_unittest") ? 1 : 0}"
  identifier                 = "unittest-postgres"
  storage_type               = "gp2"
  allocated_storage          = 120
  engine                     = "postgres"
  engine_version             = "9.6.3"
  instance_class             = "db.t2.medium"
  name                       = "${var.unittest_postgresql_db}"
  username                   = "${var.unittest_postgresql_user}"
  password                   = "${var.unittest_postgresql_password}"
  db_subnet_group_name       = "${aws_db_subnet_group.unittest.name}"
  parameter_group_name       = "${aws_db_parameter_group.unittest-postgres.name}"
  vpc_security_group_ids     = ["${aws_security_group.unittest-postgres.id}"]
  multi_az                   = false
  apply_immediately          = "true"
  auto_minor_version_upgrade = false
}

resource "aws_db_parameter_group" "unittest-postgres" {
  count  = "${contains(var.optional_resources, "rds_unittest") ? 1 : 0}"
  name   = "unittest-rds-pg"
  family = "postgres9.6"

  parameter {
    name  = "auto_explain.log_analyze"
    value = "1"
  }
  parameter {
    name  = "auto_explain.log_min_duration"
    value = "300"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "0"
  }
  parameter {
    name  = "log_statement"
    value = "none"
  }
  parameter {
    name  = "max_parallel_workers_per_gather"
    value = "2"
  }
  parameter {
    name  = "pg_hint_plan.enable_hint"
    value = "1"
  }
  parameter {
    name  = "pg_hint_plan.enable_hint_table"
    value = "0"
  }
  parameter {
    name  = "shared_preload_libraries"
    value = "auto_explain,pgaudit,pg_stat_statements,pg_hint_plan"
    apply_method = "pending-reboot"
  }
}

resource "aws_route53_record" "unittest_postgres_db_internal" {
  count   = "${contains(var.optional_resources, "rds_unittest") ? 1 : 0}"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "unittest-db.${var.region}.maintenance"
  type    = "CNAME"
  ttl     = "30"

  records = [
    "${aws_db_instance.unittest-postgres.address}"
  ]
}
