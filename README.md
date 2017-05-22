# Alibaba CloudのTerraformサンプル集
## basic_sample
VPCネットワーク内にECSインスタンスを作成し、作成したECSインスタンスに対し、EIPとセキュリティグループの設定をする基本サンプル。

![basic_sample](image/architecture_basic_sample.png)

## slb_sample
SLBを使った構成のサンプル。
VPC内のWebサーバは、踏み台サーバを経由してインターネットに接続できるようにVRouterへのルーティング設定も行う。

![slb_sample](image/architecture_slb_sample.png)

## rds_sample
RDSを使った構成のサンプル。
VPC内にWebサーバとRDSを構築。RDSへはWebサーバからのみアクセスできるようにホワイトリスト設定は。

![rds_sample](image/architecture_rds_sample.png)

## autoscaling_sample
Comming Soon
