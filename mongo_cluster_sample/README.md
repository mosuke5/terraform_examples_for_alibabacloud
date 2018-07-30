# MongoDB cluster example 
This is the repository to build multi-az MongoDb cluster.

![mongo](/image/architecture_mongo_cluster.png)

You need to configure subnet(vswitch) and CIDR, mongodb instance spec.
Provisioning scripts(`provision_mongo.sh` and `provision_snat.sh`) will provision `mongoadmin` user. In order to manage MongoDB, you can login as `mongodadmin` user. So, you need to configure your publickey and privatekey to `terraform.tfvars`.

Following is example of `terraform.tfvars`.
```
secret_key = ""
access_key = ""
region = "cn-shenzhen"
zones = ["cn-shenzhen-a", "cn-shenzhen-b", "cn-shenzhen-b"]
mongo_instances = ["ecs.n1.small","ecs.n1.small","ecs.n1.small"]
os_image = "centos_7_3_64_40G_base_20170322.vhd"
outbound_cidr = "0.0.0.0/0"
vpc_cidr = "10.0.0.0/16"
natgw_cidr = "10.0.128.0/20"
mongo_primary_cidr = "10.0.0.0/19"
mongo_secondary0_cidr = "10.0.32.0/19"
mongo_secondary1_cidr = "10.0.64.0/19"
```