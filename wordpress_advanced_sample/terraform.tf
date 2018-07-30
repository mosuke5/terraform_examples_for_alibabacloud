variable "project_name" {}
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

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "alicloud_slb" "slb" {
  name                 = "terraform-slb"
  internet             = true
  internet_charge_type = "paybytraffic"
  bandwidth            = 5
}

resource "alicloud_slb_listener" "tcp_http" {
  load_balancer_id          = "${alicloud_slb.slb.id}"
  backend_port              = "80"
  frontend_port             = "80"
  protocol                  = "http"
  bandwidth                 = "10"
  health_check_type         = "http"
  health_check_connect_port = "80"
}

resource "alicloud_slb_attachment" "slb_attachment" {
  load_balancer_id = "${alicloud_slb.slb.id}"
  instance_ids     = ["${alicloud_instance.web.*.id}"]
}

resource "alicloud_security_group" "sg_bastion" {
  name   = "${var.project_name}-sg-bastion"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "bastion_allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_bastion.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bastion_allow_all_from_internal" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_bastion.id}"
  cidr_ip           = "192.168.1.0/24"
}

resource "alicloud_security_group_rule" "bastion_allow_all_to_external" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_bastion.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group" "sg_wordpress" {
  name   = "${var.project_name}-sg-wordpress"
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

resource "alicloud_security_group_rule" "wordpress_allow_all_to_external" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_wordpress.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_vpc" "vpc" {
  name       = "${var.project_name}-vpc"
  cidr_block = "192.168.1.0/24"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "192.168.1.0/28"
  availability_zone = "${var.zone}"
}

resource "alicloud_nat_gateway" "nat_gateway" {
  vpc_id        = "${alicloud_vpc.vpc.id}"
  specification = "Small"
  name          = "terraform-nat-gw"
}

resource "alicloud_snat_entry" "default" {
  snat_table_id     = "${alicloud_nat_gateway.nat_gateway.snat_table_ids}"
  source_vswitch_id = "${alicloud_vswitch.vsw.id}"
  snat_ip           = "${alicloud_eip.nat_eip.ip_address}"
}

resource "alicloud_eip" "eip" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip" "nat_eip" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.eip.id}"
  instance_id   = "${alicloud_instance.bastion.id}"
}

resource "alicloud_eip_association" "nat_eip_asso" {
  allocation_id = "${alicloud_eip.nat_eip.id}"
  instance_id   = "${alicloud_nat_gateway.nat_gateway.id}"
}

resource "alicloud_instance" "web" {
  count                = 2
  instance_name        = "${var.project_name}-ecs-web${count.index}"
  host_name            = "wordpress-ecs-web${count.index}"
  availability_zone    = "${var.zone}"
  image_id             = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type        = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.sg_wordpress.id}"]
  vswitch_id           = "${alicloud_vswitch.vsw.id}"
  user_data            = "#!/bin/bash\necho \"${var.publickey}\" > /tmp/publickey\n${file("provisioning.sh")}"
  password             = "${var.password}"
}

resource "alicloud_instance" "bastion" {
  instance_name        = "${var.project_name}-ecs-bastion"
  host_name            = "wordpress-ecs-bastion"
  availability_zone    = "${var.zone}"
  image_id             = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type        = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.sg_bastion.id}"]
  vswitch_id           = "${alicloud_vswitch.vsw.id}"
  user_data            = "#!/bin/bash\necho \"${var.publickey}\" > /tmp/publickey\n${file("provisioning_bastion.sh")}"
  password             = "${var.password}"
}

resource "alicloud_db_instance" "db" {
  engine           = "MySQL"
  engine_version   = "5.6"
  instance_name    = "terraform-rds"
  vswitch_id       = "${alicloud_vswitch.vsw.id}"
  security_ips     = ["${alicloud_instance.web.*.private_ip}"]
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
