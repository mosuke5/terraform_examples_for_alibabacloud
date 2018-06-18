# Advanced WordPress Example
This is the example of building high available wordpress with SLB and ECS, RDS and so on. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit?ts=5b1df94f#slide=id.g3bf33c5b60_0_77).

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create two ECS instances for wordpress application in Vswitch
1. Create one ECS instance for bastion server in Vswitch
1. Create EIP and bind it to bastion ECS instance
1. Create NAT Gateway and add it to route table of VRouter
1. Create a RDS instance in Vswitch and create database, db user
1. Set ECS private ip address to RDS white list 

## How to use
You can build wordpress by following process. But if you want to operate wordpress in production environment, you need to configure more.

```
$ cp terraform.tfvars.sample terraform.tfvars
$ vim terraform.tfvars 
  => Edit variables with your favorite editor.

// Deploy to Alibaba Cloud
$ terraform apply
...
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:
rds_connection_string = xxxxxxxxx.rds.aliyuncs.com
wordpress_eip = xx.xx.xx.xx
```

```
// Connect to ECS instance with ssh
$ ssh ecs-user@xx.xx.xx.xx

// Configure wordpress
$ cd /var/www/html/wordpress
$ sudo cp wp-config-sample.php wp-config.php
$ sudo vim wp-config.php
define('DB_NAME', 'database_name_here');
define('DB_USER', 'username_here');
define('DB_PASSWORD', 'password_here');
define('DB_HOST', 'localhost');
```

After deploy and configuration to `wp-config.php`, let's access to your eip address.
You will find wordpress installation screen.

`http://<your eip address>/wordpress`

## Provisioning to ECS
ECS will be provisioned for following settings by Ansible.

- Install Apache
- Install PHP
- Deploy WordPress source code
- Create `ecs-user`
  - Add `ecs-user` to sudoers
  - Add your public key to `/home/ecs-user/.ssh/authorized_keys`
- Disable password authentication and root account login
