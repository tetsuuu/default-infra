#!/bin/bash -v
yum update -y

yum -y remove ntp
yum -y install chrony
chkconfig chronyd on
/etc/init.d/chronyd start

# configure logrotate
# enabling log compress (logrotate.conf)
sed -i -e 's/#compress/compress/' /etc/logrotate.conf

aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/fluentd/limits.conf  /etc/security/limits.conf

# get a instance region
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')

# set up td-agent
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/fluentd/td-agent.repo /etc/yum.repos.d/
yum -y install td-agent
td-agent-gem install fluent-plugin-forest
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/fluentd/td-agent /etc/init.d/
sed -i -e 's/###resource-s3-bucket###/${resource_s3_bucket}/g' /etc/init.d/td-agent
sed -i -e 's/###maintnance_service_name###/${maintenance_service_name}/g' /etc/init.d/td-agent
sed -i -e 's/###aws_network_type###/${aws_network_type}/g' /etc/init.d/td-agent
sed -i -e 's/###environment###/${environment}/g' /etc/init.d/td-agent
sed -i -e 's/###region###/${region}/g' /etc/init.d/td-agent
chmod 755 /etc/init.d/td-agent
mkdir -p /etc/td-agent/service.d
mkdir -p /var/lib/td-agent

## add cron of td-agent configuration
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/fluentd/cron.update-td-agent /etc/cron.d/
chown root:root /etc/cron.d/cron.update-td-agent
chmod 644 /etc/cron.d/cron.update-td-agent

chkconfig td-agent on
/etc/init.d/td-agent start
