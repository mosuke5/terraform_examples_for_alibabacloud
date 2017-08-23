/*
 * API KEYはとても重要なデータです。
 * terraform本体のファイルには記述せず、
 * 変数ファイル(sample.tfvars)に記述しています。
 */
variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "image_id" {}
variable "instance_type" {}

# Alicloud Providerの設定
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "alicloud_vpc" "vpc" {
  name = "hadoop-cluster-vpc"
  cidr_block = "10.18.128.0/20"
}

# ------------------------------------------------------------------------
# Core Cluster サーバー作成

module "master" {
  source = "./master"
  zone = "${var.zone}"
  vpc_id = "${alicloud_vpc.vpc.id}"
  master_subnet = "10.18.129.0/24"
  worker_subnet = "10.18.130.0/24"
  image_id = "${var.image_id}"
  instance_name = "hadoop-master"
  instance_type = "${var.instance_type}"
  servers = 1
}

module "worker" {
  source = "./worker"
  zone = "${var.zone}"
  vpc_id = "${alicloud_vpc.vpc.id}"
  master_subnet = "10.18.129.0/24"
  worker_subnet = "10.18.130.0/24"
  image_id = "${var.image_id}"
  instance_name = "hadoop-worker"
  instance_type = "${var.instance_type}"
  servers = 3
  disks_per_server = 2
}

# ------------------------------------------------------------------------
resource "alicloud_instance" "manager-server" {
  host_name = "manager-server"
  instance_name = "manager-server"
  availability_zone = "${var.zone}"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  io_optimized = "optimized"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${module.master.master_security_group_id}"]
  vswitch_id = "${module.master.master_switch_id}"
  user_data = "${file("./provisioning.sh")}"
}

# ECSに紐付けるEIP(グローバルIP)の作成
resource "alicloud_eip" "manager-eip" {
  internet_charge_type = "PayByTraffic"
}

# 作成したEIPをECSと紐付けします
resource "alicloud_eip_association" "eip_asso" {
  allocation_id = "${alicloud_eip.manager-eip.id}"
  instance_id   = "${alicloud_instance.manager-server.id}"
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 100
  security_group_id = "${module.master.master_security_group_id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_manager" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "7180/7180"
  priority          = 100
  security_group_id = "${module.master.master_security_group_id}"
  cidr_ip           = "0.0.0.0/0"
}

# ------------------------------------------------------------------------
output "worker_ips" {
  value = ["${module.worker.workers_instance_ip}"]
}

output "master_ip" {
  value = ["${module.master.master_instance_ip}"]
}