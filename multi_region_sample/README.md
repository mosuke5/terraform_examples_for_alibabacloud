# Multi Region Sample
This is the example of controlling multi region resources with using [module](https://www.terraform.io/docs/configuration/modules.html) function.
You can create following resources to Shanghai, Tokyo, Silicon Valley region at the same time.

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create an ECS instance in Vswitch

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