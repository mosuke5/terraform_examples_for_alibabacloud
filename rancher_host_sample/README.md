# ベーシックWordPress構築サンプル
## 概要
ECSとRDSを利用したベーシックなWordPress環境のサンプル。  
![wordpress](/image/architecture_wordpress_sample.png)

## 利用方法
基本的に下記の方法で実行可能です。
```
// 事前準備
$ cd wordpress_sample // 実行したいサンプルへ移動
$ cp terraform.tfvars.sample terraform.tfvars
$ vim terraform.tfvars 
  -> API KEYや公開鍵など必要情報更新

// Dry-Run
$ terraform plan -var-file="terraform.tfvars"

// クラウドへ反映
$ terraform apply -var-file="terraform.tfvars"
(略)
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

// 出力にRDSへの接続アドレスとEIPのアドレスが表示されます
Outputs:
rds_connection_string = xxxxxxxxx.rds.aliyuncs.com
wordpress_eip = xx.xx.xx.xx

// ECSへ接続
$ ssh ecs-user@xx.xx.xx.xx

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
`http://<your eip address>/wordpress`

## ECSへのセットアップ内容
ECSへは下記の設定が行われます。
- Apacheのインストール
- PHPのインストール
- WordPressソースコードの配置
- `ecs-user`の作成
  - `ecs-user`のsudoersへの追加
  - terraform.tfvarsで指定した公開鍵の配置
- sshdはパスワード認証、rootログインの禁止
