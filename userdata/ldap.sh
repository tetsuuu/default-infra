#!/bin/bash -v
yum update -y
yum install -y openldap-servers openldap-clients openssh-ldap
rm -rf /etc/openldap/slapd.d/*
cp -f /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
slaptest -f /etc/openldap/initldap.conf -F /etc/openldap/slapd.d
chown ldap.ldap -R /var/lib/ldap
chown ldap.ldap -R /etc/openldap/slapd.d
