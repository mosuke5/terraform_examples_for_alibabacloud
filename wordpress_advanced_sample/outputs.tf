output "slb_ip" {
    value = "${alicloud_slb.slb.address}"
}

output "bastion_eip" {
    value = "${alicloud_eip.eip.ip_address}"
}

output "ecs_private_ip" {
    value = "${join(",",alicloud_instance.web.*.private_ip)}"
}

output "rds_connection_string" {
    value = "${alicloud_db_instance.db.connection_string}"
}
