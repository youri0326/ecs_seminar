#!/bin/bash
# ==========================================================
# 第3章：演習の準備
# ==========================================================
# ------------------------------
# 3-5. AWS CLIのインストール
# ------------------------------
# ①AWS CLIのインストール
#公式サイトからインストーラーのダウンロード
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

#解凍用のzipコマンドのインストール
sudo apt install unzip

#zipファイルの解凍
unzip awscliv2.zip

#CLIのインストール
sudo ./aws/install

#インストールの確認
aws --version

#④AWS CLIでAWSへログイン
aws configure


# ==========================================================
# 第4章：CloudFormationでインフラ環境準備
# ==========================================================
# ------------------------------
# ① 環境変数の設定
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="（ここに苗字を入力してください）" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

# ------------------------------
# ② 作業ディレクトリの移動
# ------------------------------
cd /mnt/c/ecs_seminar/cloudformation

# ------------------------------
# ③ CloudFormationでインフラ環境構築
# ------------------------------
aws cloudformation deploy \
  --template-file ecs-seminar.yaml \
  --stack-name ecs-seminar-stack-${USER_NAME} \
  --parameter-overrides UserName=${USER_NAME} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ${REGION}






# ==========================================================
# 第5章：ECSでWebアプリのDocker環境構築
# ==========================================================
# ------------------------------
# 5-1. 演習1. ECRの環境準備
# ------------------------------
# ------------------------------
# ⓪事前準備
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="（ここに苗字を入力してください）" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

#アカウントIDの指定
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

#作成するECR名の登録
PHP_REPO_NAME="php-${USER_NAME}"
PMA_REPO_NAME="phpmyadmin-${USER_NAME}" 

# ECRへのログイン
aws ecr get-login-password --region ${REGION} | \
docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

#作業ディレクトリへ移動
cd /mnt/c/ecs_seminar

# ------------------------------
# ① ECRの作成
# ------------------------------
# PHP専用のECRを作成する
aws ecr create-repository --repository-name ${PHP_REPO_NAME} --region ${REGION}

# phpMyAdmin専用のECRを作成する
aws ecr create-repository --repository-name ${PMA_REPO_NAME} --region ${REGION}

# ------------------------------
# ② イメージのプル
# ------------------------------
#phpMyAdminイメージのプル
docker pull phpmyadmin/phpmyadmin:5.2.1

# ==========================================================
# ③ PHPイメージの作成
# ==========================================================
cd /mnt/c/ecs_seminar

docker build -t php .

# ------------------------------
# ④ イメージのプッシュ
# ------------------------------
# phpMyAminイメージをECRへタグ付け
docker tag phpmyadmin/phpmyadmin:5.2.1 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

# phpMyAdminイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

#PHPイメージをECRへタグ付け
docker tag php ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_REPO_NAME}

#PHPイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_REPO_NAME}

# ------------------------------
# 5-2. 演習2. ECSの作成と実行
# ------------------------------
# ------------------------------
# ⓪事前準備
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="（ここに苗字を入力してください）" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

#アカウントIDの確認
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo ${ACCOUNT_ID}

#作業ディレクトリの移動　※不要
cd /mnt/c/ecs_seminar

# ------------------------------
# ②タスク定義の作成
# ------------------------------
#ECSのロールの作成
aws iam create-role \
  --role-name ecsTaskExecutionRole-${USER_NAME} \
  --assume-role-policy-document file://ecs-task/iam-role-ecs-policy.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole-${USER_NAME} \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam list-attached-role-policies --role-name ecsTaskExecutionRole-${USER_NAME}

