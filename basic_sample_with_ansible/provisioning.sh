#!/bin/bash
yum install -y wget epel
yum install -y ansible
wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/add/ansible-basic-sample/basic_sample_with_ansible/playbook.yml
ansible-playbook playbook.yml
