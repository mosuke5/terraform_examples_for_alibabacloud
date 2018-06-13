# SLB example
This is the example of creating SLB/ECS, and binding ECS to SLB. This will create following resources. Architecture overview is [here](https://docs.google.com/presentation/d/1pqtbiJRGc3uUm8ulhMBf4SWm2WPCCrhgUInjm9DMYdc/edit?ts=5b1df94f#slide=id.g3c58d8ce02_0_5).

1. Create VPC
1. Create Vswitch
1. Create Security Group and set some rules
1. Create two ECS instances in Vswitch
    - Httpd and index.html including hostname will be provisioned
1. Create EIP and bind it to ECS instance
1. Create SLB instance
1. Configure listener and binding to ECS instances

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
...
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

slb = xx.xx.xx.xx
```

Please access slb ip address many times by web browser.
You will find change html output.
