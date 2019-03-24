resource "aws_s3_bucket" "default-service-config-s3" {
  bucket = "fr-${var.aws_network_type}-${var.region}-config-${var.environment}"
  acl    = "private"

  force_destroy = "true"

  tags {
    Service = "default"
  }
}
