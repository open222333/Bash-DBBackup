from src import LOG_LEVEL
from src.common.src.logger import Log
import os
import re

logger = Log('mongo_tool')
logger.set_level(LOG_LEVEL)
logger.set_msg_handler()


def parse_exclude_file(file_path: str):
    """解析紀錄需排除集合的文檔

    Args:
        file_path (str, optional): 檔案位置.

    Returns:
        dict: {dbname:[collection1, collection2...]}
    """
    result = {}
    logger.info('解析 {} 中'.format(file_path))

    full_collection_pattern = re.compile(
        r'(?P<database>\w+)\.(?P<collection>\w+)')

    try:
        with open(file_path, 'r') as f:
            items = f.read().split('\n')
            for item in items:
                if item != '':
                    m = re.search(full_collection_pattern, item)
                    if m:
                        database = m.group('database')
                        collection = m.group('collection')
                    else:
                        database = item
                        collection = '*'

                    if database not in result.keys():
                        if collection != '*':
                            result[database] = [collection]
                        else:
                            result[database] = collection
                    else:
                        if collection != '*':
                            result[database].append(collection)
                        else:
                            result[database] = collection
        logger.info('解析 {} 完成'.format(file_path))
    except Exception as err:
        logger.error('解析 {} 失敗: {}'.format(file_path, err), exc_info=True)
    return result


def mongodump(host: str, db: str, output: str = None, exclude_databases: list = None, exclude_collections: list = None, **args):
    """mongo匯出至指定資料夾

    Args:
        host (str): mongodb主機 ip:port
        db (str): 資料庫名稱
        output (str, optional): 指定輸出位置. Defaults to None.
        exclude_collections (list, optional): 必須指定資料庫,需排除的集合. Defaults to None.
        exclude_databases (list, optional): 需排除的資料庫. Defaults to None.
        collection (str, optional): 集合(collection)名稱 None則匯出全部. Defaults to None.
        username (str, optional): 使用者名稱. Defaults to None.
        password (str, optional): 使用者密碼. Defaults to None.
        auth_db (str, optional): 使用者驗證資料庫. Defaults to None.

    Returns:
        _type_: _description_
    """
    if not output:
        output = 'mongo_backup'

    if not os.path.exists(output):
        os.makedirs(output)

    command = 'mongodump -h {} -d {} -o {}'.format(host, db, output)

    if exclude_collections:
        for c in exclude_collections:
            command += ' --excludeCollection={}'.format(c)

    if exclude_databases:
        for d in exclude_databases:
            command += ' --excludeDatabase={}'.format(d)

    if 'username' in args.keys() and args["username"] != None:
        command += f' -u {args["username"]}'

    if 'password' in args.keys() and args["password"] != None:
        command += f' -p {args["password"]}'

    if 'collection' in args.keys() and args["collection"] != None:
        command += f' -c {args["collection"]}'

    if 'auth_db' in args.keys() and args["auth_db"] != None:
        command += f' --authenticationDatabase {args["auth_db"]}'

    logger.debug(f'匯出指令:{command}')
    os.system(command)
