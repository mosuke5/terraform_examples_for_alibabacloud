variable "access_key" {}
variable "secret_key" {}
variable "region-a" {
  default = "ap-northeast-1"
}
variable "region-b" {
  default = "ap-northeast-1"
}
variable "cen_name" {}
variable "cen_description" {}
variable "vpc_name_region-a" {}
variable "vpc_cidr_region-a" {}
variable "vsw_cidr_region-a" {}
variable "vpc_name_region-b" {}
variable "vpc_cidr_region-b" {}
variable "vsw_cidr_region-b" {}
variable "vpn_gateway_name" {}
variable "vpn_gateway_description" {}
variable "ssl_vpn_server_name" {}
variable "client_ip_pool" {}
variable "ssl_vpn_client_cert_name" {}

variable "zone_region-a" {}
variable "zone_region-b" {}

variable "publickey" {}
