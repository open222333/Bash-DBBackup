from pymongo import MongoClient, ReadPreference
from src.common.src.logger import Log
from src.mongo_tool import parse_exclude_file, mongodump
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-e', '--exclude_file', type=str,
                    default='collections-exclude.txt', help='排除集合檔案列表，以db.name格式一行一個。')
parser.add_argument('-H', '--host', type=str, default='127.0.0.1:27017',
                    help='指定mongo主機，格式為ip:port，預設 127.0.0.1:27017。')
parser.add_argument('-u', '--username', type=str,
                    default=None, help='指定mongo使用者')
parser.add_argument('-p', '--password', type=str,
                    default=None, help='指定mongo密碼')
parser.add_argument('-l', '--log_level', type=str, default='WARNING',
                    help='設定紀錄log等級 DEBUG,INFO,WARNING,ERROR,CRITICAL 預設WARNING')
parser.add_argument('-o', '--output_dir', type=str,
                    default=None, help='指定輸出位置資料夾')
parser.add_argument('-a', '--auth_db', type=str,
                    default=None, help='指定mongo驗證資料庫')
parser.add_argument('-R', '--read_preference', type=str, default='PRIMARY',
                    help='指定mongo讀取模式。有效值:PRIMARY,PRIMARY_PREFERRED,SECONDARY,SECONDARY_PREFERRED,NEAREST')
argv = parser.parse_args()

logger = Log(__name__)
logger.set_file_handler(file_amount=1)
logger.set_msg_handler()
logger.set_level(argv.log_level)

try:
    exclude_file = argv.exclude_file
    host = argv.host
    username = argv.username
    password = argv.password
    output_dir = argv.output_dir
    auth_db = argv.auth_db
except Exception as err:
    logger.error(msg=err, exc_info=True)

if __name__ == '__main__':

    logger.debug(f'MongoDB ReadPreference: {argv.read_preference}')
    if argv.read_preference == 'PRIMARY':
        read_preference = ReadPreference.PRIMARY
    elif argv.read_preference == 'PRIMARY_PREFERRED':
        read_preference = ReadPreference.PRIMARY_PREFERRED
    elif argv.read_preference == 'SECONDARY':
        read_preference = ReadPreference.SECONDARY
    elif argv.read_preference == 'SECONDARY_PREFERRED':
        read_preference = ReadPreference.SECONDARY_PREFERRED
    elif argv.read_preference == 'NEAREST':
        read_preference = ReadPreference.NEAREST

    if username:
        if auth_db:
            client = MongoClient(
                host,
                username=username,
                password=password,
                authSource=auth_db,
                read_preference=read_preference
            )
        else:
            client = MongoClient(
                host,
                username=username,
                password=password,
                read_preference=read_preference
            )
    else:
        client = MongoClient(host, read_preference=read_preference)

    dbs = client.list_database_names()
    exclude_target = parse_exclude_file(file_path=exclude_file)
    for db in dbs:
        logger.info(f'匯出資料庫 {db}')
        if db not in exclude_target.keys():
            mongodump(
                host=host,
                db=db,
                username=username,
                password=password,
                output=output_dir,
                auth_db=auth_db
            )
        else:
            if exclude_target[db] != '*':
                for collection in exclude_target[db]:
                    logger.info(f'排除 {db}.{collection}')
                mongodump(
                    host=host,
                    db=db,
                    username=username,
                    password=password,
                    output=output_dir,
                    exclude_collections=exclude_target[db],
                    auth_db=auth_db
                )
            else:
                logger.info(f'排除 {db} 所有 collection')
