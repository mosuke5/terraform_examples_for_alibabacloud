yum install -y wget epel
yum install -y ansible

systemctl start iptables-services
PostRouting="192.168.1.0/24"
SourceRouting=`ifconfig eth0|grep inet|awk '{print $2}'|tr -d 'addr:'`
echo 'net.ipv4.ip_forward=1'>> /etc/sysctl.conf
sysctl -p
iptables -t nat -I POSTROUTING -s $PostRouting -j SNAT --to-source $SourceRouting

cd /root
wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/master/wordpress_sample/playbook.yml
ansible-playbook playbook.yml
