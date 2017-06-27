output "rds_connection_string" {
    value = "${join(",", alicloud_db_instance.rds.connections.*.connection_string)}"
}
