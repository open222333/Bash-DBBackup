source `dirname -- "$0"`/.env

# 完整備份目錄路徑
TAR_DIR=`dirname -- "$0"`/db_bak_path

# 獲取當前系統時間
DATE=$(date +%Y%m%d%H%M)

# 若有參數則 依照參數指定DIR_PATH
if [[ $1 ]]; then
	DIR_PATH=$1
	echo "DIR_PATH: $DIR_PATH"
else
	# 依照環境變數指定DIR_PATH
	if [[ $DIR_PATH ]]; then
		echo "DIR_PATH: $DIR_PATH"
	else
		echo "error: no DIR_PATH"
	fi
fi

# 若有參數則 依照參數指定DIR_PREFIX
if [[ $2 ]]; then
	DIR_PREFIX=$2
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

# 若有參數則 依照參數指定TYPE
if [[ $3 ]]; then
	TYPE=$3
	echo "TYPE: $TYPE"
else
	# 依照環境變數指定
	# 若TYPE無指定 則為資料夾名稱
	if [[ ! $TYPE ]]; then
		TYPE=`basename -- "$TYPE"`
		echo "TYPE: $TYPE"
	fi
fi

# 若TAR_DIR不存在就建立
if [[ ! -e $TAR_DIR ]]; then
    mkdir $TAR_DIR
elif [[ ! -d $TAR_DIR ]]; then
    echo "$TAR_DIR already exists but is not a directory" 1>&2
fi

# 最終保存的備份文件名稱
TAR_BAK="_bak-$TYPE-$DATE.tar"
TAR_BAK=$DIR_PREFIX$TAR_BAK
echo "TAR_BAK: $TAR_BAK"

# 打包為.tar格式
tar -cvf $TAR_DIR/$TAR_BAK -C`dirname -- "$DIR_PATH"` `basename -- "$DIR_PATH"`

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

# 自動
if [[ $UPLOAD ]]; then
	if [[ $UPLOAD == 1 ]]; then
		if [[ $AUTO_PASSWORD ]]; then
			if [[ $AUTO_PASSWORD == 1 ]]; then
				if ! [[ -x "$(command -v sshpass)" ]]; then
					/bin/bash `dirname -- "$0"`/src/script/tool_install.sh sshpass
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
