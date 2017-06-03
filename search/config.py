import os
import sys
import json
import logging


class Config:
    # if executed as script
    p = sys.argv[0]
    exec_dir = os.path.dirname(os.path.abspath(p))
    config_file_path = os.path.join(exec_dir, 'config.json')

    if not os.path.exists(config_file_path):
        # if imported
        file_dir = os.path.dirname(__file__)
        config_file_path = os.path.join(file_dir, 'config.json')

        if not os.path.exists(config_file_path):
            raise ValueError('config.json does not exist.')

    # read config from json file
    with open(config_file_path) as f:
        config = json.load(f)
        config['config_file_path'] = config_file_path

    if config['mode'] == 'debug':
        debug = True
    else:
        debug = False

    platform = sys.platform

    def create_logger(debug):
        logger = logging.getLogger()

        file_handler = logging.FileHandler('search.log')
        formatter = logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s '
            '[in %(pathname)s:%(lineno)d]'
        )
        file_handler.setFormatter(formatter)

        if debug:
            logger.setLevel(logging.DEBUG)
            file_handler.setLevel(logging.DEBUG)
        else:
            logger.setLevel(logging.INFO)
            file_handler.setLevel(logging.INFO)

        logger.addHandler(file_handler)
        logger.info('Start logging')
        return logger

    logger = create_logger(debug)

    def check_and_create_dir(dirpath, logger):
        if not os.path.exists(dirpath):
            logger.info('Create dir: ' + dirpath)
            os.mkdir(dirpath)

    data_dir = config['data_dir']
    if data_dir == '':
        raise ValueError('data_dir is not properly set in config file.')

    check_and_create_dir(data_dir, logger)

    database_dir = os.path.join(data_dir, 'database')
    check_and_create_dir(database_dir, logger)

    pdf_dir = config['pdf_dir']
    check_and_create_dir(pdf_dir, logger)

    txt_dir = config['txt_dir']
    check_and_create_dir(txt_dir, logger)

    if 'db_readonly' in config:
        val = config['db_readonly']
        if val == 'true':
            db_readonly = True
        elif val == 'false':
            db_readonly = False
        else:
            raise ValueError('Invalid config setting: ' + val)
    else:
        db_readonly = False

    @classmethod
    def get(cls):
        return cls.config
