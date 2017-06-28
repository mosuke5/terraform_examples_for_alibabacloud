output "wordpress_eip" {
    value = "${alicloud_eip.eip.ip_address}"
}

output "rds_connection_string" {
    value = "${alicloud_db_instance.rds.connections.0.connection_string}"
}
