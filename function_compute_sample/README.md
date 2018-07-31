# Function Compute example
This is the basic function compute(FC) example. This will create following resources.
This code create very simple function which output "hello world" every 1 minute.

1. Create LogService Project and Store
1. Create RAM role and policy for FC
1. Create FC service, function, trigger

## How to use
First you need to chnage configuration to yours.
```
$ cp terraform.tfvars.sample terrafrom.tfvars
$ vim terraform.tfvars
 => Edit variables with your favorite editor.
```

Upload sample code to OSS bucket as `function_compute.py.zip`.
```python
import logging

def handler(event, context):
  logger = logging.getLogger()
  logger.info('hello world')
  return 'hello world'
```

Deploy to Alibaba Cloud
```
$ terraform apply
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```
