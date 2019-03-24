#!/bin/bash -v
yum update -y

aws s3 cp s3://fugafuga/mongodb/mongodb.repo /etc/yum.repos.d/mongodb.repo
yum install -y mongo-10gen
yum --enablerepo=epel install -y redis

aws s3 cp s3://hogehoge/bastion/audit_logger /usr/local/bin/audit_logger
chmod +x /usr/local/bin/audit_logger
mkdir /var/log/operation/
chmod 777 /var/log/operation/
chattr -R +a /var/log/operation
echo "" >> /etc/ssh/sshd_config
echo "ForceCommand /usr/local/bin/audit_logger" >> /etc/ssh/sshd_config

/etc/init.d/sshd restart
