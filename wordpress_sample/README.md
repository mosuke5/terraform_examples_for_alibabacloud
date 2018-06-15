# WordPress example
This is the example of building wordpress with ECS and RDS. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit?ts=5b1df94f#slide=id.g3bf33c5b60_0_25).

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create an ECS instance in Vswitch
1. Create EIP and bind it to ECS instance
1. Create a RDS instance in Vswitch and create database, db user
1. Set ECS private ip address to RDS white list 

## How to use
You can build wordpress by following process. But if you want to operate wordpress in production, you need to configure more.

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
