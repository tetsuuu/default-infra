aws_network_type                              = "default"

second_octet                                  = "" //TODO

config_s3_bucket                              = "hogehoge"
resource_s3_bucket                            = "fugafuga"
environment                                   = "production"

region                                        = "us-east-1"
# Use Availability zone
availability_zone                             = ["us-east-1a", "us-east-1b"]
availability_zone_privatelink_extend          = ["us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

# AMI ID
ec2_ami                                       = "ami-1853ac65"

delegate_domain                               = "hogehoge.com"
common_key                                    = "maintenance"
maintenance_user                              = "maintenance"

# mandatory resources are jenkins(master), bastion, ldap and nagios
optional_resources = [
  "bastion_log",
  "bastion_secure_log",
  "jenkins_slave",
  "jenkins_slave_apply",
  "jenkins_slave_plan",
  "jenkins_slave_serverspec",
  "log_aggregator"
]

remote_maintenance_cidr_blocks             = [
  "0.0.0.0/29",
  "0.0.0.0/31"
]

remote_maintenance_cidr_blocks_secure_bastion = [
  "0.0.0.0/32"
]

remote_maintenance_cidr_blocks_aism           = [
  "0.0.0.0/32"
]

# ldap-root
ldap_rootdn                                     = "dc=account,dc=hogehoge,dc=com"
ldap_admin_group                                = "group"
ldap_rootpw                                     = "password"

nagiosadmin_pw                                  = "password"
dxc-support_pw                                  = "password"

slack_alert_ch                                  = "channel"

kms_administrators = [
    "fuga.fuga",
    "hoge.fuga"
]

slack_webhook_url           = "" //TODO

slack_config                                  = {
    alert_channel = "#channel"
    color_id      = "#d00000"
    user_name     = "username"
    icon          = ":bow:"
}
