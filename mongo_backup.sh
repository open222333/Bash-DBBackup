source `dirname -- "$0"`/.env

# 臨時備份目錄
OUT_DIR=`dirname -- "$0"`/db_bak_tmp

# 完整備份目錄路徑
TAR_DIR=`dirname -- "$0"`/db_bak_path

# 獲取當前系統時間
DATE=$(date +%Y%m%d%H%M)

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

# 最終保存的備份文件名稱
TAR_BAK="_bak-mongo-$DATE.tar"
TAR_BAK=$DIR_PREFIX$TAR_BAK
echo "TAR_BAK: $TAR_BAK"

if [[ ! $MONGODB_PORT ]]; then
	MONGODB_PORT=27017
fi

if [[ ! $MONGODB_AUTHDB ]]; then
	MONGODB_AUTHDB=admin
fi

# 若無 mongodump 工具 則安裝
if ! [[ -x "$(command -v mongodump)" ]]; then
	# centos
	wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel70-x86_64-100.6.1.rpm
	/bin/bash `dirname -- "$0"`/tool_install.sh mongodump `dirname -- "$0"`/mongodb-database-tools-rhel70-x86_64-100.6.1.rpm
fi

# 備份全部數據 若有帳密 則執行有帳密的指令
if [[ $MONGODB_USER ]]; then
	if [[ $MONDB_EXCLUDE_COLLECTIONS == 1 ]]; then
		# 取得 排除資料表
		EXCLUDE_COLLECTIONS=`tr '\n' ' ' < collections-exclude.txt`;
	else
		mongodump -h $MONGODB_HOST:$MONGODB_PORT -u $MONGODB_USER -p $MONGODB_PASS --authenticationDatabase $MONGODB_AUTHDB -o $OUT_DIR/$DATE
		if [[ $DEBUG == 1 ]]; then
			echo "DEBUG指令: mongodump -h $MYSQLDB_HOST:$MONGODB_PORT -u $MONGODB_USER -p MONGODB_PASS --authenticationDatabase $MONGODB_AUTHDB -o $OUT_DIR/$DATE"
		fi
	fi
else
	if [[ $MONDB_EXCLUDE_COLLECTIONS == 1 ]]; then
		# 取得 排除資料表
		EXCLUDE_COLLECTIONS=`tr '\n' ' ' < collections-exclude.txt`;
	else
		mongodump -h $MONGODB_HOST:$MONGODB_PORT -o $OUT_DIR/$DATE
		if [[ $DEBUG == 1 ]]; then
			echo "DEBUG指令: mongodump -h $MYSQLDB_HOST:$MONGODB_PORT -o $OUT_DIR/$DATE"
		fi
	fi
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
if [[ $KEEP_DAYS ]]; then
	find $TAR_DIR/ -mtime +$KEEP_DAYS -name "*.tar" -exec rm -rf {} \;
fi

# 使用key
if [[ $USE_KEY ]]; then
	if [[ $USE_KEY == 1 ]]; then
		if [[ ! -e $HOME/.ssh/$KEY_NAME ]]; then
			/bin/bash `dirname -- "$0"`/generate_ssh_key.sh
		fi
	fi
fi

if [[ $UPLOAD ]]; then
	if [[ $UPLOAD == 1 ]]; then
		# 自動
		if [[ $AUTO_PASSWORD ]]; then
			if [[ $AUTO_PASSWORD == 1 ]]; then
				if ! [[ -x "$(command -v sshpass)" ]]; then
					/bin/bash `dirname -- "$0"`/tool_install.sh sshpass
				fi
				rsync -Pav --temp-dir=/tmp --remove-source-files -e "sshpass -p$HOST_PASSWORD ssh" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH
				if [[ $DEBUG == 1 ]]; then
					echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e \"sshpass -pHOST_PASSWORD ssh\" $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
				fi
			else
				rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH
				if [[ $DEBUG == 1 ]]; then
					echo "DEBUG指令: rsync -Pav --temp-dir=/tmp --remove-source-files -e ssh $TAR_DIR/$TAR_BAK root@$HOST:$TARGET_PATH"
				fi
			fi
		fi
	fi
fi

exit
