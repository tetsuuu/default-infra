#!/bin/bash -v

yum update -y

/etc/init.d/crond stop

# set up nagios
yum install -y nagios nagios-plugins-all nrpe nagios-plugins-nrpe perl-libwww-perl perl-Crypt-SSLeay perl-LWP-Protocol-https jq
sed -i -e 's|#cfg_dir=/etc/nagios/servers|cfg_dir=/etc/nagios/service.d|g' /etc/nagios/nagios.cfg
sed -i -e 's|service_check_timeout_state=c|service_check_timeout_state=u|g' /etc/nagios/nagios.cfg
sed -i -e 's|service_check_timeout=60|service_check_timeout=600|g' /etc/nagios/nagios.cfg
sed -i -e 's|execute_service_checks=1|execute_service_checks=0|g' /etc/nagios/nagios.cfg
sed -i -e 's|enable_notifications=1|enable_notifications=0|g' /etc/nagios/nagios.cfg
mkdir /etc/nagios/service.d
mkdir /etc/nagios/command
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/${aws_network_type}/${environment}/${region}/service.d/ /etc/nagios/service.d/ --recursive
htpasswd -cb /etc/nagios/passwd nagiosadmin ${nagiosadmin_pw}
htpasswd -b /etc/nagios/passwd dxc-support ${dxc-support_pw}
sed -i -e 's|#authorized_for_read_only=user1,user2|authorized_for_read_only=dxc-support|' /etc/nagios/cgi.cfg
sed -i -e 's|authorized_for_all_services=nagiosadmin|authorized_for_all_services=nagiosadmin,dxc-support|' /etc/nagios/cgi.cfg
sed -i -e 's|authorized_for_all_hosts=nagiosadmin|authorized_for_all_hosts=nagiosadmin,dxc-support|' /etc/nagios/cgi.cfg
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/limits.conf  /etc/security/limits.conf
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/objects/ /etc/nagios/objects/ --recursive
sed -i -e "s|###local_host_name###|${aws_network_type}-${environment}-${region}|g" /etc/nagios/objects/localhost.cfg
sed -i -e "s|###nagiosadmin_pw###|${nagiosadmin_pw}|g" /etc/nagios/objects/localhost.cfg
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/conf.d/ /etc/nagios/conf.d/ --recursive
sed -i -e "s|===slack_ch===|${slack_alert_ch}|g" /etc/nagios/conf.d/slack_nagios.cfg
sed -i -e "s|###region###|${region}|g" /etc/nagios/conf.d/aws_cloudwatch.cfg
sed -i -e "s|###region###|${region}|g" /etc/nagios/conf.d/aws_cloudwatch_logs.cfg
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/${aws_network_type}/${environment}/${region}/conf.d/contacts_service.cfg /etc/nagios/conf.d/
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/check_cloudwatch_alarm.sh /usr/lib64/nagios/plugins/check_cloudwatch_alarm.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_alarm.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/check_cloudwatch_alarm_custom.sh /usr/lib64/nagios/plugins/check_cloudwatch_alarm_custom.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_alarm_custom.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/check_cloudwatch_logs_error.sh /usr/lib64/nagios/plugins/check_cloudwatch_logs_error.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_logs_error.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/check_ecs_task_count.sh /usr/lib64/nagios/plugins/check_ecs_task_count.sh
chmod +x /usr/lib64/nagios/plugins/check_ecs_task_count.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/cloudwatch_describe_alarms.sh /usr/lib64/nagios/plugins/cloudwatch_describe_alarms.sh
chmod +x /usr/lib64/nagios/plugins/cloudwatch_describe_alarms.sh
mkdir -p /tmp/cloudwatch_alarms
chmod 777 /tmp/cloudwatch_alarms

# slack notification
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/${aws_network_type}/${environment}/${region}/conf.d/slack_nagios.sh /usr/local/bin/slack_nagios.sh
chmod +x /usr/local/bin/slack_nagios.sh
sed -i -e "s|===slack_ch===|${slack_alert_ch}|g" /usr/local/bin/slack_nagios.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/slack_nagios.pl /usr/local/bin/slack_nagios.pl
chmod +x /usr/local/bin/slack_nagios.pl

