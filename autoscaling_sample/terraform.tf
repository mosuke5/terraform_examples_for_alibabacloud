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

# セキュリティグループの作成
resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}" # セキュリティグループはVPCにひも付きます
}

# セキュリティグループのルール設定
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

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 2
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

resource "alicloud_ess_scaling_group" "scaling" {
  scaling_group_name = "terraform-scaling-group"
  min_size           = 2
  max_size           = 5
  removal_policies   = ["OldestInstance", "NewestInstance"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  loadbalancer_ids = ["${alicloud_slb.slb.id}"]
}

resource "alicloud_ess_scaling_configuration" "config" {
  scaling_group_id  = "${alicloud_ess_scaling_group.scaling.id}"
  image_id          = "m-t4n9xcbgxmq3cl3cgb8c"
  instance_type     = "ecs.n1.tiny"
  io_optimized      = "optimized"
  system_disk_category = "cloud_efficiency"
  security_group_id = "${alicloud_security_group.sg.id}"
  active            = true
  scaling_configuration_name = "terraform-scaling-conf"
}

resource "alicloud_ess_scaling_rule" "rule-scale-out" {
  scaling_rule_name = "terraform-scale-out"
  scaling_group_id = "${alicloud_ess_scaling_group.scaling.id}"
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = 2
  cooldown         = 60
}

resource "alicloud_ess_scaling_rule" "rule-scale-in" {
  scaling_rule_name = "terraform-scale-in"
  scaling_group_id = "${alicloud_ess_scaling_group.scaling.id}"
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = -2
  cooldown         = 60
}

resource "alicloud_ess_schedule" "schedule-scale-out" {
  scheduled_action    = "${alicloud_ess_scaling_rule.rule-scale-out.ari}"
  launch_time         = "2017-05-23T03:00Z"  # UTC時間
  scheduled_task_name = "terraform-schedule-scale-out"
  recurrence_type     = "Daily"
  recurrence_end_time = "2017-08-01T03:00Z"  # UTC時間
  recurrence_value    = 1
}

resource "alicloud_ess_schedule" "schedule-scale-in" {
  scheduled_action    = "${alicloud_ess_scaling_rule.rule-scale-in.ari}"
  launch_time         = "2017-05-23T05:00Z"  # UTC時間
  scheduled_task_name = "terraform-schedule-scale-in"
  recurrence_type     = "Daily"
  recurrence_end_time = "2017-08-01T05:00Z"  # UTC時間
  recurrence_value    = 1
}
