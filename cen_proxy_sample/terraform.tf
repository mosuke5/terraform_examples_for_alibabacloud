provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region-a}"
  alias      = "region-a"
}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region-b}"
  alias      = "region-b"
}

resource "alicloud_vpc" "vpc_region-a" {
  provider   = "alicloud.region-a"
  name       = "${var.vpc_name_region-a}"
  cidr_block = "${var.vpc_cidr_region-a}"
}

resource "alicloud_vswitch" "vsw_region-a" {
  provider          = "alicloud.region-a"
  vpc_id            = "${alicloud_vpc.vpc_region-a.id}"
  cidr_block        = "${var.vsw_cidr_region-a}"
  availability_zone = "${var.zone_region-a}"
}

resource "alicloud_vpc" "vpc_region-b" {
  provider   = "alicloud.region-b"
  name       = "${var.vpc_name_region-b}"
  cidr_block = "${var.vpc_cidr_region-b}"
}

resource "alicloud_vswitch" "vsw_region-b" {
  provider          = "alicloud.region-b"
  vpc_id            = "${alicloud_vpc.vpc_region-b.id}"
  cidr_block        = "${var.vsw_cidr_region-b}"
  availability_zone = "${var.zone_region-b}"
}

resource "alicloud_cen_instance" "cen" {
  provider    = "alicloud.region-a"
  name        = "${var.cen_name}"
  description = "${var.cen_description}"
}

resource "alicloud_cen_instance_attachment" "attachment_region-a" {
  provider                 = "alicloud.region-a"
  instance_id              = "${alicloud_cen_instance.cen.id}"
  child_instance_id        = "${alicloud_vpc.vpc_region-a.id}"
  child_instance_region_id = "${var.region-a}"
}

resource "alicloud_cen_instance_attachment" "attachment_region-b" {
  provider                 = "alicloud.region-b"
  instance_id              = "${alicloud_cen_instance.cen.id}"
  child_instance_id        = "${alicloud_vpc.vpc_region-b.id}"
  child_instance_region_id = "${var.region-b}"
}

resource "alicloud_vpn_gateway" "vpn-gateway" {
  provider             = "alicloud.region-b"
  name                 = "${var.vpn_gateway_name}"
  vpc_id               = "${alicloud_vpc.vpc_region-b.id}"
  bandwidth            = "10"
  enable_ipsec         = false
  enable_ssl           = true
  instance_charge_type = "PostPaid"
  description          = "${var.vpn_gateway_description}"
}

resource "alicloud_ssl_vpn_server" "ssl-vpn-server" {
  provider       = "alicloud.region-b"
  name           = "${var.ssl_vpn_server_name}"
  vpn_gateway_id = "${alicloud_vpn_gateway.vpn-gateway.id}"
  client_ip_pool = "${var.client_ip_pool}"
  local_subnet   = "${alicloud_vpc.vpc_region-a.cidr_block}"
  protocol       = "UDP"
  cipher         = "AES-128-CBC"
  port           = 1194
  compress       = "false"
}

resource "alicloud_ssl_vpn_client_cert" "cert1" {
  provider          = "alicloud.region-b"
  ssl_vpn_server_id = "${alicloud_ssl_vpn_server.ssl-vpn-server.id}"
  name              = "${var.ssl_vpn_client_cert_name}"
}

resource "alicloud_security_group" "sg_region-a" {
  provider = "alicloud.region-a"
  name     = "terraform-sg"
  vpc_id   = "${alicloud_vpc.vpc_region-a.id}"
}

resource "alicloud_security_group_rule" "allow_ssh-a" {
  provider          = "alicloud.region-a"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_region-a.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group" "sg_region-b" {
  provider = "alicloud.region-b"
  name     = "terraform-sg"
  vpc_id   = "${alicloud_vpc.vpc_region-b.id}"
}

resource "alicloud_security_group_rule" "allow_ssh_region-b" {
  provider          = "alicloud.region-b"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_region-b.id}"
  cidr_ip           = "0.0.0.0/0"
}


resource "alicloud_cen_route_entry" "vpn" {
    provider       = "alicloud.region-b"
    instance_id    = "${alicloud_cen_instance.cen.id}"
    route_table_id = "${alicloud_vpc.vpc_region-b.route_table_id}"
    cidr_block     = "${var.client_ip_pool}"
    depends_on     = [
        "alicloud_ssl_vpn_server.ssl-vpn-server"
    ]
}

resource "alicloud_instance" "proxy-a" {
  provider             = "alicloud.region-a"
  instance_name        = "terraform-ecs"
  host_name            = "proxy-ecs"
  availability_zone    = "${var.zone_region-a}"
  image_id             = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type        = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.sg_region-a.id}"]
  vswitch_id           = "${alicloud_vswitch.vsw_region-a.id}"
  user_data            = "#!/bin/bash\nmkdir -p /root/.ssh\nchmod 700 /root/.ssh\necho \"${var.publickey}\" > /root/.ssh/authorized_keys\nchmod 400 /root/.ssh/authorized_keys}"
}

resource "alicloud_instance" "proxy-b" {
  provider             = "alicloud.region-b"
  instance_name        = "terraform-ecs"
  host_name            = "proxy-ecs"
  availability_zone    = "${var.zone_region-b}"
  image_id             = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type        = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.sg_region-b.id}"]
  vswitch_id           = "${alicloud_vswitch.vsw_region-b.id}"
  user_data            = "#!/bin/bash\nmkdir -p /root/.ssh\nchmod 700 /root/.ssh\necho \"${var.publickey}\" > /root/.ssh/authorized_keys\nchmod 400 /root/.ssh/authorized_keys}"
}

resource "alicloud_eip" "eip-a" {
  provider             = "alicloud.region-a"
}

resource "alicloud_eip" "eip-b" {
  provider             = "alicloud.region-b"
}

resource "alicloud_eip_association" "eip_associate-a" {
  provider             = "alicloud.region-a"
  allocation_id = "${alicloud_eip.eip-a.id}"
  instance_id   = "${alicloud_instance.proxy-a.id}"
}

resource "alicloud_eip_association" "eip_associate-b" {
  provider             = "alicloud.region-b"
  allocation_id = "${alicloud_eip.eip-b.id}"
  instance_id   = "${alicloud_instance.proxy-b.id}"
}
