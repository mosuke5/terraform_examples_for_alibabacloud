variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
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
  vpc_id = "${alicloud_vpc.vpc.id}" # セキュリティグループはVPCにひも付きます
}

# VPCの作成
resource "alicloud_vpc" "vpc" {
  name = "terraform-vpc"
  cidr_block = "10.1.0.0/21"
}

# vswitchの作成。VPCの中に作ります。
resource "alicloud_vswitch" "vsw" {
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "10.1.1.0/24"
  availability_zone = "${var.zone}"
}

resource "alicloud_db_instance" "rds" {
    engine = "MySQL"
    engine_version = "5.6"
    db_instance_class = "rds.mysql.t1.small"
    db_instance_storage = "10"
    db_instance_net_type = "Intranet"
    vswitch_id = "${alicloud_vswitch.vsw.id}"

    master_user_name = "${var.database_user_name}"
    master_user_password = "${var.database_user_password}"

    db_mappings = [{
      db_name = "${var.database_name}"
      character_set_name = "${var.database_character}"
      db_description = "tf"
    }]
}
