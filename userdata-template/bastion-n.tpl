#!/bin/bash -v
yum update -y

yum -y remove ntp
yum -y install chrony
chkconfig chronyd on
/etc/init.d/chronyd start

# configure logrotate
# enabling log compress (logrotate.conf)
sed -i -e 's/#compress/compress/' /etc/logrotate.conf

# get a instance region
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')

# disable ec2-user
## create default user
useradd --no-user-group --gid root --uid 1000 ${MAINTENANCE_USER} -s /bin/bash -c "${aws_network_type} admin user"

## copy authorized_key
mkdir -p /home/${MAINTENANCE_USER}/.ssh
cp /home/ec2-user/.ssh/authorized_keys /home/${MAINTENANCE_USER}/.ssh/authorized_keys
chown -R ${MAINTENANCE_USER}:root /home/${MAINTENANCE_USER}/.ssh
chmod 600 /home/${MAINTENANCE_USER}/.ssh/authorized_keys

## enable SUDOERS
cat > /etc/sudoers.d/${MAINTENANCE_USER} << 'EOL'
${MAINTENANCE_USER} ALL=(ALL) NOPASSWD:ALL
EOL

chmod 400 /etc/sudoers.d/${MAINTENANCE_USER}

## disable sudo
sed -i -e "s%ec2-user%#ec2-user%g" /etc/sudoers.d/cloud-init
## delete ec2-user
userdel -r ec2-user
## replace cloud config
sed -i -e "s%name: ec2-user%name: ${MAINTENANCE_USER}%" /etc/cloud/cloud.cfg.d/00_defaults.cfg
sed -i -e "s%gecos: EC2 Default User%gecos: ${aws_network_type} admin user%" /etc/cloud/cloud.cfg.d/00_defaults.cfg

# hostname change
sed -i -e "s%HOSTNAME=.*%HOSTNAME=${INSTANCE_NAME}%" /etc/sysconfig/network

# repo update
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion/mongodb/mongodb.repo /etc/yum.repos.d/mongodb.repo

# yum intall jq, mysql, postgresql, OpenLDAP client, sssd, mongodb and redis
yum install -y jq
yum install -y mysql55
yum install -y postgresql96
yum install -y sssd sssd-client sssd-ldap openldap-clients
yum install -y mongodb-org-shell
yum --enablerepo=epel install -y redis

# setting audit logger
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion/audit_logger /usr/local/bin/
chmod +x /usr/local/bin/audit_logger
mkdir /var/log/operation/
chmod 777 /var/log/operation/
chattr -R +a /var/log/operation
echo "" >> /etc/ssh/sshd_config
echo "ForceCommand /usr/local/bin/audit_logger" >> /etc/ssh/sshd_config

/etc/init.d/sshd restart

# set up sssd
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion/sssd.conf /etc/sssd/sssd.conf

sed -i -e "s%#####LDAP_SERVER#####%${LDAP_SERVER}%" /etc/sssd/sssd.conf
sed -i -e "s%#####ROOTDN#####%${ROOTDN}%g" /etc/sssd/sssd.conf
sed -i -e "s%#####ALLOW_GROUP#####%${ACCESS_ALLOW_GROUP}%" /etc/sssd/sssd.conf

chown root:root /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

echo "sudoers:    files sss" >> /etc/nsswitch.conf
echo "# Ldap Login Options" >> /etc/ssh/sshd_config
echo "AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys" >> /etc/ssh/sshd_config
echo "AuthorizedKeysCommandUser root" >> /etc/ssh/sshd_config
sed -i -E "s/^#PubkeyAuthentication yes$/PubkeyAuthentication yes/g" /etc/ssh/sshd_config

authconfig --enablesssd --enablesssdauth --enablelocauthorize --enableldap --enableldapauth --disableldaptls --ldapserver=ldap://${LDAP_SERVER} --ldapbasedn=${ROOTDN} --enablemkhomedir --updateall --nostart

service sssd start
service sshd restart

chkconfig sssd on

# reboot for updating hostname
shutdown -r now
