#!/bin/bash -v
yum update -y

# configure logrotate
# enabling log compress (logrotate.conf)
sed -i -e 's/#compress/compress/' /etc/logrotate.conf

# get a instance region
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')

# setting up ldap
# install openldap-tools and testing clients
yum install -y openldap-servers openldap-clients openssh-ldap

# Syslog setting
echo "local4.*                          /var/log/slapd.log" >> /etc/rsyslog.conf
/etc/init.d/rsyslog restart

# disable ec2-user
## create default user
useradd --no-user-group --gid root --uid 1000 ${MAINTENANCE_USER} -s /bin/bash -c "${AWS_NETWORK_TYPE} admin user"

## copy authorized_key
mkdir -p /home/${MAINTENANCE_USER}/.ssh
cp -f /home/ec2-user/.ssh/authorized_keys /home/${MAINTENANCE_USER}/.ssh/authorized_keys
chown -R ${MAINTENANCE_USER}:root /home/${MAINTENANCE_USER}/.ssh
chmod 600 /home/${MAINTENANCE_USER}/.ssh/authorized_keys

## enable SUDOERS
cat > /etc/sudoers.d/${MAINTENANCE_USER} << 'EOL'
${MAINTENANCE_USER} ALL=(ALL) NOPASSWD:ALL
EOL

chmod 400 /etc/sudoers.d/${MAINTENANCE_USER}

# disable ec2-user
## disable sudo
sed -i -e "s%ec2-user%#ec2-user%g" /etc/sudoers.d/cloud-init
## delete ec2-user
userdel -r ec2-user
## replace cloud config

sed -i -e "s%name: ec2-user%name: ${MAINTENANCE_USER}%" /etc/cloud/cloud.cfg.d/00_defaults.cfg
sed -i -e "s%gecos: EC2 Default User%gecos: ${AWS_NETWORK_TYPE} admin user%" /etc/cloud/cloud.cfg.d/00_defaults.cfg

# get conf files from s3
cd /tmp
aws s3 cp s3://${RES_S3_BUCKET}/terraform/resource/maintenance/ldap/ . --recursive

# configure slapd.conf
# set rootpw
CRYPTROOTPW=$(slappasswd -h '{SSHA}' << EOS
${ROOTPW}
${ROOTPW}

EOS
)
sed -i -e "s%#####ROOTPW#####%$${CRYPTROOTPW}%" ./slapd-master.conf
sed -i -e "s%#####ROOTDN#####%${ROOTDN}%g" ./slapd-master.conf
sed -i -e "s%#####LDAP_ADMIN_GROUP#####%${LDAP_ADMIN_GROUP}%g" ./slapd-master.conf

mv -f ./slapd-master.conf /etc/openldap/slapd.conf
chown ldap:ldap /etc/openldap/slapd.conf

# get self certs for staging only
tar xvfz ./${STAGE}/certs/ldap_certs.tar.gz -C /etc/openldap/certs

chown root:ldap /etc/openldap/certs/slapd.key
chmod 440 /etc/openldap/certs/slapd.key

