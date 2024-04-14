#!/bin/bash

# 依照環境變數指定 保留天數 無指定則 3 天
if [[ $RSYNC_LOG_DAYS_TO_KEEP ]]; then
	DAYS_TO_KEEP=$RSYNC_LOG_DAYS_TO_KEEP
else
	DAYS_TO_KEEP=3
fi
echo "保留天數: $DAYS_TO_KEEP"

# 依照環境變數指定 日誌文件目錄 無指定則 logs
if [[ $RSYNC_LOG_DIR ]]; then
	LOG_DIR=$RSYNC_LOG_DIR
else
	LOG_DIR="logs"
fi
echo "日誌文件目錄: $LOG_DIR"

# 判斷日誌文件目錄是否存在
if [ -d "$LOG_DIR" ]; then
    # 進入日誌文件目錄
    cd "$LOG_DIR" || exit

    # 刪除超過保留天數的日誌文件
    find . -name "*.log" -mtime +$DAYS_TO_KEEP -exec rm {} \;

    echo "已刪除超過 $DAYS_TO_KEEP 天的日誌文件"
else
    echo "日誌文件目錄 $LOG_DIR 不存在"
fi
