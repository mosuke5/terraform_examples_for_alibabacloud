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

# Create a new load balancer for classic
resource "alicloud_slb" "slb" {
  name                 = "terraform-slb"
  internet             = true
  internet_charge_type = "paybytraffic"

  listener = [
    {
      "instance_port" = "80"
      "lb_port"       = "80"
      "lb_protocol"   = "http"
      "bandwidth"     = "10"
      "sticky_session" = "on"
      "sticky_session_type" = "insert"
      "cookie_timeout" = "1"
    }
  ]
}

resource "alicloud_slb_attachment" "slb_attachment" {
    slb_id    = "${alicloud_slb.slb.id}"
    instances = ["${alicloud_instance.web.*.id}"]
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

# vpc内サーバはfumidaiサーバを経由してインターネットに出れるようにルーティング設定
# fumidaiサーバへのフォワーディング設定は別途必要
resource "alicloud_route_entry" "default" {
  router_id             = "${alicloud_vpc.vpc.router_id}"
  route_table_id        = "${alicloud_vpc.vpc.router_table_id}"
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "Instance"
  nexthop_id            = "${alicloud_instance.fumidai.id}"
}

# ECSに紐付けるEIP(グローバルIP)の作成
resource "alicloud_eip" "eip" {
  internet_charge_type = "PayByTraffic"
}

# 作成したEIPをECSと紐付けします
resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.eip.id}"
  instance_id   = "${alicloud_instance.fumidai.id}"
}

# ECSの作成
resource "alicloud_instance" "web" {
  count = 2
  instance_name = "terraform-ecs"
  availability_zone = "${var.zone}"
  image_id = "m-6wec065ood8fic52mh6v" # CentOS7.3
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
}

resource "alicloud_instance" "fumidai" {
  instance_name = "terraform-ecs-fumidai"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
}
