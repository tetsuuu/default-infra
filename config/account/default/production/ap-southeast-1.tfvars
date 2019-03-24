aws_network_type                                = "default"

second_octet                                    = "" //TODO

config_s3_bucket                                = "hogehoge"
resource_s3_bucket                              = "fugafuga"
environment                                     = "production"

region                                          = "ap-southeast-1"
# Use Availability zone
availability_zone                               = ["ap-southeast-1a", "ap-southeast-1b"]
# AMI ID
ec2_ami                                         = "ami-e2adf99e"

delegate_domain                                 = "hogehoge.com"
common_key                                      = "maintenance"
maintenance_user                                = "maintenance"

bastion_root_block_device_volume_size = 50
bastion_root_block_device_delete_on_termination = true
jenkins_root_block_device_volume_size = 50
jenkins_root_block_device_delete_on_termination = true
nexus_root_block_device_delete_on_termination   = true

# mandatory resources are jenkins(master), bastion, ldap and nagios
optional_resources                              = [
  "bastion_log",
  "jenkins_slave",
  "log_aggregator"
]
jenkins_slave_count                             = 1

remote_maintenance_cidr_blocks               = [
  "0.0.0.0/29",
  "0.0.0.0/31"
]

remote_maintenance_cidr_blocks_aism             = [
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
