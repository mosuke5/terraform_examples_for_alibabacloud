variable "account_id" {}
variable "access_key" {}
variable "secret_key" {}
variable "oss_bucket" {}
variable "region" {}

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  account_id = "${var.account_id}"
  region     = "${var.region}"
}

resource "alicloud_log_project" "example" {
  name        = "fc-log-20180730"
  description = "created by terraform"
}

resource "alicloud_log_store" "example" {
  project = "${alicloud_log_project.example.name}"
  name    = "fc-log-store"
}

resource "alicloud_ram_role" "role" {
  name        = "fc-role"
  services    = ["fc.aliyuncs.com"]
  description = "this is a role test."
  force       = true
}

resource "alicloud_ram_policy" "policy" {
  name = "fc-policy"

  statement = [
    {
      effect = "Allow"
      action = ["log:PostLogStoreLogs"]

      resource = [
        "acs:log:*:*:project/${alicloud_log_project.example.name}/logstore/${alicloud_log_store.example.name}",
      ]
    },
    {
      effect   = "Allow"
      action   = ["oss:Get*"]
      resource = ["acs:oss:*:*:${var.oss_bucket}"]
    },
  ]

  description = "this is a policy test"
  force       = true
}

resource "alicloud_ram_role_policy_attachment" "attach" {
  policy_name = "${alicloud_ram_policy.policy.name}"
  policy_type = "${alicloud_ram_policy.policy.type}"
  role_name   = "${alicloud_ram_role.role.name}"
}

resource "alicloud_fc_service" "foo" {
  name            = "my-fc-service"
  description     = "my fc service for terraform test"
  internet_access = false
  role            = "${alicloud_ram_role.role.arn}"

  log_config = [
    {
      project  = "${alicloud_log_project.example.name}"
      logstore = "${alicloud_log_store.example.name}"
    },
  ]
}

resource "alicloud_fc_function" "foo" {
  service     = "${alicloud_fc_service.foo.name}"
  name        = "hello-world"
  description = "my fc function for terraform test"
  oss_bucket  = "${var.oss_bucket}"
  oss_key     = "function_compute.py.zip"
  memory_size = "512"
  runtime     = "python2.7"
  handler     = "function_compute.handler"
}

resource "alicloud_fc_trigger" "foo" {
  service    = "${alicloud_fc_service.foo.name}"
  function   = "${alicloud_fc_function.foo.name}"
  name       = "hello-trigger"
  type       = "timer"
  source_arn = "test"

  config = <<EOF
    {
        "payload": "aaaaa",
        "cronExpression": "0 0/1 * * * *",
        "enable": true
    }
  EOF
}
