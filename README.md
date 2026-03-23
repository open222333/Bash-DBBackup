# Bash-DBBackup

資料庫與資料夾備份腳本集合，支援 MongoDB、MySQL 備份打包，以及 Python 腳本進行細粒度的 MongoDB 備份（支援排除指定集合）。備份結果為 `.tar` 檔，可選擇性上傳到遠端主機並自動清理舊備份。

---

## 目錄結構

```
Bash-DBBackup/
├── conf/
│   └── .env                        # 環境變數設定（從 .env.default 複製）
├── src/
│   └── script/
│       └── dir_backup.sh           # 資料夾打包備份
├── logs/                           # 備份 log 輸出目錄
├── mongo_backup.sh                 # MongoDB mongodump + tar 打包
├── mysql_backup.sh                 # MySQL mysqldump + tar 打包
├── mongodump.py                    # Python MongoDB 備份（支援排除集合）
├── mongodump27.py                  # 同上，相容 MongoDB 2.7 版本
├── collections-exclude.txt         # mongodump.py 排除集合清單
├── databases-exclude.txt.default   # mysql 排除資料表清單範本
└── requirements.txt                # Python 依賴套件
```

---

## 腳本說明

### mongo_backup.sh

使用 `mongodump` 備份 MongoDB，並將結果打包為 `.tar` 檔案。

- 備份檔名格式：`{DIR_PREFIX}_bak-mongo-{DATE}.tar`
- 日期格式：`YYYYMMDDHHMM`

### mysql_backup.sh

使用 `mysqldump` 備份 MySQL，並將結果打包為 `.tar` 檔案。

- 備份檔名格式：`{DIR_PREFIX}_bak-mysql-{DATE}.tar`
- 支援透過 `databases-exclude.txt` 排除指定資料表（`MYSQLDB_EXCLUDE_TABLES=1`）

### src/script/dir_backup.sh

將指定目錄打包為 `.tar` 檔案。

- 備份檔名格式：`{DIR_PREFIX}_bak-{TYPE}-{DATE}.tar`
- 支援透過指令參數覆蓋 `.env` 設定

### mongodump.py / mongodump27.py

Python 版 MongoDB 備份腳本，支援透過檔案指定排除集合。

- `mongodump.py`：適用 MongoDB 3.x 以上
- `mongodump27.py`：相容 MongoDB 2.7 版本，用法相同

---

## 執行流程

```
執行備份腳本
  ├── 讀取 conf/.env 環境變數
  ├── 執行 mongodump / mysqldump / tar
  ├── 打包輸出 .tar 檔案
  ├── [UPLOAD=1] 使用 scp/rsync 上傳到目標主機
  └── [KEEP_DAYS 已設定] 刪除超過 N 天的備份檔
```

---

## 使用方法

### 步驟一：設定環境變數

```bash
cp conf/.env.default conf/.env
# 編輯 conf/.env，填入對應的帳密與設定
```

### 步驟二：執行備份

```bash
# 資料夾備份（指令參數可覆蓋 .env 設定）
sh src/script/dir_backup.sh [(可選) DIR_PATH] [(可選) DIR_PREFIX] [(可選) TYPE]

# MongoDB 備份
sh mongo_backup.sh [(可選) DIR_PREFIX]

# MySQL 備份
sh mysql_backup.sh [(可選) DIR_PREFIX]
```

### Python 版 MongoDB 備份

```bash
pip install -r requirements.txt

python mongodump.py [-h] [-e EXCLUDE_FILE] [-H HOST] [-u USERNAME] \
                    [-p PASSWORD] [-l LOG_LEVEL] [-o OUTPUT_DIR] \
                    [-a AUTH_DB] [-R READ_PREFERENCE]

# 範例：排除指定集合並輸出至 /tmp/backup
python mongodump.py -e collections-exclude.txt -H 127.0.0.1:27017 \
                    -u admin -p secret -o /tmp/backup -a admin
```

#### 參數說明

| 參數 | 說明 |
|------|------|
| `-e EXCLUDE_FILE` | 排除集合清單檔案，格式為 `db.collection`，一行一個 |
| `-H HOST` | MongoDB 主機，格式 `ip:port`，預設 `127.0.0.1:27017` |
| `-u USERNAME` | MongoDB 使用者名稱 |
| `-p PASSWORD` | MongoDB 密碼 |
| `-l LOG_LEVEL` | log 等級：`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`，預設 `WARNING` |
| `-o OUTPUT_DIR` | 備份輸出目錄 |
| `-a AUTH_DB` | 身份驗證資料庫 |
| `-R READ_PREFERENCE` | 讀取模式：`PRIMARY`, `PRIMARY_PREFERRED`, `SECONDARY`, `SECONDARY_PREFERRED`, `NEAREST` |

---

## 環境變數說明（conf/.env）

```ini
# MongoDB 連線設定
MONGODB_HOST=
MONGODB_PORT=
MONGODB_USER=
MONGODB_PASS=
MONGODB_AUTHDB=        # 身份驗證資料庫

# MySQL 設定
MYSQLDB_USER=
MYSQLDB_PASS=
MYSQLDB_EXCLUDE_TABLES= # 設為 1 啟用排除資料表功能（搭配 databases-exclude.txt）

# 資料夾備份設定
DIR_PREFIX=            # 備份檔名前綴（預設為主機名稱）
DIR_PATH=              # 備份目標路徑
TYPE=                  # 備份類型標記（預設為資料夾名稱）

# 遠端上傳設定
HOST=                  # 目標主機 IP
HOST_PASSWORD=         # 目標主機密碼
TARGET_PATH=           # 目標主機存放路徑

# 上傳控制
AUTO_PASSWORD=         # 設為 1 啟用自動密碼輸入（使用 sshpass）
UPLOAD=                # 設為 1 啟用上傳
KEEP_DAYS=             # 保留天數，超過則刪除；未設定則不刪除

# SSH Key 設定（USE_KEY=1 時啟用）
USE_KEY=
KEY_NAME=
KEY_TARGET_HOST=

# 系統設定
USE_SUDO=              # 設為 1 使用 sudo 安裝套件
SUDO_PASSWORD=         # sudo 使用者密碼
DEBUG=                 # 設為 1 顯示詳細指令訊息（除錯用）
LOG_LEVEL=             # log 等級，預設 WARNING
```

---

## 注意事項

- `conf/.env` 包含敏感資訊（帳密），請勿提交至版本控制。
- `databases-exclude.txt` 中排除的資料表格式為 `dbname.tablename`，一行一個，不可有空行。
- `collections-exclude.txt` 中排除的集合格式為 `db.collection`，一行一個。
- 使用 `AUTO_PASSWORD=1` 需確保目標主機已安裝 `sshpass`。
- `KEEP_DAYS` 未設定時不會自動刪除舊備份，請定期手動清理或設定此值。
- `mongodump27.py` 僅適用於 MongoDB 2.7 版本環境，勿混用。
- 建議在 crontab 中搭配絕對路徑執行，避免環境變數找不到問題。
