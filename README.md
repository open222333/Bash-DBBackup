# Bash-SQL_Backup

```
輸出tar檔至db_bak_path
```

## 步驟

1. 複製 .env.default 成 .env, 填入環境變數

2. 執行指令

# 指令

```bash
# 資料夾 備份打包
# 名稱 {$DIR_PREFIX}_bak-{$TYPE}-{DATE=$(date +%Y%m%d%H%M)}.tar
sh path_to_dir/dir_backup.sh [(可選) DIR_PATH] [(可選) DIR_PREFIX] [(可選) TYPE]

# mongo 備份打包
# 名稱 {$DIR_PREFIX}_bak-mongo-{DATE=$(date +%Y%m%d%H%M)}.tar
sh path_to_dir/mongo_backup.sh [(可選) DIR_PREFIX]

# mysql 備份打包
# 名稱 {$DIR_PREFIX}_bak-mysql-{DATE=$(date +%Y%m%d%H%M)}.tar
sh path_to_dir/mysql_backup.sh [(可選) DIR_PREFIX]
```

# 環境變數說明

```
# mongo帳密 資料庫主機ip PORT號(預設27017)
MONGODB_HOST=
MONGODB_PORT=
MONGODB_USER=
MONGODB_PASS=
# 指定的身份驗證數據庫
MONGODB_AUTHDB=

# mysql帳密
MYSQLDB_USER=
MYSQLDB_PASS=

# 名稱 {$DIR_PREFIX}_bak-{$TYPE}-{DATE=$(date +%Y%m%d%H%M)}.tar
# dir_backup tar檔名前綴(指令參數優先 預設為主機名稱) 目標路徑(指令參數優先) TYPE(指令參數優先 預設為資料夾名稱)
DIR_PREFIX=
DIR_PATH=
TYPE=

# 備份 目標主機 ip 以及 路徑
HOST=
HOST_PASSWORD=
TARGET_PATH=

# 是否使用自動使用密碼 若為1則啟用
AUTO_PASSWORD=
# 是否執行同步 若為1則啟用
UPLOAD=
# 刪除幾天前的備份，即只保留近幾天的備份 未指定則關閉
KEEP_DAYS=
# 若USE_KEY為1則啟用 指定key名稱 目標host
USE_KEY=
KEY_NAME=
KEY_TARGET_HOST=
# 使用sudo安裝套件 若為1則啟用
USE_SUDO=
# 顯示指令訊息 進行排錯 若為1則啟用
DEBUG=
```