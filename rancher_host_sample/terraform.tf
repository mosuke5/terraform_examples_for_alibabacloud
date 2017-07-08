variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "rancher_manager_image" {}
variable "rancher_host_image" {}
variable "rancher_agent_install_cmd" {}
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

# セキュリティグループの作成
resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

# セキュリティグループのルール設定
resource "alicloud_security_group_rule" "allow_all_ingress" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_egress" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
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
  instance_id   = "${alicloud_instance.rancher_manager.id}"
}

resource "alicloud_instance" "rancher_manager" {
  instance_name = "rancher-manager"
  host_name = "rancher-manager"
  availability_zone = "${var.zone}"
  image_id = "${var.rancher_manager_image}"
  instance_type = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
}

/*
resource "alicloud_instance" "rancher_host" {
  count = 2
  instance_name = "rancher-host-${count.index}"
  host_name = "rancher-host-${count.index}"
  availability_zone = "${var.zone}"
  image_id = "${var.rancher_host_image}"
  instance_type = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  internet_charge_type = "PayByTraffic"
  internet_max_bandwidth_out = "5"
  user_data = "${var.rancher_agent_install_cmd}"
}

resource "alicloud_db_instance" "rds" {
    engine = "MySQL"
    engine_version = "5.6"
    db_instance_class = "rds.mysql.t1.small"
    db_instance_storage = "10"
    db_instance_net_type = "Intranet"
    vswitch_id = "${alicloud_vswitch.vsw.id}"
    security_ips  = ["${alicloud_instance.rancher_host.*.private_ip}"]

    master_user_name = "${var.database_user_name}"
    master_user_password = "${var.database_user_password}"

    db_mappings = [{
      db_name = "${var.database_name}"
      character_set_name = "${var.database_character}"
      db_description = "terraform wordpress"
    }]
}
*/