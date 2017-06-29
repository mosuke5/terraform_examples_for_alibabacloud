# Alibaba CloudのTerraformサンプル集
## はじめに
- 本レポジトリは[Alibaba Cloud](https://jp.aliyun.com)で利用できるTerraformのサンプル集です。
- Alibaba CloudではTerraformの[プラグイン](https://github.com/alibaba/terraform-provider)を提供しています。こちらを一緒に利用してください。
- `terraform.tfbars`をお使いの環境の設定に変更することで基本的に動作可能です
- もしうまく動作しないや、ご要望あればIssueないしはPull requestしてください。

## 実行方法
基本的に下記の方法で実行可能です。
```
// 事前準備
$ cd baisc_sample // 実行したいサンプルへ移動
$ cp terraform.tfvars.sample terraform.tfvars
$ vim terraform.tfvars // API KEYなど必要情報更新

// Dry-Run
$ terraform plan -var-file="terraform.tfvars"

// クラウドへ反映
$ terraform apply -var-file="terraform.tfvars"

// 反映をデバッグログ残して実行したい
$ TF_LOG=TRACE TF_LOG_PATH=./terraform.log terraform apply -var-file="terraform.tfvars"

// 環境削除
$ terraform destroy -var-file="terraform.tfvars"
```

## サンプル一覧
- [ベーシックサンプル](/basic_sample/)
- [ベーシックサンプル(Ansible利用)](/basic_sample_with_ansible/)
- [SLBサンプル](/slb_sample/)
- [RDSサンプル](/slb_sample/)
- [AutoScalingサンプル](/autoscaling_sample/)
- [mongoDBクラスターサンプル](/mongo_cluster_sample/)
- [WordPressサンプル](/wordpress_sample/)
