#!/bin/bash -v
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
sudo yum install -y nagios nagios-plugins-all nagios-plugins-nrpe perl-libwww-perl perl-Crypt-SSLeay perl-LWP-Protocol-https jq
sed -i -e 's/#cfg_dir=\/etc\/nagios\/servers/cfg_dir=\/etc\/nagios\/servers/' /etc/nagios/nagios.cfg
sed -i -e 's/service_check_timeout_state=c/service_check_timeout_state=u/'    /etc/nagios/nagios.cfg
sed -i -e 's/service_check_timeout=60/service_check_timeout=600/'             /etc/nagios/nagios.cfg
mkdir /etc/nagios/servers
htpasswd -cb /etc/nagios/passwd user1 password
htpasswd -b /etc/nagios/passwd user2 password
sed -i -e 's/#authorized_for_read_only=user1,user2/authorized_for_read_only=user2/' /etc/nagios/cgi.cfg
sed -i -e 's/authorized_for_all_services=user1/authorized_for_all_services=user1,user2/' /etc/nagios/cgi.cfg
sed -i -e 's/authorized_for_all_hosts=user1/authorized_for_all_hosts=user1,user2/' /etc/nagios/cgi.cfg

aws s3 cp s3://fugafuga/nagios/slack_nagios.sh /usr/local/bin/slack_nagios.sh
chmod +x /usr/local/bin/slack_nagios.sh
aws s3 cp s3://fugafuga/nagios/objects/contacts.cfg           /etc/nagios/objects/contacts.cfg
aws s3 cp s3://fugafuga/nagios/objects/localhost.cfg          /etc/nagios/objects/localhost.cfg
aws s3 cp s3://fugafuga/nagios/conf.d/slack_nagios_prod.cfg   /etc/nagios/conf.d/slack_nagios.cfg
aws s3 cp s3://fugafuga/nagios/conf.d/additional_commands.cfg /etc/nagios/conf.d/additional_commands.cfg
aws s3 cp s3://fugafuga/nagios/conf.d/aws_cloudwatch.cfg      /etc/nagios/conf.d/aws_cloudwatch.cfg
sed -i -e "s/====REGION====/$REGION/g" /etc/nagios/conf.d/aws_cloudwatch.cfg
aws s3 cp s3://fugafuga/nagios/check_cloudwatch_alarm.sh      /usr/lib64/nagios/plugins/check_cloudwatch_alarm.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_alarm.sh
aws s3 cp s3://fugafuga/nagios/conf.d/aws_cloudwatch_custom.cfg /etc/nagios/conf.d/aws_cloudwatch_custom.cfg
aws s3 cp s3://fugafuga/nagios/check_cloudwatch_alarm_custom.sh /usr/lib64/nagios/plugins/check_cloudwatch_alarm_custom.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_alarm_custom.sh
aws s3 cp s3://fugafuga/nagios/conf.d/aws_cloudwatch_logs_prod.cfg /etc/nagios/conf.d/aws_cloudwatch_logs.cfg
sed -i -e "s/====REGION====/$REGION/g" /etc/nagios/conf.d/aws_cloudwatch_logs.cfg
aws s3 cp s3://fugafuga/nagios/check_cloudwatch_logs_error.sh      /usr/lib64/nagios/plugins/check_cloudwatch_logs_error.sh
chmod +x /usr/lib64/nagios/plugins/check_cloudwatch_logs_error.sh

aws s3 cp s3://fugafuga/nagios/conf.d/check_logfiles.cfg   /etc/nagios/conf.d/check_logfiles.cfg
aws s3 cp s3://fugafuga/nagios/logfiles_alarm_rule.cfg     /etc/nagios/logfiles_alarm_rule.cfg
aws s3 cp s3://fugafuga/nagios/check_logfiles-3.8.1.tar.gz ./check_logfiles-3.8.1.tar.gz
tar xvzf check_logfiles-3.8.1.tar.gz
cd check_logfiles-3.8.1
./configure
make
cp ./plugins-scripts/check_logfiles /usr/lib64/nagios/plugins/
mkdir /etc/nagios/var
chown root.nagios /etc/nagios/var
chmod 774 /etc/nagios/var

curl -L http://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh
aws s3 cp s3://fugafuga/nagios/limits.conf  /etc/security/limits.conf

chkconfig httpd on
chkconfig nagios on

/etc/init.d/httpd start
/etc/init.d/nagios start
