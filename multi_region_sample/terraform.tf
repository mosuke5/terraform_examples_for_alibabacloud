variable "access_key" {}
variable "secret_key" {}
variable "region_jp" {}
variable "zone_jp" {}
variable "region_cn" {}
variable "zone_cn" {}
variable "region_us" {}
variable "zone_us" {}
variable "project_name" {}
variable "publickey" {}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region_jp}"
  alias = "tokyo"
}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region_cn}"
  alias = "shanghai"
}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region_us}"
  alias = "silicon_valley"
}

module "tokyo" {
  source = "./global"
  region = "${var.region_jp}"
  zone = "${var.zone_jp}"
  project_name = "${var.project_name}"
  publickey = "${var.publickey}"
  vpc_cidr = "192.168.1.0/24"
  vsw_cidr = "192.168.1.0/28"
  providers = {
    alicloud = "alicloud.tokyo"
  }
}

module "shanghai" {
  source = "./global"
  region = "${var.region_cn}"
  zone = "${var.zone_cn}"
  project_name = "${var.project_name}"
  publickey = "${var.publickey}"
  vpc_cidr = "192.168.2.0/24"
  vsw_cidr = "192.168.2.0/28"
  providers = {
    alicloud = "alicloud.shanghai"
  }
}

module "silicon_valley" {
  source = "./global"
  region = "${var.region_us}"
  zone = "${var.zone_us}"
  project_name = "${var.project_name}"
  publickey = "${var.publickey}"
  vpc_cidr = "192.168.3.0/24"
  vsw_cidr = "192.168.3.0/28"
  providers = {
    alicloud = "alicloud.silicon_valley"
  }
}
