variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "alicloud_slb" "slb" {
  name                 = "terraform-slb"
  internet             = true
  internet_charge_type = "paybytraffic"
  bandwidth            = 5
}
resource "alicloud_slb_listener" "tcp_http" {
  load_balancer_id = "${alicloud_slb.slb.id}"
  backend_port = "80"
  frontend_port = "80"
  protocol = "tcp"
  bandwidth = "10"
  health_check_type = "tcp"
}

#resource "alicloud_slb_attachment" "slb_attachment" {
#  load_balancer_id = "${alicloud_slb.slb.id}"
#  instance_ids = ["${alicloud_instance.web.*.id}"]
#}

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

resource "alicloud_vpc" "vpc" {
  name = "terraform-vpc"
  cidr_block = "192.168.1.0/24"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "192.168.1.0/28"
  availability_zone = "${var.zone}"
}

resource "alicloud_ess_scaling_group" "scaling" {
  scaling_group_name = "terraform-scaling-group"
  min_size           = 2
  max_size           = 5
  removal_policies   = ["OldestInstance", "NewestInstance"]
  vswitch_ids = ["${alicloud_vswitch.vsw.id}"]
  loadbalancer_ids = ["${alicloud_slb.slb.id}"]
}

resource "alicloud_ess_scaling_configuration" "config" {
  scaling_group_id  = "${alicloud_ess_scaling_group.scaling.id}"
  image_id          = "ubuntu_16_0402_64_20G_alibase_20180409.vhd"
  instance_type     = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_group_id = "${alicloud_security_group.sg.id}"
  scaling_configuration_name = "terraform-scaling-conf"
  active            = true 
  enable            = true 
  force_delete      = true
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
  launch_time         = "2018-07-01T12:00Z"
  scheduled_task_name = "terraform-schedule-scale-out"
  recurrence_type     = "Daily"
  recurrence_value    = 1
  recurrence_end_time = "2018-08-01T12:00Z"
}

resource "alicloud_ess_schedule" "schedule-scale-in" {
  scheduled_action    = "${alicloud_ess_scaling_rule.rule-scale-in.ari}"
  launch_time         = "2018-07-01T14:00Z"
  scheduled_task_name = "terraform-schedule-scale-in"
  recurrence_type     = "Daily"
  recurrence_value    = 1
  recurrence_end_time = "2018-08-01T12:00Z"
}
