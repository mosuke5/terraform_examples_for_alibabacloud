yum install -y wget epel
yum install -y ansible
cd /root
wget https://raw.githubusercontent.com/mosuke5/terraform_examples_for_alibabacloud/master/wordpress_advanced_sample/playbook_bastion.yml -O playbook.yml
ansible-playbook playbook.yml
