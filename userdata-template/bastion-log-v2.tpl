#!/bin/bash -v
yum update -y

# Add td-agent user and group with fixed uid/gid avoid conflict with nrpe
groupadd --gid 496 td-agent
useradd --no-user-group --uid 497 --gid 496 td-agent -d /var/lib/td-agent -s /bin/nologin -c td-agent

# Add nrpe before removing ntp
yum -y install nagios nagios-plugins-all nrpe nagios-plugins-nrpe perl-Switch perl-DateTime perl-Sys-Syslog perl-libwww-perl perl-Crypt-SSLeay perl-LWP-Protocol-https
curl "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=4174&cf_id=24" -o /usr/lib64/nagios/plugins/check_mem
chmod +x /usr/lib64/nagios/plugins/check_mem
cat > /etc/nagios/nrpe.cfg << 'EOL'
log_facility=daemon
pid_file=/var/run/nrpe/nrpe.pid
server_port=5666
nrpe_user=nrpe
nrpe_group=nrpe
allowed_hosts=127.0.0.1,=====CIDR_BLOCK=====
dont_blame_nrpe=1
allow_bash_command_substitution=0
debug=0
command_timeout=60
connection_timeout=300
include_dir=/etc/nrpe.d/

command[check_nagios]=/usr/lib64/nagios/plugins/check_nagios -e 5 -F /var/log/nagios/status.dat -C /usr/sbin/nagios
command[check_mem]=/usr/lib64/nagios/plugins/check_mem -w 80 -c 90
command[check_swap]=/usr/lib64/nagios/plugins/check_swap -w 40% -c 20%
command[check_disk_/]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[iNode]=/usr/lib64/nagios/plugins/check_disk -W 20% -K 10% -p /
command[check_disk_/log]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /log
command[iNode_/log]=/usr/lib64/nagios/plugins/check_disk -W 20% -K 10% -p /log

command[check_load]=/usr/lib64/nagios/plugins/check_load -w 99,2,99 -c 99,3,99

command[check_procs_sshd]=/usr/lib64/nagios/plugins/check_procs -c 1: -a "/usr/sbin/sshd"
command[check_procs_crond]=/usr/lib64/nagios/plugins/check_procs -c 1: -a "crond"
command[check_procs_rsyslogd]=/usr/lib64/nagios/plugins/check_procs -c 1: -a "/sbin/rsyslogd"
command[check_procs_chronyd]=/usr/lib64/nagios/plugins/check_procs -c 1: -a "chronyd"
command[check_procs_fluentd]=/usr/lib64/nagios/plugins/check_procs -c 1: -a "td-agent"
EOL

sed -i -e "s|=====CIDR_BLOCK=====|${MAINTENANCE_CIDR}|" /etc/nagios/nrpe.cfg

chkconfig nrpe on
/etc/init.d/nrpe start

# instoll chrony
yum -y remove ntp
yum -y install chrony jq
chkconfig chronyd on
/etc/init.d/chronyd start

curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip -d /opt/
rm -rf CloudWatchMonitoringScripts-1.2.2.zip

# TODO Delete; Postgresql is temporary
if [ ${environment} = staging ]; then
yum -y install postgresql96
fi

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

# set up td-agent
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/td-agent.repo /etc/yum.repos.d/
yum -y install td-agent
td-agent-gem install fluent-plugin-forest
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/td-agent /etc/init.d/
sed -i -e 's/###resource-s3-bucket###/${resource_s3_bucket}/' /etc/init.d/td-agent
sed -i -e 's/###aws_network_type###/${aws_network_type}/' /etc/init.d/td-agent
sed -i -e 's/###environment###/${environment}/' /etc/init.d/td-agent
sed -i -e 's/###region###/${region}/' /etc/init.d/td-agent
chmod 755 /etc/init.d/td-agent
mkdir -p /etc/td-agent/service.d
mkdir -p /var/lib/td-agent
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/logfile_purge.sh /var/lib/td-agent/
chown td-agent:td-agent /var/lib/td-agent/logfile_purge.sh
chmod 744 /var/lib/td-agent/logfile_purge.sh
echo "0 20 * * * /var/lib/td-agent/logfile_purge.sh" > /var/spool/cron/td-agent
chmod 600 /var/spool/cron/td-agent
chown td-agent:td-agent /var/spool/cron/td-agent
sed -i -e 's/rotate 30/rotate 3/g' /etc/logrotate.d/td-agent
/etc/init.d/crond restart
chkconfig td-agent on
## add cron of td-agent configuration
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/cron.update-td-agent /etc/cron.d/
chown root:root /etc/cron.d/cron.update-td-agent
chmod 644 /etc/cron.d/cron.update-td-agent

# bastion
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/audit_logger /usr/local/bin/
chmod +x /usr/local/bin/audit_logger
mkdir /var/log/operation/
chmod 777 /var/log/operation/
chattr -R +a /var/log/operation
echo "" >> /etc/ssh/sshd_config
echo "ForceCommand /usr/local/bin/audit_logger" >> /etc/ssh/sshd_config

# yum intall OpenLDAP client, sssd
yum -y install sssd sssd-client sssd-ldap openldap-clients

# set up sssd
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/sssd.conf /etc/sssd/sssd.conf
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
chkconfig sssd on
service sssd start

# create log directory
mkdir /log
## check format status
FSTYPE=$(blkid /dev/xvdb | awk ' { print $3 } ')
if [ -z "$${FSTYPE}" ]; then
  mkfs -t ext4 /dev/xvdb
  mount /dev/xvdb /log
  echo "/dev/xvdb /log ext4 defaults 1 1" >> /etc/fstab
  chmod 777 /log
  mkdir -p /log/default
  chown td-agent:default-user /log/default
  chmod 750 /log/default
else
  mount /dev/xvdb /log
  echo "/dev/xvdb /log ext4 defaults 1 1" >> /etc/fstab
  chmod 777 /log
  chown td-agent:default-user /log/default
  chmod 750 /log/default
fi
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/bastion-log/create_log_dir.sh /var/lib/td-agent/
ROOTPW=$(printf %q "${ROOTPW}")
sed -i -e "s/###LDAP_ROOTDN###/${ROOTDN}/g" /var/lib/td-agent/create_log_dir.sh
sed -i -e "s/###LDAP_ROOTPW###/$${ROOTPW}/g" /var/lib/td-agent/create_log_dir.sh
chmod 744 /var/lib/td-agent/create_log_dir.sh

# reboot for updating hostname
shutdown -r now
