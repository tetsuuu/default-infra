#!/bin/bash -v
yum update -y

# install ruby21 and other resources for serverspec
yum install -y git docker java-1.8.0-openjdk.x86_64 jq mysql ruby22 ruby22-devel gcc-c++ zlib-devel
sudo update-alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

# remove ruby20 series(vim cannot use caused by removing ruby20)
yum remove -y ruby ruby20 ruby20-libs

# install ansible stable-2.5 for ec2 module and boto3
pip install git+https://github.com/ansible/ansible.git@stable-2.5
pip install boto3

# install gems for serverspecs
gem install rake serverspec rspec rspec_junit_formatter io-console builder highline nokogiri

chkconfig docker on

usermod -a -G docker ec2-user

/etc/init.d/docker start
