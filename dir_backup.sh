source `dirname -- "$0"`/.env

# 完整備份目錄路徑
TAR_DIR=`dirname -- "$0"`/db_bak_path

# 獲取當前系統時間
DATE=$(date +%Y%m%d%H%M)

# 若TAR_DIR不存在就建立
if [[ ! -e $TAR_DIR ]]; then
    mkdir $TAR_DIR
elif [[ ! -d $TAR_DIR ]]; then
    echo "$TAR_DIR already exists but is not a directory" 1>&2
fi

# 最終保存的備份文件
TAR_BAK="_bak_$HOSTNAME-$DATE.tar"

# 打包為.tar格式
tar -cvf $TAR_DIR/$DIR_BAK_PREFIX$TAR_BAK -C`dirname -- "$DIR_PATH"` `basename -- "$DIR_PATH"`

# 刪除tar備份包 $DAYS 天前的備份文件
find $TAR_DIR/ -mtime +$DAYS -name "*.tar" -exec rm -rf {} \;

rsync -Pav -e ssh $TAR_DIR/$DIR_BAK_PREFIX$TAR_BAK root@$HOST:$TARGET_DIR

exit
