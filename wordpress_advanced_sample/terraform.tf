variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "password" {}
variable "publickey" {}
variable "database_user_name" {}
variable "database_user_password" {}
variable "database_name" {}
variable "database_character" {}

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
      "health_check"  = "on"
      "health_check_type" = "http"
      "health_check_connect_port" = "80"
      "health_check_domain" = "$_ip"
      "health_check_uri" = "/"
      "health_check_http_code" = "http_2xx"
      "health_check_timeout" = "5"
      "health_check_interval" = "5"
      "healthy_threshold" = "3"
      "unhealthy_threshold" = "3"
    }
  ]
}

resource "alicloud_slb_attachment" "slb_attachment" {
    slb_id    = "${alicloud_slb.slb.id}"
    instances = ["${alicloud_instance.web.*.id}"]
}

# セキュリティグループの作成
resource "alicloud_security_group" "sg_fumidai" {
  name   = "terraform-sg-fumidai"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "fumidai_allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_fumidai.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "fumidai_allow_all_from_internal" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_fumidai.id}"
  cidr_ip           = "192.168.0.0/16"
}

resource "alicloud_security_group" "sg_wordpress" {
  name   = "terraform-sg-wordpress"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "wordpress_allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_wordpress.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "wordpress_allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_wordpress.id}"
  cidr_ip           = "0.0.0.0/0"
}

# VPCの作成
resource "alicloud_vpc" "vpc" {
  name = "terraform-vpc"
  cidr_block = "192.168.0.0/16"
}

# vswitchの作成。VPCの中に作ります。
resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "192.168.1.0/24"
  availability_zone = "${var.zone}"
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
  instance_name = "terraform-ecs-web${count.index}"
  host_name = "wordpress-ecs-web${count.index}"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg_wordpress.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  user_data = "#!/bin/bash\necho \"${var.publickey}\" > /tmp/publickey"
  password = "${var.password}"
}

# ECSの作成
resource "alicloud_instance" "fumidai" {
  instance_name = "terraform-ecs-fumidai"
  host_name = "wordpress-ecs-fumidai"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg_fumidai.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  user_data = "#!/bin/bash\necho \"${var.publickey}\" > /tmp/publickey\n${file("provisioning_fumidai.sh")}"
  password = "${var.password}"
}

resource "alicloud_route_entry" "default" {
  router_id             = "${alicloud_vpc.vpc.router_id}"
  route_table_id        = "${alicloud_vpc.vpc.router_table_id}"
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "Instance"
  nexthop_id            = "${alicloud_instance.fumidai.id}"
}

resource "alicloud_db_instance" "rds" {
    engine = "MySQL"
    engine_version = "5.6"
    db_instance_class = "rds.mysql.t1.small"
    db_instance_storage = "10"
    db_instance_net_type = "Intranet"
    vswitch_id = "${alicloud_vswitch.vsw.id}"
    security_ips  = ["${alicloud_instance.web.*.private_ip}"]

    master_user_name = "${var.database_user_name}"
    master_user_password = "${var.database_user_password}"

    db_mappings = [{
      db_name = "${var.database_name}"
      character_set_name = "${var.database_character}"
      db_description = "terraform wordpress"
    }]
}
