variable "zone" {}
variable "vpc_id" {}
variable "master_subnet" {}
variable "worker_subnet" {}
variable "image_id" {}
variable "instance_name" {}
variable "instance_type" {}
variable "servers" {}
variable "disks_per_server" {}

# ------------------------------------------------------------------------
# セキュリティグループの作成
resource "alicloud_security_group" "sg-worker" {
  name   = "SecurityForWorkers"
  vpc_id = "${var.vpc_id}"
}

resource "alicloud_security_group_rule" "allow_from_master" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-worker.id}"
  cidr_ip           = "${var.master_subnet}"
}

resource "alicloud_security_group_rule" "allow_outbound_workers" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-worker.id}"
  cidr_ip           = "0.0.0.0/0"
}

# ------------------------------------------------------------------------
resource "alicloud_vswitch" "vsw-worker" {
  name              = "hadoop-worker"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.worker_subnet}"
  availability_zone = "${var.zone}"
}

resource "alicloud_instance" "workers" {
  count = "${var.servers}"
  host_name = "worker${count.index}"
  availability_zone = "${var.zone}"
  image_id = "${var.image_id}"
  instance_name = "${var.instance_name}${count.index}"
  instance_type = "${var.instance_type}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg-worker.id}"]
  vswitch_id = "${alicloud_vswitch.vsw-worker.id}"
  tags {
    name = "${var.instance_name}-${count.index}"
  }
}

# ------------------------------------------------------------------------
# Disks
resource "alicloud_disk" "disks" {
  count = "${var.disks_per_server * var.servers}"
  availability_zone = "${var.zone}"
  category          = "cloud_ssd"
  size              = "50"
}

resource "alicloud_disk_attachment" "worker-disk-attach" {
  count = "${var.disks_per_server * var.servers}"
  disk_id     = "${element(alicloud_disk.disks.*.id, count.index)}"
  instance_id = "${element(alicloud_instance.workers.*.id, count.index / var.disks_per_server)}"
}

# ------------------------------------------------------------------------
# Outputs
output "worker_switch_id" {
  value = "${alicloud_vswitch.vsw-worker.id}"
}

output "worker_security_group_id" {
  value = "${alicloud_security_group.sg-worker.id}"
}

output "workers_instance_ip" {
  value = ["${alicloud_instance.workers.*.ip}"]
}

