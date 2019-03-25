# Involiking terraform from ansible
This is most basic sample about invoking terraform from ansible. This will create following resources. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit#slide=id.g5512275ccb_2_0).
1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create 3 ECS instances in Vswitch
1. Provision httpd to these with ansible

## How to use
First you need to chnage configuration to yours and install ansible.
```
$ brew install ansible
$ cd terraform
$ cp terraform.tfvars.sample terrafrom.tfvars
$ vim terraform.tfvars
 => Edit variables with your favorite editor.
```

Deploy to Alibaba Cloud
```
$ ansible-playbook -i ./inventry.sh -u root
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

eip = xx.xx.xx.xx
```

## Reference
- [terraform – Manages a Terraform deployment (and plans)](https://docs.ansible.com/ansible/latest/modules/terraform_module.html)
- [HASHICORP TERRAFORM AND RED HAT ANSIBLE AUTOMATION](https://www.redhat.com/cms/managed-files/pa-terraform-and-ansible-overview-f14774wg-201811-en.pdf)
