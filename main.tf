variable "aws_network_type" {}
variable "region" {}

variable "availability_zone" {
  type = "list"
}

variable "availability_zone_privatelink_extend" {
  type    = "list"
  default = []
}

variable "second_octet" {}
variable "ec2_ami" {}
variable "delegate_domain" {}
variable "config_s3_bucket" {}
variable "resource_s3_bucket" {}
variable "common_key" {}
variable "maintenance_user" {}
variable "environment" {}

variable "bastion_root_block_device_volume_size" {
  default = 20
}

variable "bastion_root_block_device_delete_on_termination" {
  default = false
}

variable "jenkins_root_block_device_volume_size" {
  default = 30
}

variable "jenkins_root_block_device_delete_on_termination" {
  default = false
}

variable "optional_resources" {
  # mandatory resources are jenkins(master), bastion, ldap and nagios
  type    = "list"
  default = []
}

variable "jenkins_slave_count" {
  default = 0
}

variable "jenkins_slave_build_count" {
  default = 0
}

variable "jenkins_slave_unittest_count" {
  default = 0
}

variable "nexus_root_block_device_volume_size" {
  default = 100
}

variable "nexus_root_block_device_delete_on_termination" {
  default = false
}

variable "remote_maintenance_cidr_blocks" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_central_jenkins" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_nttd" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_qburst" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_aism" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_secure_bastion" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_cn_anyconnect" {
  type    = "list"
  default = []
}

variable "remote_maintenance_cidr_blocks_cn_cdc" {
  type    = "list"
  default = []
}

variable "unittest_postgresql_user" {
  default = ""
}

variable "unittest_postgresql_password" {
  default = ""
}

variable "unittest_postgresql_db" {
  default = ""
}

variable "ldap_rootdn" {
  default = ""
}

variable "ldap_admin_group" {
  default = ""
}

variable "ldap_rootpw" {
  default = ""
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.46.0"
}

provider "template" {
  version = "~> 1.0.0"
}

data "aws_caller_identity" "self" {}

variable "nagiosadmin_pw" {
  default = ""
}

variable "dxc-support_pw" {
  default = ""
}

variable "slack_alert_ch" {
  default = ""
}

variable "slack_config" {
  type = "map"

  default = {
    alert_channel = "#channel"
    color_id      = "#d00000"
    user_name     = "username"
    icon          = ":wrench:"
  }
}

variable "kms_administrators" {
  type = "list"
}

variable "slack_webhook_url" {
  default = ""
}

data "aws_iam_user" "kms_admin" {
  count     = "${length(var.kms_administrators)}"
  user_name = "${element(var.kms_administrators, count.index)}"
}
