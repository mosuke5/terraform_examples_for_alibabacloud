# RDS example
This is the example of creating RDS instance. This will create following resources. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit#slide=id.g3be18e2e38_0_2).

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create an ECS instance in Vswitch
1. Create EIP and bind it to ECS instance
1. Create a RDS instance in Vswitch and create database, db user
1. Set ECS private ip address to RDS white list 

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
It takes a 5-10 minitus to create RDS. You need to wait to finish.
```