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

resource "alicloud_vpc" "vpc_1" {
  name       = "${var.project_name}-vpc-1"
  cidr_block = "192.168.1.0/24"
}

resource "alicloud_vswitch" "vsw_1" {
  vpc_id            = "${alicloud_vpc.vpc_1.id}"
  cidr_block        = "192.168.1.0/28"
  availability_zone = "${var.zone}"
}

resource "alicloud_vpn_gateway" "vpn_gw_1" {
    name = "${var.project_name}-vpn-gw-1"
    vpc_id = "${alicloud_vpc.vpc_1.id}"
    bandwidth = "10"
    instance_charge_type = "PostPaid"
		enable_ssl = true
}

resource "alicloud_vpn_customer_gateway" "cgw_1" {
    name = "${var.project_name}-cgw-1"
    ip_address = "${alicloud_vpn_gateway.vpn_gw_2.internet_ip}"
}

resource "alicloud_vpc" "vpc_2" {
  name       = "${var.project_name}-vpc-2"
  cidr_block = "192.168.2.0/24"
}

resource "alicloud_vswitch" "vsw_2" {
  vpc_id            = "${alicloud_vpc.vpc_2.id}"
  cidr_block        = "192.168.2.0/28"
  availability_zone = "${var.zone}" }

resource "alicloud_vpn_gateway" "vpn_gw_2" {
    name = "${var.project_name}-vpn-gw-2"
    vpc_id = "${alicloud_vpc.vpc_2.id}"
    bandwidth = "10"
    instance_charge_type = "PostPaid"
		enable_ssl = true
}

resource "alicloud_vpn_customer_gateway" "cgw_2" {
    name = "${var.project_name}-cgw-2"
    ip_address = "${alicloud_vpn_gateway.vpn_gw_1.internet_ip}"
}

resource "alicloud_vpn_connection" "vpn_connection_1" {
    name = "${var.project_name}-connection-1"
    vpn_gateway_id = "${alicloud_vpn_gateway.vpn_gw_1.id}"
    customer_gateway_id = "${alicloud_vpn_customer_gateway.cgw_1.id}"
    local_subnet = ["192.168.1.0/24"]
    remote_subnet = ["192.168.2.0/24"]
    effect_immediately = true
    ike_config = [{
        ike_auth_alg = "sha1"
        ike_enc_alg = "aes"
        ike_version = "ikev1"
        ike_mode = "main"
        ike_lifetime = 86400
        psk = "tf-testvpn2"
        ike_pfs = "group2"
        ike_remote_id = "test"
        ike_local_id = "test"
    }]
		ipsec_config = [{
        ipsec_pfs = "group2"
        ipsec_enc_alg = "aes"
        ipsec_auth_alg = "sha1"
        ipsec_lifetime = 8640
    }]
}

resource "alicloud_vpn_connection" "vpn_connection_2" {
    name = "${var.project_name}-connection-2"
    vpn_gateway_id = "${alicloud_vpn_gateway.vpn_gw_2.id}"
    customer_gateway_id = "${alicloud_vpn_customer_gateway.cgw_2.id}"
    local_subnet = ["192.168.2.0/24"]
    remote_subnet = ["192.168.1.0/24"]
    effect_immediately = true
    ike_config = [{
      ike_auth_alg = "sha1"
        ike_enc_alg = "aes"
        ike_version = "ikev1"
        ike_mode = "main"
        ike_lifetime = 86400
        psk = "tf-testvpn2"
        ike_pfs = "group2"
        ike_remote_id = "test"
        ike_local_id = "test"
    }]
		ipsec_config = [{
        ipsec_pfs = "group2"
        ipsec_enc_alg = "aes"
        ipsec_auth_alg = "sha1"
        ipsec_lifetime = 8640
    }]
}


resource "alicloud_security_group" "sg_1" {
  name   = "${var.project_name}-sg-1"
  vpc_id = "${alicloud_vpc.vpc_1.id}"
}
resource "alicloud_security_group" "sg_2" {
  name   = "${var.project_name}-sg-2"
  vpc_id = "${alicloud_vpc.vpc_2.id}"
}
resource "alicloud_security_group_rule" "allow_ssh_1" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_1.id}"
  cidr_ip           = "0.0.0.0/0"
}
resource "alicloud_security_group_rule" "allow_ssh_2" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_2.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_from_internal_1" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_1.id}"
  cidr_ip           = "192.168.0.0/16"
}
resource "alicloud_security_group_rule" "allow_all_from_internal_2" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.sg_2.id}"
  cidr_ip           = "192.168.0.0/16"
}

resource "alicloud_instance" "ecs1" {
  instance_name = "${var.project_name}-ecs-1"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.small"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg_1.id}"]
  vswitch_id = "${alicloud_vswitch.vsw_1.id}"
  password = "Test1234"
}

resource "alicloud_instance" "ecs2" {
  instance_name = "${var.project_name}-ecs-2"
  availability_zone = "${var.zone}"
  image_id = "centos_7_3_64_40G_base_20170322.vhd"
  instance_type = "ecs.n4.large"
  system_disk_category = "cloud_efficiency"
  security_groups = ["${alicloud_security_group.sg_2.id}"]
  vswitch_id = "${alicloud_vswitch.vsw_2.id}"
  password = "Test1234"
}

resource "alicloud_eip" "eip1" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "eip_asso1" {
  allocation_id = "${alicloud_eip.eip1.id}"
  instance_id   = "${alicloud_instance.ecs1.id}"
}

resource "alicloud_eip" "eip2" {
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_eip_association" "eip_asso2" {
  allocation_id = "${alicloud_eip.eip2.id}"
  instance_id   = "${alicloud_instance.ecs2.id}"
}

resource "alicloud_route_entry" "re1" {
  route_table_id        = "${alicloud_vpc.vpc_1.router_table_id}"
  destination_cidrblock = "192.168.2.0/24"
  nexthop_type          = "VpnGateway"
  nexthop_id            = "${alicloud_vpn_gateway.vpn_gw_1.id}"
}
resource "alicloud_route_entry" "re2" {
  route_table_id        = "${alicloud_vpc.vpc_2.router_table_id}"
  destination_cidrblock = "192.168.1.0/24"
  nexthop_type          = "VpnGateway"
  nexthop_id            = "${alicloud_vpn_gateway.vpn_gw_2.id}"
}