# initialize DB
rm -rf /etc/openldap/slapd.d/*
cp -f /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

# copy sudo and openssh-ldap schema
SUDOPATH=$(ls -d /usr/share/doc/sudo-*)
OPENSSHLDAP=$(ls -d /usr/share/doc/openssh-ldap-*)
cp -f $${SUDOPATH}/schema.OpenLDAP /etc/openldap/schema/sudo.schema
cp -f $${OPENSSHLDAP}/openssh-lpk-openldap.schema /etc/openldap/schema/.

# create initial db
chown ldap:ldap -R /var/lib/ldap
chown ldap:ldap -R /etc/openldap/slapd.d

# this command will be occurred error
sudo -u ldap slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d

echo 'SLAPD_OPTIONS="-f /etc/openldap/slapd.conf"' >> /etc/sysconfig/ldap

# start slapd
/etc/init.d/slapd start
chkconfig slapd on

# add base.ldif and user.ldif
ROOTDNDC=$(echo "${ROOTDN}" | awk -F',' '{print $1}' | sed -e 's/dc=//')
ROOTDNO=$(echo "${ROOTDN}" | awk -F',' '{print $1}' | sed -e 's/dc=//')

sed -i -e "s%#####ROOTPW#####%$${CRYPTROOTPW}%g" ./base.ldif
sed -i -e "s%#####ROOTDN#####%${ROOTDN}%g" ./base.ldif
sed -i -e "s/#####LDAP_ADMIN_GROUP#####/${LDAP_ADMIN_GROUP}/g" ./base.ldif
sed -i -e "s/#####ROOTDNDC#####/$${ROOTDNDC}/g" ./base.ldif
sed -i -e "s/#####ROOTDNO#####/$${ROOTDNO}/g" ./base.ldif
sed -i -e "s%#####JENKINSHOST#####%${JENKINS_HOST}%" ./base.ldif

mv -f ./base.ldif /etc/openldap/base.ldif

ldapadd -x -D "cn=Manager,${ROOTDN}" -W -f /etc/openldap/base.ldif << EOS
${ROOTPW}

EOS

# setting up lam
# install add requirement mw
yum -y install libwebp
yum -y install libmcrypt libtool-ltdl libtidy libXpm libtiff gd-last autoconf automake

yum -y install httpd24
yum -y install php70 php70-common php70-opcache php70-devel php70-mbstring php70-mcrypt php70-xml php70-gd php70-fpm php70-ldap php70-zip php70-mhash

sed -i -e 's/;default_charset = "iso-8859-1"/default_charset = "UTF-8"/g' /etc/php.ini
#sed -i -e "s/;mbstring.language = Japanese/mbstring.language = Japanese /g" /etc/php.ini
sed -i -e "s/;mbstring.internal_encoding = EUC-JP/mbstring.internal_encoding = UTF-8/g" /etc/php.ini
#sed -i -e "s/;mbstring.http_input = auto/mbstring.http_input = pass/g" /etc/php.ini
#sed -i -e "s/;mbstring.http_output = SJIS/mbstring.http_output = pass/g" /etc/php.ini
#sed -i -e "s/;mbstring.http_input = auto/mbstring.http_input = pass/g" /etc/php.ini
#sed -i -e "s/;mbstring.encoding_translation = Off/mbstring.encoding_translation = Off/g" /etc/php.ini
#sed -i -e "s/;mbstring.detect_order = auto/mbstring.detect_order = auto/g" /etc/php.ini
#sed -i -e "s/;date.timezone =/date.timezone = Asia\/Tokyo/g" /etc/php.ini
# ServerTokens off
sed -i -e "s/expose_php = On/expose_php= Off/" /etc/php.ini

# install lam package
rpm -ivh ./ldap-account-manager-6.2-0.fedora.1.noarch.rpm

# setup lam config /var/lib/ldap-account-manager/config
# config.cfg
#TODO auto make password
mv -f ./config.cfg /var/lib/ldap-account-manager/config/config.cfg
chown apache:apache /var/lib/ldap-account-manager/config/config.cfg

#TODO auto change password
sed -i -e "s%#####ROOTDN#####%${ROOTDN}%g" ./lam.conf
mv -f ./lam.conf /var/lib/ldap-account-manager/config/lam.conf
chown apache:apache /var/lib/ldap-account-manager/config/lam.conf

# install ltd self-service-password
tar xvfz ./ltb-project-self-service-password-1.2.tar.gz

# setup ssp disable sms, token with mail, use_questions
sed -i -e "s%$$ldap_url = \"ldap://localhost\"%$$ldap_url = \"ldap://localhost:389\"%" ./config.inc.php
sed -i -e "s%$$ldap_binddn = \"cn=manager,dc=example,dc=com\"%$$ldap_binddn = \"cn=Manager,${ROOTDN}\"%" ./config.inc.php
sed -i -e "s%$$ldap_bindpw = \"secret\"%$$ldap_bindpw = \"${ROOTPW}\"%" ./config.inc.php
sed -i -e "s%$$ldap_base = \"dc=example,dc=com\"%$$ldap_base = \"${ROOTDN}\"%" ./config.inc.php

mv -f ./ltb-project-self-service-password-1.2 /usr/share/self-service-password
mv -f ./config.inc.php /usr/share/self-service-password/conf/config.inc.php
mv -f ./ssp.apache.conf /etc/httpd/conf.d/.

# setting httpd
# Port change
sed -i -e "s/Listen 80/Listen 18000/" /etc/httpd/conf/httpd.conf
# Hide apache version from HTTP Server Response Header
echo "ServerTokens ProductOnly" >> /etc/httpd/conf/httpd.conf
echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf
sed -i "s/Options Indexes FollowSymLinks/#Options Indexes FollowSymLinks/g" /etc/httpd/conf/httpd.conf

# delete welcome.conf
rm -f /etc/httpd/conf.d/welcome.conf
# comment: trace information is off by conf.d/notrace.conf

service httpd start
chkconfig httpd on


# setting updating ldif by cron
yum -y install jq
mkdir -p /etc/openldap/current_ldif

# backup.sh
mkdir -p /usr/local/bin

sed -i -e "s/#####ROOTDN#####/${ROOTDN}/" ./ldif-backup.sh
sed -i -e "s/#####CONFIG_S3_BUCKET#####/${CONFIG_S3_BUCKET}/" ./ldif-backup.sh
sed -i -e "s/#####STAGE#####/${STAGE}/" ./ldif-backup.sh

mv -f ./ldif-backup.sh /usr/local/bin/ldif-backup.sh

chmod 700 /usr/local/bin/ldif-backup.sh

# execute update.sh at first time
sed -i -e "s/#####CONFIG_S3_BUCKET#####/${CONFIG_S3_BUCKET}/" ./ldif-update.sh
sed -i -e "s/#####STAGE#####/${STAGE}/" ./ldif-update.sh

mv -f ./ldif-update.sh /usr/local/bin/ldif-update.sh

chmod 700 /usr/local/bin/ldif-update.sh

/usr/local/bin/ldif-update.sh

# cron.d
service crond stop
mv -f ./cron.ldap-backup /etc/cron.d/cron.ldap-backup
chmod 644 /etc/cron.d/cron.ldap-backup
service crond start

# TODO add tg-agent
# TODO add nrpe