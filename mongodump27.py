# -*- coding: UTF-8 -*-
from logging.handlers import TimedRotatingFileHandler, RotatingFileHandler
from pymongo import MongoClient, ReadPreference
from datetime import datetime
import argparse
import logging
import os
import re


class Log():

    def __init__(self, log_name):
        self.log_name = log_name
        self.logger = logging.getLogger(log_name)
        self.logger.setLevel(logging.WARNING)

        # 當前日期
        self.now_time = datetime.now().__format__('%Y-%m-%d')

        self.log_path = 'logs'
        if not os.path.exists(self.log_path):
            os.makedirs(self.log_path)

        self.log_file = os.path.join(
            self.log_path, '{}-all.log'.format(log_name))
        self.formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    def set_log_path(self, log_path):
        """設置log檔存放位置

        Args:
            log_path (str): 路徑 預設為 logs
        """
        self.log_path = log_path
        if not os.path.exists(self.log_path):
            os.makedirs(self.log_path)

    def set_log_file_name(self, name):
        """設置log檔名稱 預設為 {log_name}-all.log

        Args:
            name (str): _description_
        """
        self.log_file = os.path.join(self.log_path, name)

    def set_date_handler(self, days=7):
        """設置每日log檔

        Args:
            log_file (_type_): log檔名
            days (int, optional): 保留天數. Defaults to 7.

        Returns:
            TimedRotatingFileHandler: _description_
        """
        self.log_file = os.path.join(
            self.log_path, '{}-{}.log'.format(self.log_name, self.now_time))
        handler = TimedRotatingFileHandler(
            self.log_file, when='D', backupCount=days)
        handler.setFormatter(self.formatter)
        self.logger.addHandler(handler)

    def set_file_handler(self, size=1 * 1024 * 1024, file_amount=5):
        """設置log檔案大小限制

        Args:
            log_file (_type_): log檔名
            size (int, optional): 檔案大小. Defaults to 1*1024*1024 (1M).
            file_amount (int, optional): 檔案數量. Defaults to 5.

        Returns:
            RotatingFileHandler: _description_
        """
        handler = RotatingFileHandler(
            self.log_file, maxBytes=size, backupCount=file_amount)
        handler.setFormatter(self.formatter)
        self.logger.addHandler(handler)

    def set_msg_handler(self):
        """設置log steam

        Returns:
            logging.StreamHandler: _description_
        """
        handler = logging.StreamHandler()
        handler.setFormatter(self.formatter)
        self.logger.addHandler(handler)

    def set_log_formatter(self, formatter):
        """設置log格式 formatter

        %(asctime)s - %(name)s - %(levelname)s - %(message)s

        Args:
            formatter (str): log格式.
        """
        self.formatter = formatter

    def set_level(self, level='WARNING'):
        """設置log等級

        Args:
            level (str): 設定紀錄log等級 DEBUG,INFO,WARNING,ERROR,CRITICAL 預設WARNING
        """
        if level == 'DEBUG':
            self.logger.setLevel(logging.DEBUG)
        elif level == 'INFO':
            self.logger.setLevel(logging.INFO)
        elif level == 'WARNING':
            self.logger.setLevel(logging.WARNING)
        elif level == 'ERROR':
            self.logger.setLevel(logging.ERROR)
        elif level == 'CRITICAL':
            self.logger.setLevel(logging.CRITICAL)

    def debug(self, message, exc_info=False):
        self.logger.debug(message, exc_info=exc_info)

    def info(self, message, exc_info=False):
        self.logger.info(message, exc_info=exc_info)

    def warning(self, message, exc_info=False):
        self.logger.warning(message, exc_info=exc_info)

    def error(self, message, exc_info=False):
        self.logger.error(message, exc_info=exc_info)

    def critical(self, message, exc_info=False):
        self.logger.critical(message, exc_info=exc_info)


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


def parse_exclude_file(file_path):
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
                        result[database] = [collection]
                    else:
                        result[database].append(collection)
        logger.info('解析 {} 完成'.format(file_path))
    except Exception as err:
        logger.error('解析 {} 失敗: {}'.format(file_path, err), exc_info=True)
    return result


def mongodump(host, db, output=None, exclude_databases=None, exclude_collections=None, **args):
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
        command += ' -u {}'.format(args["username"])

    if 'password' in args.keys() and args["password"] != None:
        command += ' -p {}'.format(args["password"])

    if 'collection' in args.keys() and args["collection"] != None:
        command += ' -c {}'.format(args["collection"])

    if 'auth_db' in args.keys() and args["auth_db"] != None:
        command += ' --authenticationDatabase {}'.format(args["auth_db"])

    logger.debug('匯出指令:{}'.format(command))
    os.system(command)


if __name__ == '__main__':

    logger.debug('MongoDB ReadPreference: {}'.format(argv.read_preference))
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
        logger.info('匯出資料庫 {}'.format(db))
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
            for collection in exclude_target[db]:
                logger.info('排除 {}.{}'.format(db, collection))
            mongodump(
                host=host,
                db=db,
                username=username,
                password=password,
                output=output_dir,
                exclude_collections=exclude_target[db],
                auth_db=auth_db
            )
