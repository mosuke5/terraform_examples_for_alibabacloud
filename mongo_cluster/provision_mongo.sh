#!/bin/bash
useradd -u 1000 -G wheel mongoadmin
mkdir /home/mongoadmin/.ssh && chmod 700 /home/mongoadmin/.ssh
cat > /home/mongoadmin/.ssh/authorized_keys << EOF
<<<< MONGOADMIN PUBLICKEY >>>>
EOF
chmod 600 /home/mongoadmin/.ssh/authorized_keys
chown -R mongoadmin. /home/mongoadmin/.ssh
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
cat > /etc/yum.repos.d/mongo-org-3.4.repo << EOF
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF
yum makecache
yum install -y mongodb-org