# check_logfiles
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/check_logfiles-3.8.1.tar.gz ./check_logfiles-3.8.1.tar.gz
tar xvzf check_logfiles-3.8.1.tar.gz
cd check_logfiles-3.8.1
./configure
make
cp ./plugins-scripts/check_logfiles /usr/lib64/nagios/plugins/
mkdir /etc/nagios/var
chown root.nagios /etc/nagios/var
chmod 774 /etc/nagios/var

# set up td-agent
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/td-agent.repo /etc/yum.repos.d/
yum -y install td-agent
td-agent-gem install fluent-plugin-forest
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/td-agent /etc/init.d/
sed -i -e 's/###resource-s3-bucket###/${resource_s3_bucket}/' /etc/init.d/td-agent
sed -i -e 's/###aws_network_type###/${aws_network_type}/' /etc/init.d/td-agent
sed -i -e 's/###environment###/${environment}/' /etc/init.d/td-agent
sed -i -e 's/###region###/${region}/' /etc/init.d/td-agent
chmod 755 /etc/init.d/td-agent
mkdir -p /etc/td-agent/service.d
mkdir -p /var/lib/td-agent
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/logfile_purge.sh /var/lib/td-agent/
chown td-agent:td-agent /var/lib/td-agent/logfile_purge.sh
chmod 744 /var/lib/td-agent/logfile_purge.sh
echo "0 */3 * * * /var/lib/td-agent/logfile_purge.sh" > /var/spool/cron/td-agent
chmod 600 /var/spool/cron/td-agent
chown td-agent:td-agent /var/spool/cron/td-agent
sed -i -e 's/rotate 30/rotate 3/g' /etc/logrotate.d/td-agent
chkconfig td-agent on

# set up nagios master check script
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/nagios_master_check.sh /usr/lib64/nagios/nagios_master_check.sh
sed -i -e "s|###region###|${region}|g" /usr/lib64/nagios/nagios_master_check.sh
sed -i -e "s|###nagios_host_no###|${nagios_host_no}|g" /usr/lib64/nagios/nagios_master_check.sh
chmod 744 /usr/lib64/nagios/nagios_master_check.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/cron.master-check /etc/cron.d/
chown root:root /etc/cron.d/cron.master-check
chmod 644 /etc/cron.d/cron.master-check

# set up config import script
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/config_sync.sh /usr/lib64/nagios/config_sync.sh
sed -i -e "s|###resource_s3_bucket###|${resource_s3_bucket}|g" /usr/lib64/nagios/config_sync.sh
sed -i -e "s|###environment###|${environment}|g" /usr/lib64/nagios/config_sync.sh
sed -i -e "s|###aws_network_type###|${aws_network_type}|g" /usr/lib64/nagios/config_sync.sh
sed -i -e "s|###region###|${region}|g" /usr/lib64/nagios/config_sync.sh
chmod 744 /usr/lib64/nagios/config_sync.sh
/usr/lib64/nagios/config_sync.sh
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/cron.update-nagios /etc/cron.d/
chown root:root /etc/cron.d/cron.update-nagios
chmod 644 /etc/cron.d/cron.update-nagios

# delete welcome.conf
rm -f /etc/httpd/conf.d/welcome.conf

# set up nrpe
aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nagios-n/nrpe.cfg /etc/nagios/nrpe.cfg
sed -i -e "s|nrpe_user=nrpe|nrpe_user=nagios|g" /etc/nagios/nrpe.cfg
sed -i -e "s|nrpe_group=nrpe|nrpe_group=nagios|g" /etc/nagios/nrpe.cfg
/etc/init.d/nrpe start

# nagios master check
/usr/lib64/nagios/plugins/check_nrpe -H nagios-n-${nagios_host_no}.${region}.maintenance -c check_nagios
CHKNAGIOS=$?
if [ $CHKNAGIOS != 0 ];then
  /etc/init.d/httpd start
  /etc/init.d/td-agent start
  /etc/init.d/nagios start
#  echo "[$(date +%s)] START_EXECUTING_SVC_CHECKS" > /var/spool/nagios/cmd/nagios.cmd
  echo "[$(date +%s)] ENABLE_NOTIFICATIONS" > /var/spool/nagios/cmd/nagios.cmd
else
  /etc/init.d/nagios start
  echo "[$(date +%s)] ENABLE_HOST_SVC_CHECKS;nagios-n-${nagios_host_no}" > /var/spool/nagios/cmd/nagios.cmd
fi

/etc/init.d/crond start
