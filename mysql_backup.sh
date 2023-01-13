source `dirname -- "$0"`/.env

# 臨時備份目錄
OUT_DIR=`dirname -- "$0"`/db_bak_tmp

# 完整備份目錄路徑
TAR_DIR=`dirname -- "$0"`/db_bak_path

# 獲取當前系統時間
DATE=$(date +%Y%m%d%H%M)

# 若有參數則 依照參數指定DIR_PREFIX
if [ $1 ]; then
	DIR_PREFIX=$1
	echo "DIR_PREFIX: $DIR_PREFIX"
else
	# 依照環境變數指定 無指定則使用主機名稱
	if [ $DIR_PREFIX ]; then
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

# 最終保存的備份文件名稱
TAR_BAK="_bak-mysql-$DATE.tar"
TAR_BAK=$DIR_PREFIX$TAR_BAK
echo "TAR_BAK: $TAR_BAK"

# 若無 xtrabackup 工具 則安裝
if ! [ -x "$(command -v xtrabackup)" ]; then
	# centos
	sh `dirname -- "$0"`/tool_install.sh percona-xtrabackup-24
fi

# 備份全部數據 若有帳密 則執行有帳密的指令
if [ $MYSQLDB_USER ]; then
	xtrabackup --user=$MYSQLDB_USER --password=$MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATE
	if [ $DEBUG == 1 ]; then
		echo "xtrabackup --user=$MYSQLDB_USER --password=$MYSQLDB_PASS --backup --target-dir=$OUT_DIR/$DATE"
	fi
else
	echo "MySQL需要帳號密碼"
fi

# 打包為.tar格式
tar -cvf $TAR_DIR/$TAR_BAK -C$OUT_DIR $DATE

# 刪除暫存
if [[ -e $OUT_DIR/$DATE ]]
then
	echo "remove $OUT_DIR/$DATE" 1>&2
    rm -rf $OUT_DIR/$DATE
else
	echo "no $OUT_DIR/$DATE"
fi

# 刪除tar備份包$DAYS天前的備份文件
if [ $KEEP_DAYS ]; then
	find $TAR_DIR/ -mtime +$KEEP_DAYS -name "*.tar" -exec rm -rf {} \;
fi

# 使用key
if [ $USE_KEY ]; then
	if [ $USE_KEY == 1 ]; then
		if [[ ! -e $HOME/.ssh/$KEY_NAME ]]; then
			sh `dirname -- "$0"`/generate_ssh_key.sh
		fi
	fi
fi

if [ $UPLOAD ]; then
	if [ $UPLOAD == 1 ]; then
		# 自動
		if [ $AUTO_PASSWORD ]; then
			if [ $AUTO_PASSWORD == 1 ]; then
				if ! [ -x "$(command -v sshpass)" ]; then
					sh `dirname -- "$0"`/tool_install.sh sshpass
				fi
				rsync -Pav --temp-dir=/tmp --remove-source-files -e "sshpass -p$HOST_PASSWORD ssh" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH

				if [ $DEBUG == 1 ]; then
					echo "rsync -Pav --temp-dir=/tmp --remove-source-files -e \"sshpass -p$HOST_PASSWORD ssh\" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
				fi
			else
				rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH
				if [ $DEBUG == 1 ]; then
					echo "rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
				fi
			fi
		fi
	fi
fi

exit
