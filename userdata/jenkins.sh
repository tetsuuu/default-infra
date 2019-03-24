#!/bin/bash -v
yum update -y
yum install -y git docker java-1.8.0-openjdk.x86_64
sudo update-alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins

chkconfig docker on
chkconfig jenkins on

usermod -a -G docker jenkins
/etc/init.d/docker start
/etc/init.d/jenkins start
