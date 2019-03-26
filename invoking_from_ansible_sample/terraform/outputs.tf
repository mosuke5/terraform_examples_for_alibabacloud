output "public_ip" {
    value = "${join(",",alicloud_instance.web.*.public_ip)}"
}
