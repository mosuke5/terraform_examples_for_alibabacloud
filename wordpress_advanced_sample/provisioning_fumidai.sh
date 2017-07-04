yum install -y wget epel
yum install -y ansible

yum install -y iptables-services
systemctl start iptables
systemctl enable iptables
PostRouting="192.168.1.0/24"
SourceRouting=`ifconfig eth0|grep inet|awk '{print $2}'|tr -d 'addr:'`
echo 'net.ipv4.ip_forward=1'>> /etc/sysctl.conf
sysctl -p
iptables -t nat -I POSTROUTING -s $PostRouting -j SNAT --to-source $SourceRouting
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited
iptables -A FORWARD -s $PostRouting -j ACCEPT
iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited
iptables-save > /etc/sysconfig/iptables

cd /root
wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/master/wordpress_sample/playbook.yml
ansible-playbook playbook.yml
