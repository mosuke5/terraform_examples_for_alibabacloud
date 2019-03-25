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
PLAY [127.0.0.1] **********************************************************************************

TASK [Gathering Facts] ****************************************************************************
ok: [127.0.0.1]

TASK [Exec terraform scripts] *********************************************************************
changed: [127.0.0.1]

TASK [Wait for port 22 to open] *******************************************************************
ok: [127.0.0.1] => (item=161.117.3.12)
ok: [127.0.0.1] => (item=47.74.216.15)
ok: [127.0.0.1] => (item=47.74.217.96)

PLAY [Provisioning to instances] ******************************************************************

TASK [Gathering Facts] ****************************************************************************
ok: [47.74.216.15]
ok: [47.74.217.96]
ok: [161.117.3.12]

TASK [be sure httpd is installed] *****************************************************************
changed: [161.117.3.12]
changed: [47.74.216.15]
changed: [47.74.217.96]

TASK [be sure httpd is running and enabled] *******************************************************
changed: [47.74.217.96]
changed: [47.74.216.15]
changed: [161.117.3.12]

PLAY RECAP ****************************************************************************************
127.0.0.1                  : ok=3    changed=1    unreachable=0    failed=0
161.117.3.12               : ok=3    changed=2    unreachable=0    failed=0
47.74.216.15               : ok=3    changed=2    unreachable=0    failed=0
47.74.217.96               : ok=3    changed=2    unreachable=0    failed=0
```

## Reference
- [terraform – Manages a Terraform deployment (and plans)](https://docs.ansible.com/ansible/latest/modules/terraform_module.html)
- [HASHICORP TERRAFORM AND RED HAT ANSIBLE AUTOMATION](https://www.redhat.com/cms/managed-files/pa-terraform-and-ansible-overview-f14774wg-201811-en.pdf)
