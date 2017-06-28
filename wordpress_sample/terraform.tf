variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
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

# セキュリティグループの作成
resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}"
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
  instance_id   = "${alicloud_instance.web.id}"
}

# ECSの作成
resource "alicloud_instance" "web" {
  instance_name = "terraform-ecs"
  host_name = "wordpress-ecs"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  user_data = "#!/bin/bash\necho \"${var.publickey}\" > /tmp/publickey\n${file("provisioning.sh")}"
}

resource "alicloud_db_instance" "rds" {
    engine = "MySQL"
    engine_version = "5.6"
    db_instance_class = "rds.mysql.t1.small"
    db_instance_storage = "10"
    db_instance_net_type = "Intranet"
    vswitch_id = "${alicloud_vswitch.vsw.id}"
    security_ips  = ["${alicloud_instance.web.private_ip}"]

    master_user_name = "${var.database_user_name}"
    master_user_password = "${var.database_user_password}"

    db_mappings = [{
      db_name = "${var.database_name}"
      character_set_name = "${var.database_character}"
      db_description = "terraform wordpress"
    }]
}
