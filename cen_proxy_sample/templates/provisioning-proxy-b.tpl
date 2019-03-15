yum update
yum install -y wget
yum install -y ansible
cd /root
useradd ecs-user
echo '${password}' | passwd --stdin ecs-user
mkdir -p /home/ecs-user/.ssh
echo "${publickey}" > /home/ecs-user/.ssh/authorized_keys
chown -R ecs-user:ecs-user /home/ecs-user
chmod 700 /home/ecs-user/.ssh
chmod 400 /home/ecs-user/.ssh/authorized_keys
echo "ecs-user  ALL=(ALL)       ALL" > /etc/sudoers
echo export PROXY_A_IP="${proxy-a-ip}" >> /etc/environment
echo export DEST_DOMAIN="${dest-domain}" >> /etc/environment
source /etc/environment
cd /tmp
ansible-playbook playbook.yml
