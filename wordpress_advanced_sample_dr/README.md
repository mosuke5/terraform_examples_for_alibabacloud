# Advanced WordPress構築サンプル
## 概要
実践的なWordPress環境のサンプル  
![wordpress](/image/architecture_wordpress_advanced_sample.png)

- SLBの構築
  - リスナーの設定
  - バックエンドサーバの設定
- ECS(WordPress用)の構築
- ECS(踏み台用)の構築
  - NATサーバとしての設定
  - VRouterのルーティングテーブルへの追加
- RDSの構築
- VPCの構築

## 利用方法
基本的に下記の方法で実行可能です。
```
// 事前準備
$ cd wordpress_advanced_sample // 実行したいサンプルへ移動
$ cp terraform.tfvars.sample terraform.tfvars
$ vim terraform.tfvars 
  -> API KEYや公開鍵など必要情報更新

// Dry-Run
$ terraform plan -var-file="terraform.tfvars"

// クラウドへ反映
$ terraform apply -var-file="terraform.tfvars"
(略)
Apply complete! Resources: x added, 0 changed, 0 destroyed.

// 出力にRDSへの接続アドレスや踏み台のEIPのアドレスなどが表示されます
Outputs:
ecs_private_ip = 192.168.1.xx,192.168.1.xx
fumidai_eip = xx.xx.xx.xx
slb_ip = yy.yy.yy.yy
rds_connection_string = xxxxxxxxx.rds.aliyuncs.com

// 踏み台ECSへ接続
$ ssh ecs-user@xx.xx.xx.xx

// WordPress ECSへ接続
$ ssh root@192.168.1.xx

// WordPress ECSの設定
$ wget https://raw.githubusercontent.com/mosuke5/terraform_for_alibabacloud_examples/master/wordpress_advanced_sample/provisioning_wordpress.sh
$ sh provisioning_wordpress.sh
/* このスクリプトで下記を行います
  - ecs-userの作成(パスワードはデフォルトではTest1234)
  - php, apacheのインストール
  - wordpressの配置
  - sshの設定(rootログイン禁止)
*/

// WordPressの設定
$ cd /var/www/html/wordpress
$ sudo cp wp-config-sample.php wp-config.php
$ sudo vim wp-config.php
/** WordPress のためのデータベース名 */
define('DB_NAME', 'database_name_here');

/** MySQL データベースのユーザー名 */
define('DB_USER', 'username_here');

/** MySQL データベースのパスワード */
define('DB_PASSWORD', 'password_here');

/** MySQL のホスト名 */
define('DB_HOST', 'localhost');


define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
```

## 利用開始
設定が完了したらブラウザから接続してみよう。  
`http://<your slb address>/wordpress`
