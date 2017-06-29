# マルチゾーンをわたるMongoDBクラスタを構築サンプル
![mongo](/image/architecture_mongo_cluster.png)

このサンプルを実行するためには、各ゾーンのサブネット (vswitch作成)CIDRの設定とmongoインスタンススペックの設定
が必要です。そして、システムを管理するために、`mongoadmin`ユーザーが作成されます。`mongoadmin`ユーザーへログイン
するためには、各プロビジョンスクリプト (`provision_mongo.sh`及び`provision_snat.sh`)に、`mongoadmin`ユーザーの
公開鍵と秘密鍵を設定する必要があります。

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
