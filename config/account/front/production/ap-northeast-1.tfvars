aws_network_type          = "front"

second_octet              = 0

config_s3_bucket          = "service"
resource_s3_bucket        = "service"
environment               = "production"

region                    = "ap-northeast-1"
# Use Availability zone
availability_zone = ["ap-northeast-1a", "ap-northeast-1c"]

# AMI ID
ec2_ami                   = "ami-a77c30c1"

delegate_domain           = "fugafuga.com"
common_key                = "service"
maintenance_user          = "service"

auto_scale_default        = 2

# mandatory resources are jenkins(master), bastion, ldap and nagios
optional_resources = [
  "bastion_log",
  "bastion_secure_log",
  "jenkins_slave",
  "jenkins_slave_apply",
  "jenkins_slave_plan",
  "log_aggregator"
]
jenkins_slave_count       = 1

remote_maintenance_cidr_blocks_fr = [
  "0.0.0.0/29",
  "0.0.0.0/31"
]

remote_maintenance_cidr_blocks_aism = [
  "0.0.0.0/32"
]

# ldap-root
ldap_rootdn                = "dc=account,dc=hogehoge,dc=com"
ldap_admin_group           = "admin_group"
ldap_rootpw                = "password"

nagiosadmin_pw = "password"
dxc-support_pw = "password"

slack_alert_ch                                = "channnel"

kms_administrators = [
  "hoge.hoge",
  "fuga.fuga",
  "hoge.fuga"
]

slack_webhook_url                             = "hogehoge"

slack_config                                  = {
    alert_channel = "#channel"
    color_id      = "#d00000"
    user_name     = "username"
    icon          = ":bow:"
}
