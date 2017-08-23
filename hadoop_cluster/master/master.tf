variable "zone" {}
variable "vpc_id" {}
variable "master_subnet" {}
variable "worker_subnet" {}
variable "image_id" {}
variable "instance_name" {}
variable "instance_type" {}
variable "servers" {}

resource "alicloud_vswitch" "vsw-master" {
  name              = "hadoop-master"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.master_subnet}"
  availability_zone = "${var.zone}"
}

# ------------------------------------------------------------------------
# セキュリティグループの作成
resource "alicloud_security_group" "sg-master" {
  name   = "SecurityForMaster"
  vpc_id = "${var.vpc_id}"
}

resource "alicloud_security_group_rule" "allow_from_workers" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-master.id}"
  cidr_ip           = "${var.worker_subnet}"
}

resource "alicloud_security_group_rule" "allow_outbound_masters" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-master.id}"
  cidr_ip           = "0.0.0.0/0"
}

# ------------------------------------------------------------------------
# Master ECSの作成
resource "alicloud_instance" "master" {
  count = "${var.servers}"
  host_name = "master${count.index}"
  instance_name = "${var.instance_name}"
  availability_zone = "${var.zone}"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg-master.id}"]
  vswitch_id = "${alicloud_vswitch.vsw-master.id}"
  user_data = "${file("master/provision_master.sh")}"
}

# ------------------------------------------------------------------------
output "master_switch_id" {
  value = "${alicloud_vswitch.vsw-master.id}"
}

output "master_security_group_id" {
  value = "${alicloud_security_group.sg-master.id}"
}

output "master_instance_ip" {
  value = "${alicloud_instance.master.ip}"
}
