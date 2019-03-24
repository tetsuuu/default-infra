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
sed -i -e "s%#####ROOTPW#####%$${CRYPTROOTPW}%" ./slapd-slave.conf
sed -i -e "s%#####ROOTDN#####%${ROOTDN}%g" ./slapd-slave.conf
sed -i -e "s%#####LDAP_ADMIN_GROUP#####%${LDAP_ADMIN_GROUP}%g" ./slapd-slave.conf

mv -f  ./slapd-slave.conf /etc/openldap/slapd.conf
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

mv -f  ./base.ldif /etc/openldap/base.ldif

ldapadd -x -D "cn=Manager,${ROOTDN}" -W -f /etc/openldap/base.ldif << EOS
${ROOTPW}

EOS

# setting updating ldif by cron
# update.sh
yum -y install jq
mkdir -p /etc/openldap/current_ldif

mkdir -p /usr/local/bin

sed -i -e "s/#####CONFIG_S3_BUCKET#####/${CONFIG_S3_BUCKET}/" ./ldif-update.sh
sed -i -e "s/#####STAGE#####/${STAGE}/" ./ldif-update.sh

mv -f  ./ldif-update.sh /usr/local/bin/ldif-update.sh

chmod 700 /usr/local/bin/ldif-update.sh

# startup update
/usr/local/bin/ldif-update.sh

# cron.d
service crond stop
mv -f  ./cron.ldap-update /etc/cron.d/cron.ldap-update
chmod 644 /etc/cron.d/cron.ldap-update
service crond start

# TODO add tg-agent
# TODO add nrpe