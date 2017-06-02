/*
 * API KEYはとても重要なデータです。
 * terraform本体のファイルには記述せず、
 * 変数ファイル(sample.tfvars)に記述しています。
 */
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "ap-northeast"
}
variable "zones" {
  type = "list"
  default = ["ap-northeast-1","ap-northeast-1","ap-northeast-1"]
}
variable "mongo_instances" {
  type = "list"
  default = ["ecs.n1.small","ecs.n1.small","ecs.n1.small"]
}
variable "os_image" {}
variable "outbound_cidr" {}
variable "vpc_cidr" {}
variable "natgw_cidr" {}
variable "mongo_primary_cidr" {}
variable "mongo_secondary0_cidr" {}
variable "mongo_secondary1_cidr" {}

# Alicloud Providerの設定
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

########################################################################
# Securityグループ作成
#    1. mongo-cluster-securitygroup という名前のセキュレティグループを作成
#    2. ポート22だけ通信を許可。それ以外は拒否
# セキュリティグループの作成
resource "alicloud_security_group" "sg" {
  name   = "mongo-cluster-securitygroup"
  vpc_id = "${alicloud_vpc.vpc.id}" # セキュリティグループはVPCにひも付きます
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  /*
   * Webサーバインターネットからの通信ですが、実際にインターネットと通信するのはEIPのため
   * ECSのセキュリティグループのルール設定は"intranet"で問題ないです。
   */
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

########################################################################
# VPCネットの作成
#    1. mongovpc 10.0.0.0/16 VPCネットワークを作成
#    2. vswitchを3つ作成
#       a. mongo-primary 10.0.0.0/19 : primary インスタンスのサブネット
#       b. mongo-primary 10.0.32.0/19 : replica インスタンスのサブネット
#       c. mongo-primary 10.0.64.0/19 : replica インスタンスのサブネット
#    3. SNAT用のvpc作成 10.0.128.0/20

resource "alicloud_vpc" "vpc" {
  name = "mongovpc"
  cidr_block = "${var.vpc_cidr}"
}

# vswitchの作成。mongo-primary
resource "alicloud_vswitch" "mongo-primary-switch" {
  name              = "mongo-primary-switch"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.mongo_primary_cidr}"
  availability_zone = "${var.zones[0]}"
}

# vswitchの作成。mongo-secondary0
resource "alicloud_vswitch" "mongo-secondary0-switch" {
  name              = "mongo-secondary0-switch"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.mongo_secondary0_cidr}"
  availability_zone = "${var.zones[1]}"
}

# vswitchの作成。mongo-secondary1
resource "alicloud_vswitch" "mongo-secondary1-switch" {
  name              = "mongo-secondary1-switch"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.mongo_secondary1_cidr}"
  availability_zone = "${var.zones[2]}"
}

# vswitchの作成。nat-bastion
resource "alicloud_vswitch" "nat-bastion-switch" {
  name              = "mongo-nat-bastion-switch"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.natgw_cidr}"
  availability_zone = "${var.zones[0]}"
}

########################################################################
# ECS作成
#    1. SNATゲートウェイ用のECS作成
#    2. 外部通信のためのEIP / Routing設定
#    3. Mongoクラスと用のインスタンスを作成
#       a. 1 ecs in mongo-primary-vswitch
#       b. 1 ecs in mongo-secondary0-vswitch
#       c. 1 ecs in mongo-secondary1-vswitch

resource "alicloud_instance" "mongo-snat-gw" {
  instance_name = "mongo-cluster-nat-gateway"
  host_name = "mongo-snat-gw"
  availability_zone = "${var.zones[0]}"
  image_id = "${var.os_image}"
  instance_type = "ecs.n1.tiny"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.nat-bastion-switch.id}"
  user_data = "${file("provision_snat.sh")}"
}

resource "alicloud_eip" "snat-eip" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "snat-eip-asso" {
  allocation_id = "${alicloud_eip.snat-eip.id}"
  instance_id   = "${alicloud_instance.mongo-snat-gw.id}"
}

# SNAT設定
resource "alicloud_route_entry" "route-for-mongo-resource" {
  router_id             = "${alicloud_vpc.vpc.router_id}"
  route_table_id        = "${alicloud_vpc.vpc.router_table_id}"
  destination_cidrblock = "${var.outbound_cidr}"
  nexthop_type          = "Instance"
  nexthop_id            = "${alicloud_instance.mongo-snat-gw.id}"
}

#### Mongo クラスタ用のインスタンスを作成
resource "alicloud_instance" "mongo-primary" {
  instance_name = "mongo-primary"
  host_name = "mongo-primary"
  availability_zone = "${var.zones[0]}"
  image_id = "${var.os_image}"
  instance_type = "${var.mongo_instances[0]}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.mongo-primary-switch.id}"
  user_data = "${file("provision_mongo.sh")}"
}

resource "alicloud_instance" "mongo-secondary0" {
  instance_name = "mongo-secondary0"
  host_name = "mongo-secondary0"
  availability_zone = "${var.zones[1]}"
  image_id = "${var.os_image}"
  instance_type = "${var.mongo_instances[1]}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.mongo-secondary0-switch.id}"
  user_data = "${file("provision_mongo.sh")}"
}

resource "alicloud_instance" "mongo-secondary1" {
  instance_name = "mongo-secondary1"
  host_name = "mongo-secondary1"
  availability_zone = "${var.zones[2]}"
  image_id = "${var.os_image}"
  instance_type = "${var.mongo_instances[2]}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.mongo-secondary1-switch.id}"
  user_data = "${file("provision_mongo.sh")}"
}