#!/bin/bash -v
yum update -y
yum install -y git docker java-1.8.0-openjdk.x86_64 jq mysql postgresql96
sudo update-alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

aws s3 cp s3://fugafuga/mongodb/mongodb.repo /etc/yum.repos.d/mongodb.repo
yum -y install mongodb-org

chkconfig docker on

usermod -a -G docker jenkins
usermod -a -G docker ec2-user
/etc/init.d/docker start
