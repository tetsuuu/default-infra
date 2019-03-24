aws_network_type          = "front"

second_octet              = 0

config_s3_bucket          = "service"
resource_s3_bucket        = "service"
environment               = "production"

region                    = "eu-central-1"
# Use Availability zone
availability_zone = ["eu-central-1a", "eu-central-1c"]

# AMI ID
ec2_ami                   = "ami-a058674b"

delegate_domain           = "fugafuga.com"
common_key                = "service"
maintenance_user          = "service"

# mandatory resources are jenkins(master), bastion, ldap and nagios
optional_resources = []

remote_maintenance_cidr_blocks = [
  "0.0.0.0/29",
  "0.0.0.0/31"
]

remote_maintenance_cidr_blocks_aism = [
  // VIR Bastion on FRIT production account for AISM operator
  "0.0.0.0/32"
]

# ldap-root
# ldap-root
ldap_rootdn                = "dc=account,dc=hogehoge,dc=com"
ldap_admin_group           = "admin_group"
ldap_rootpw                = "password"

nagiosadmin_pw             = "password"
dxc-support_pw             = "password"

slack_alert_ch             = "channnel"

kms_administrators = [
  "hoge.hoge",
  "fuga.fuga",
  "hoge.fuga"
]
