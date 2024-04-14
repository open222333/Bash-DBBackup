source `dirname -- "$0"`/.env

# 臨時備份目錄
OUT_DIR=`dirname -- "$0"`/db_bak_tmp

# 完整備份目錄路徑
TAR_DIR=`dirname -- "$0"`/db_bak_path

# log檔 存放資料夾
LOG_DIR=`dirname -- "$0"`/logs

# 獲取當前系統時間
DATETIME=$(date +%Y%m%d%H%M)
# 獲取當前系統日期
DATE=$(date +%Y%m%d)

# rsync log 名稱
LOG_NAME="$LOG_DIR/mysql_$DATE.log"

# 若有參數則 依照參數指定DIR_PREFIX
if [[ $1 ]]; then
	DIR_PREFIX=$1
	echo "DIR_PREFIX: $DIR_PREFIX"
else
	# 依照環境變數指定 無指定則使用主機名稱
	if [[ $DIR_PREFIX ]]; then
		echo "DIR_PREFIX: $DIR_PREFIX"
	else
		DIR_PREFIX=$HOSTNAME
		echo "DIR_PREFIX: $DIR_PREFIX"
	fi
fi

# 若OUT_DIR不存在就建立
if [[ ! -e $OUT_DIR ]]; then
    mkdir $OUT_DIR
elif [[ ! -d $OUT_DIR ]]; then
    echo "$OUT_DIR already exists but is not a directory" 1>&2
fi

# 若TAR_DIR不存在就建立
if [[ ! -e $TAR_DIR ]]; then
    mkdir $TAR_DIR
elif [[ ! -d $TAR_DIR ]]; then
    echo "$TAR_DIR already exists but is not a directory" 1>&2
fi

# 若LOG_DIR不存在就建立
if [[ ! -e $LOG_DIR ]]; then
    mkdir $LOG_DIR
elif [[ ! -d $LOG_DIR ]]; then
    echo "$LOG_DIR already exists but is not a directory" 1>&2
fi

# 最終保存的備份文件名稱
TAR_BAK="_bak-mysql-$DATETIME.tar"
TAR_BAK=$DIR_PREFIX$TAR_BAK
echo "TAR_BAK: $TAR_BAK"

# 若無 xtrabackup 工具 則安裝
if ! [[ -x "$(command -v xtrabackup)" ]]; then
	# centos
	/bin/bash `dirname -- "$0"`/src/script/tool_install.sh percona-xtrabackup-24
fi

# 備份全部數據 若有帳密 則執行有帳密的指令
if [[ $MYSQLDB_USER ]]; then
	if [[ $USE_SUDO == 1 ]]; then
		echo $SUDO_PASSWORD | sudo -S xtrabackup --user=$MYSQLDB_USER --password=$MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATETIME
		if [[ $DEBUG == 1 ]]; then
			echo "DEBUG指令: echo SUDO_PASSWORD | sudo -S xtrabackup --user=MYSQLDB_USER --password=$MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATETIME"
		fi
	else
		if [[ $MYSQLDB_ONLY_SCHEMA == 1 ]]; then
			# 若$OUT_DIR/$DATE不存在就建立
			if [[ ! -e $OUT_DIR/$DATETIME ]]; then
				mkdir $OUT_DIR/$DATETIME
			elif [[ ! -d $OUT_DIR/$DATETIME ]]; then
				echo "$OUT_DIR/$DATETIME already exists but is not a directory" 1>&2
			fi

			# 匯出 資料庫結構
			mysqldump -u$MYSQLDB_USER -p$MYSQLDB_PASS --all-databases --no-data > $OUT_DIR/$DATETIME/all-databases-schema-$DATETIME.sql
		else
			if [[ $MYSQLDB_EXCLUDE == 1 ]]; then

				# 取得 排除資料表
				EXCLUDE_TABLES=`tr '\n' ' ' < databases-exclude.txt`;

				xtrabackup --user=$MYSQLDB_USER --password=$MYSQLDB_PASS --databases-exclude="$EXCLUDE_TABLES" --backup --target-dir=$OUT_DIR/$DATETIME
				if [[ $DEBUG == 1 ]]; then
					echo "DEBUG指令: xtrabackup --user=$MYSQLDB_USER --password=MYSQLDB_PASS --databases-exclude=\"$EXCLUDE_TABLES\" --backup --target-dir=$OUT_DIR/$DATETIME"
				fi

				# 匯出 資料庫結構
				mysqldump -u$MYSQLDB_USER -p$MYSQLDB_PASS --all-databases --no-data > $OUT_DIR/$DATETIME/all-databases-schema-$DATETIME.sql
			else
				xtrabackup --user=$MYSQLDB_USER --password=$MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATETIME
				if [[ $DEBUG == 1 ]]; then
					echo "DEBUG指令: xtrabackup --user=$MYSQLDB_USER --password=MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATETIME"
				fi
			fi
		fi
	fi
else
	echo "需要帳號密碼"
fi

# 打包為.tar格式
tar -cvf $TAR_DIR/$TAR_BAK -C$OUT_DIR $DATETIME

# 刪除暫存
if [[ -e $OUT_DIR/$DATETIME ]]
then
	echo "remove $OUT_DIR/$DATETIME" 1>&2
    rm -rf $OUT_DIR/$DATETIME
else
	echo "no $OUT_DIR/$DATETIME"
fi

# 刪除tar備份包$DAYS天前的備份文件
if [[ $KEEP_DAYS ]]; then
	find $TAR_DIR/ -mtime +$KEEP_DAYS -name "*.tar" -exec rm -rf {} \;
fi

# 使用key
if [[ $USE_KEY ]]; then
	if [[ $USE_KEY == 1 ]]; then
		if [[ ! -e $HOME/.ssh/$KEY_NAME ]]; then
			/bin/bash `dirname -- "$0"`/src/script/generate_ssh_key.sh
		fi
	fi
fi

if [[ $UPLOAD && $UPLOAD == 1 ]]; then
	# 自動
	if [[ $AUTO_PASSWORD && $AUTO_PASSWORD == 1 ]]; then
		if ! [[ -x "$(command -v sshpass)" ]]; then
			/bin/bash `dirname -- "$0"`/src/script/tool_install.sh sshpass
		fi
		if [[ $RSYNC_LOG && $RSYNC_LOG == 1 ]]; then
			rsync -Pav --temp-dir=/tmp --remove-source-files -e "sshpass -p$HOST_PASSWORD ssh" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH  --log-file=$LOG_NAME

			if [[ $DEBUG && $DEBUG == 1 ]]; then
				echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e \"sshpass -pHOST_PASSWORD ssh\" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH" --log-file=$LOG_NAME
			fi
		else
			rsync -Pav --temp-dir=/tmp --remove-source-files -e "sshpass -p$HOST_PASSWORD ssh" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH

			if [[ $DEBUG && $DEBUG == 1 ]]; then
				echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e \"sshpass -pHOST_PASSWORD ssh\" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
			fi
		fi
	else
		if [[ $RSYNC_LOG && $RSYNC_LOG == 1 ]]; then
			rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH --log-file=$LOG_NAME

			if [[ $DEBUG && $DEBUG == 1 ]]; then
				echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH --log-file=$LOG_NAME"
			fi
		else
			rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH

			if [[ $DEBUG && $DEBUG == 1 ]]; then
				echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
			fi
		fi
	fi
fi

# 執行 刪除超過天數的log檔
if [[ $RSYNC_LOG && $RSYNC_LOG == 1 ]]; then
	source remove_log.sh
fi

exit
