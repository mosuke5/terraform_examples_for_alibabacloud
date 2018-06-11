# Basic example
This is most basic example. This will create following resources. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit?ts=5b1df94f#slide=id.g3c4891986d_1_0).
1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create an ECS instance in Vswitch
1. Create EIP and bind it to ECS instance
1. Provision httpd to ECS instance with Userdata function

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
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

eip = xx.xx.xx.xx
```

Access eip address with web browser.  
![http_output](/basic_sample/http_output.png)


## Reference(Japanese)
http://qiita.com/mosuke5/items/a65683ce6569bffd7ef0
