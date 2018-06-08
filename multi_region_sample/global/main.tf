variable "region" {}
variable "zone" {}
variable "vpc_cidr" {}
variable "vsw_cidr" {}
variable "project_name" {} 
variable "publickey" {} 
variable "instance_password" {} 

resource "alicloud_vpc" "vpc" {
  name = "${var.project_name}-vpc"
  cidr_block = "${var.vpc_cidr}"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.vsw_cidr}"
  availability_zone = "${var.zone}"
}

resource "alicloud_security_group" "sg" {
  name   = "${var.project_name}-sg"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_from_internal" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg.id}"
  cidr_ip           = "192.168.0.0/16"
}

resource "alicloud_instance" "instance" {
  instance_name = "${var.project_name}-ecs"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.mn4.large"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg.id}"]
  vswitch_id = "${alicloud_vswitch.vsw.id}"
  password = "${var.instance_password}"
  host_name = "${var.project_name}-${var.region}"
  internet_max_bandwidth_out = 100
}
