variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "database_user_name" {}
variable "database_user_password" {}
variable "database_name" {}
variable "database_character" {}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "alicloud_security_group" "sg" {
  name   = "terraform-sg"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

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

resource "alicloud_vpc" "vpc" {
  name       = "terraform-vpc"
  cidr_block = "192.168.1.0/24"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "192.168.1.0/28"
  availability_zone = "${var.zone}"
}

resource "alicloud_eip" "eip" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.eip.id}"
  instance_id   = "${alicloud_instance.web.id}"
}

resource "alicloud_instance" "web" {
  instance_name        = "terraform-ecs"
  availability_zone    = "${var.zone}"
  image_id             = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type        = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.sg.id}"]
  vswitch_id           = "${alicloud_vswitch.vsw.id}"
}

resource "alicloud_db_instance" "db" {
  engine           = "MySQL"
  engine_version   = "5.6"
  instance_name    = "terraform-rds"
  vswitch_id       = "${alicloud_vswitch.vsw.id}"
  security_ips     = ["${alicloud_instance.web.private_ip}"]
  instance_type    = "rds.mysql.t1.small"
  instance_storage = "50"
}

resource "alicloud_db_account" "default" {
  instance_id = "${alicloud_db_instance.db.id}"
  name        = "${var.database_user_name}"
  password    = "${var.database_user_password}"
}

resource "alicloud_db_account_privilege" "default" {
  instance_id  = "${alicloud_db_instance.db.id}"
  account_name = "${alicloud_db_account.default.name}"
  privilege    = "ReadWrite"
  db_names     = ["${alicloud_db_database.default.name}"]
}

resource "alicloud_db_database" "default" {
  instance_id   = "${alicloud_db_instance.db.id}"
  name          = "${var.database_name}"
  character_set = "${var.database_character}"
}
