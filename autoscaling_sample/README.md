# AutoScaling example
This is the example of AutoScaling. This will create following resources.

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create SLB instance
1. Create Scaling Group, binding SLB
1. Create Scaling Configuration, launch ubuntu machine 
1. Create Scaling Rules, scale in/out

## How to use
First you need to chnage configuration to yours.
```
$ cp terraform.tfvars.sample terrafrom.tfvars
$ vim terraform.tfvars
 => Edit variables with your favorite editor.
```

Deploy to Alibaba Cloud
```
$ terraform apply
```
