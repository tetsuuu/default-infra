#!/bin/bash -v
yum update -y

yum -y install java-1.8.0-openjdk-devel
yum -y remove java-1.7.0-openjdk.x86_64

aws s3 cp s3://${resource_s3_bucket}/terraform/resource/maintenance/nexus/nexus-2.14.5-02-bundle.tar.gz /usr/local/nexus-2.14.5-02-bundle.tar.gz
cd /usr/local
tar -xvzf nexus-2.14.5-02-bundle.tar.gz

NEXUSPATH=$(ls -d /usr/local/nexus-* | grep -v *.tar.gz)

ln -s $${NEXUSPATH} nexus

# nexus user needs /home/bash as shells
useradd -m nexus
chown -R nexus:nexus $${NEXUSPATH}
chown -R nexus:nexus /usr/local/sonatype-work

mkdir -p -m 755 /var/run/nexus
chown nexus:nexus /var/run/nexus

sed -i -e '2s/^/export NEXUS_HOME=\/usr\/local\/nexus\n/' /usr/local/nexus/bin/nexus
sed -i -e 's/NEXUS_HOME=".."/NEXUS_HOME="\/usr\/local\/nexus"/' /usr/local/nexus/bin/nexus
sed -i -e 's/#RUN_AS_USER=/RUN_AS_USER="nexus"/' /usr/local/nexus/bin/nexus
sed -i -e 's/#PIDDIR="."/PIDDIR="\/var\/run\/nexus"/' /usr/local/nexus/bin/nexus

cp /usr/local/nexus/bin/nexus /etc/init.d/nexus
chmod 755 /etc/init.d/nexus
chkconfig --add /etc/init.d/nexus
chkconfig --level 345 nexus on
service nexus start
