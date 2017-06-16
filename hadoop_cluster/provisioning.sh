#!/bin/bash
cd /etc/yum.repos.d/
wget http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
yum install -y cloudera-manager-server jdk
yum install -y cloudera-manager-server-db-2
systemctl start cloudera-scm-server-db
systemctl start cloudera-scm-server