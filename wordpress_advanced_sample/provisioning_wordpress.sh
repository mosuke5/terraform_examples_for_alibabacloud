yum install -y wget epel
yum install -y ansible
cd /root
wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/master/wordpress_sample/playbook.yml
ansible-playbook playbook.yml
