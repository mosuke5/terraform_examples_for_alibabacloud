#!/bin/bash
useradd -u 1000 -G wheel mongoadmin
mkdir /home/mongoadmin/.ssh && chmod 700 /home/mongoadmin/.ssh
cat > /home/mongoadmin/.ssh/authorized_keys << EOF
<<<< MONGOADMIN PUBLICKEY >>>>
EOF
cat > /home/mongoadmin/.ssh/id_rsa << EOF
<<<< MONGOADMIN PRIVATEKEY >>>>
EOF
chmod 600 /home/mongoadmin/.ssh/authorized_keys
chmod 600 /home/mongoadmin/.ssh/id_rsa
chown -R mongoadmin. /home/mongoadmin/.ssh
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
cat > /etc/sysctl.d/ipv4-forward.conf <<< EOF
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.conf
systemctl start firewalld
firewall-cmd --set-default-zone external
firewall-cmd --zone=external --add-interfce=eth0 --permanent
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eth0 -j MASQUERADE -s 10.0.0.0/16