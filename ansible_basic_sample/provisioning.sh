#!/bin/bash
yum install -y wget epel
yum install -y ansible
wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/add/ansible-basic-sample/ansible_basic_sample/playbook.yml
ansible-playbook playbook.yml
