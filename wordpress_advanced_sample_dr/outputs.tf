output "slb_ip" {
    value = "${alicloud_slb.slb.address}"
}

output "ecs_db_private_ip" {
    value = "${alicloud_instance.db.private_ip}"
}

output "ecs_web_private_ip" {
    value = "${join(",",alicloud_instance.web.*.private_ip)}"
}

output "ecs_web_public_ip" {
    value = "${join(",",alicloud_instance.web.*.public_ip)}"
}
