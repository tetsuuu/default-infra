aws_network_type                              = "default"

second_octet                                  = "" //TODO

config_s3_bucket                              = "hogehoge"
resource_s3_bucket                            = "fugafuga"
environment                                   = "staging"

region                                        = "ap-northeast-1"
# Use Availability zone
availability_zone                             = ["ap-northeast-1a", "ap-northeast-1c"]
# AMI ID
ec2_ami                                       = "ami-a77c30c1"

delegate_domain                               = "hogehoge.com"
common_key                                    = "maintenance"
maintenance_user                              = "maintenance"

nexus_root_block_device_delete_on_termination = true

# mandatory resources are jenkins(master), bastion, ldap and nagios
optional_resources = [
  "bastion_log",
  "bastion_secure_log",
  "jenkins_slave",
  "jenkins_slave_apply",
  "jenkins_slave_plan",
  "jenkins_slave_serverspec",
  "log_aggregator",
  "nexus"
]

jenkins_slave_count                           = 1

remote_maintenance_cidr_blocks                = [
  "0.0.0.0/29",
  "0.0.0.0/31"
]

remote_maintenance_cidr_blocks_aism           = [
  "0.0.0.0/32"
]

# ldap-root
ldap_rootdn                                   = "dc=account,dc=hogehoge,dc=com"
ldap_admin_group                              = "group"
ldap_rootpw                                   = "password"

nagiosadmin_pw                                = "password"
dxc-support_pw                                = "password"

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
