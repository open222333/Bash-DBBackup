# Bash-SQL_Backup

```
輸出tar檔至db_bak_path
```

## 步驟

1. 複製 .env.default 成 .env, 填入環境變數

2. 執行指令

# 指令

```bash
# 打包備份資料夾
sh path_to_dir/dir_backup.sh [可選 DIR_PATH] [可選 DIR_PREFIX] [可選 TYPE]

# mongo備份打包
sh path_to_dir/mongo_backup.sh

# mysql備份打包
sh path_to_dir/mysql_backup.sh
```

# 環境變數說明

```env
# 備份 資料庫主機 ip
DB_HOST=

# mongo帳密 PORT號(預設值27017)
MONGODB_USER=
MONGODB_PASS=
MONGODB_PORT=

# mysql帳密
MYSQLDB_USER=
MYSQLDB_PASS=

# 名稱
# dir_backup tar檔名前綴(參數優先 預設為主機名稱) 目標路徑(參數優先) TYPE(參數優先)預設為資料夾名稱
DIR_PREFIX=
DIR_PATH=
TYPE=

# 備份 目標主機 ip 以及 路徑
HOST=
HOST_PASSWORD=
TARGET_PATH=

# 若為1則啟用
AUTO_PASSWORD=
USE_KEY=
UPLOAD=
# 刪除幾天前的備份，即只保留近幾天的備份 未指定則關閉
KEEP_DAYS=
# 指定key名稱 目標host
KEY_NAME=
KEY_TARGET_HOST=
```