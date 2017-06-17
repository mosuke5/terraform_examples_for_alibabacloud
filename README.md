# Alibaba CloudのTerraformサンプル集
## はじめに
- 本レポジトリは[Alibaba Cloud](https://jp.aliyun.com)で利用できるTerraformのサンプル集です。
- Alibaba Cloudでは公式のTerraformの他に、Alibaba社が開発する独自のTerraformレポジトリがありますが、このサンプル集では公式Terraformを利用することを前提としています。
- `terraform.tfbars`をお使いの環境の設定に変更することで基本的に動作可能です
- もしうまく動作しないや、ご要望あればIssueないしはPull requestしてください。

## 実行方法
基本的に下記の方法で実行可能です。
```
// 事前準備
$ cd baisc_sample // 実行したいサンプルへ移動
$ cp terraform.tfvars.sample terraform.tfvars
$ vim terraform.tfvars // API KEYなど必要情報更新

// Dry-Run
$ terraform plan -var-file="terraform.tfvars"

// クラウドへ反映
$ terraform apply -var-file="terraform.tfvars"

// 反映をデバッグログ残して実行したい
$ TF_LOG=TRACE TF_LOG_PATH=./terraform.log terraform apply -var-file="terraform.tfvars"

// 環境削除
$ terraform destroy -var-file="terraform.tfvars"
```

## basic_sample
VPCネットワーク内にECSインスタンスを作成し、作成したECSインスタンスに対し、EIPとセキュリティグループの設定をする基本サンプル。
また、ユーザデータ機能を利用して稼働させるインスタンスには`httpd`をインストール起動している。

![basic_sample](image/architecture_basic_sample.png)

## basic_sample_with_ansible
basic_sampleと構成は同様。
basic_sampleはユーザデータ機能でシェルスクリプトを用いてhttpdのインストールや起動を行っていた。
この例では、ユーザデータ機能でAnsibleを実行させてhttpdのインストールや起動を実施。
これにより、シェルスクリプトでは表現しづらい複雑な設定などに対応が可能になる。

## slb_sample
SLBを使った構成のサンプル。
VPC内のWebサーバは、踏み台サーバを経由してインターネットに接続できるようにVRouterへのルーティング設定も行う。

![slb_sample](image/architecture_slb_sample.png)

## rds_sample
RDSを使った構成のサンプル。
VPC内にWebサーバとRDSを構築。RDSへはWebサーバからのみアクセスできるようにホワイトリスト設定は。

![rds_sample](image/architecture_rds_sample.png)

## autoscaling_sample
AutoScalingを使った構成のサンプル。
SLB配下のECSはAutoScalingにて作成。12-14時の間だけスケールする例を構築。
![autoscaling_sample](image/architecture_autoscaling_sample.png)

## MongoDBクラスタを追加
マルチゾーンをわたるMongoDBクラスタを構築サンプル
![mongo](image/architecture_mongo_cluster.png)

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
