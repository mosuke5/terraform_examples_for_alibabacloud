# この記事のサンプルコードです。
# http://qiita.com/mosuke5/items/a65683ce6569bffd7ef0

/*
 * API KEYはとても重要なデータです。
 * terraform本体のファイルには記述せず、
 * 変数ファイル(sample.tfvars)に記述しています。
 */
variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}

# Alicloud Providerの設定
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

# セキュリティグループの作成
resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}" # セキュリティグループはVPCにひも付きます
}

# セキュリティグループのルール設定
# 今回はWebサーバということで80番ポートのみ空けます
resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  /*
   * Webサーバインターネットからの通信ですが、実際にインターネットと通信するのはEIPのため
   * ECSのセキュリティグループのルール設定は"intranet"で問題ないです。
   */ 
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# VPCの作成
resource "alicloud_vpc" "vpc" {
  name = "terraform-vpc"
  cidr_block = "10.1.0.0/21"
}

# vswitchの作成。VPCの中に作ります。
resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "10.1.1.0/24"
  availability_zone = "${var.zone}"
}

# ECSに紐付けるEIP(グローバルIP)の作成
resource "alicloud_eip" "eip" {
  internet_charge_type = "PayByTraffic"
}

# 作成したEIPをECSと紐付けします
resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.eip.id}"
  instance_id   = "${alicloud_instance.web.id}"
}

# ECSの作成
resource "alicloud_instance" "web" {
  instance_name = "terraform-ecs"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"] # セキュリティグループは複数設定できるのでListになってます
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  user_data = "#include\nhttps://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/master/basic_sample/provisioning.sh"
}
