from whoosh.index import create_in, open_dir
from whoosh.fields import TEXT, DATETIME, NUMERIC, KEYWORD, ID, Schema
from whoosh.analysis import NgramTokenizer
from whoosh.qparser import QueryParser, MultifieldParser
from whoosh.query import Every, Term, Wildcard
from dateutil.parser import parse

import logging
import argparse
import os
import datetime
import re
import sys
import json
import unicodedata
import langdetect


def normalize(string):
    return unicodedata.normalize('NFKC', string)


class Config:
    # Workaround: fix later
    argvs = sys.argv
    argc = len(argvs)
    if argc == 3 and argvs[1] == '--config':
        config_filename = argvs[2]
    else:
        config_filename = 'config.json'

    if not os.path.exists(config_filename):
        raise ValueError('config.json does not exist.')

    # read config from json file
    with open(config_filename) as f:
        config = json.load(f)

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


class IndexManager:
    def check_and_init_db(self):
        if os.listdir(Config.database_dir) == []:
            self.create_index()

    def create_index(self, ngram_min=1, ngram_max=2):
        ngram_tokenizer = NgramTokenizer(minsize=ngram_min, maxsize=ngram_max)
        schema = Schema(file_path        = ID(stored=True, unique=True),
                        parent_file_path = ID(stored=True),
                        title            = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        authors          = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        publisher        = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        content          = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        page             = NUMERIC(stored=True),
                        total_pages      = NUMERIC(stored=True),
                        tags             = KEYWORD(stored=True, lowercase=True, scorable=True),
                        summary          = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        memo             = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        language         = ID(stored=True),
                        document_format  = ID(stored=True),
                        identifier       = ID(stored=True),
                        series_id        = ID(stored=True),
                        published_at     = DATETIME(stored=True, sortable=True),
                        created_at       = DATETIME(stored=True, sortable=True))

        ix = create_in(Config.database_dir, schema)
        Config.logger.info('Created db: ' + Config.database_dir)
        ix.close()

    def secure_datetime(self, date):
        """date: type unknown."""
        if type(date) is datetime.datetime:
            pdatetime = date
        elif type(date) is datetime.date:
            year = date.year
            month = date.month
            day = date.day
            pdatetime = datetime.datetime(year, month, day)
        elif type(date) is str:
            pdatetime = parse(date)
        else:
            raise TypeError

        return pdatetime

    def add_pdf_file(self, writer, file_path, summary="", published_date=None):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        # set initial title: filename without ext
        title = os.path.splitext(os.path.basename(file_path))[0]

        # prepare published date
        if published_date is not None:
            pdatetime = self.secure_datetime(published_date)
            writer.update_document(file_path          = file_path,
                                   title              = title,
                                   summary            = summary,
                                   document_format    = 'pdf',
                                   published_at       = pdatetime,
                                   created_at         = datetime.datetime.now())
        else:
            writer.update_document(file_path          = file_path,
                                   title              = title,
                                   summary            = summary,
                                   document_format    = 'pdf',
                                   created_at         = datetime.datetime.now())

        Config.logger.info('Added :' + file_path)

    def add_text_file(self, writer, text_file_path, parent_file_path, title="", num_page=1, published_date=None):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        _, ext = os.path.splitext(text_file_path)
        if ext != '.txt':
            raise ValueError('Input file is not text file: ' + text_file_path)

        with open(text_file_path, 'r', encoding='utf-8') as f:
            content_text = f.read()

        content_text_normalized = normalize(content_text)

        # detect language from text
        lang = langdetect.detect(content_text_normalized)

        # set initial title: filename without ext
        if title == "":
            title = os.path.splitext(os.path.basename(parent_file_path))[0]

        # prepare published date
        if published_date is not None:
            pdatetime = self.secure_datetime(published_date)
            writer.update_document(file_path          = text_file_path,
                                   parent_file_path   = parent_file_path,
                                   title              = title,
                                   content            = content_text_normalized,
                                   page               = num_page,
                                   language           = lang,
                                   document_format    = 'txt',
                                   published_at       = pdatetime,
                                   created_at         = datetime.datetime.now())
        else:
            writer.update_document(file_path          = text_file_path,
                                   parent_file_path   = parent_file_path,
                                   title              = title,
                                   content            = content_text,
                                   page               = num_page,
                                   language           = lang,
                                   document_format    = 'txt',
                                   created_at         = datetime.datetime.now())


        Config.logger.info('Added :' + text_file_path)

    def add_text_page_file(self, writer, text_file_path):
        """Add database page-wise text file.
        filename format: {DOCUMENT_NAME}_p{NUM_PAGE}.txt
        """
        if not os.path.exists(text_file_path):
            raise ValueError('File does not exist: ' + text_file_path)

        filename = os.path.basename(text_file_path)
        m = re.search(r'(.+)_p(\d+).txt', filename)
        if m is None:
            raise ValueError('Invalid file format: ' + text_file_path)

        doc_filename = m.group(1) + '.pdf'
        doc_file_path = os.path.join(Config.pdf_dir, doc_filename)
        num_page = int(m.group(2))

        if not os.path.exists(doc_file_path):
            raise ValueError('Document file does not exist: ' + doc_file_path)

        self.add_text_file(writer=writer,
                           text_file_path=text_file_path,
                           parent_file_path=doc_file_path,
                           num_page=num_page)

    def add_dir(self, writer, text_dir_path):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        files = os.listdir(text_dir_path)
        text_file_paths = []
        for file in files:
            _, ext = os.path.splitext(file)
            if ext == '.txt':
                text_file_paths.append(os.path.join(text_dir_path, file))

        if text_file_paths == []:
            raise ValueError('No text files in: ' + text_dir_path)

        for i, path in enumerate(text_file_paths):
            self.add_text_page_file(writer, path)
            # show progress
            print(str(i + 1) + ' / ' + str(len(text_file_paths)))


class Search:
    def __init__(self):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)
        self.ix = open_dir(Config.database_dir)

    def search(self, query_str, sort_field, reverse=False, n_page=1, pagelen=10):
        Config.logger.debug('Get query: ' + query_str)
        with self.ix.searcher() as searcher:
            query = MultifieldParser(['title', 'content'],
                                     self.ix.schema).parse(query_str)
            results = searcher.search_page(query, n_page,
                                           pagelen=pagelen,
                                           sortedby=sort_field,
                                           reverse=reverse,
                                           filter=Term('document_format', 'txt'))
            n_hits = len(results)  # number of total hit documents
            total_pages = n_hits // pagelen + 1  # number of search result pages
            if n_page > total_pages:
                raise ValueError

            res_list = []
            for r in results:
                d = {}
                for key in r.keys():  # copy all fields
                    if type(r[key]) == datetime.datetime:
                        d[key] = r[key].isoformat()
                    else:
                        d[key] = r[key]

                # remove garbled characters
                d['highlighted_body'] = self.remove_garble(r.highlights('content'))
                res_list.append(d)

            return {'rows': res_list, 'n_hits': n_hits, 'total_pages': total_pages}

    def get_sorted_index(self, field, n_page=1, pagelen=10, reverse=False):
        with self.ix.searcher() as searcher:
            query = Every()
            results = searcher.search_page(query, n_page, pagelen=pagelen,
                                           sortedby=field, reverse=reverse,
                                           filter=Term('document_format', 'pdf'))
            n_docs = len(results)  # number of total documents
            total_pages = n_docs // pagelen + 1  # number of result pages
            if n_page > total_pages:
                raise ValueError

            res_list = []
            for r in results:
                d = {}
                for key in r.keys():  # copy all fields
                    if type(r[key]) == datetime.datetime:
                        d[key] = r[key].isoformat()
                    else:
                        d[key] = r[key]
                res_list.append(d)

            return {'rows': res_list, 'n_docs': n_docs, 'total_pages': total_pages}

    def remove_garble(self, str):
        """Remove (visually annoying) unicode replacement characters."""
        # TODO: remove with nearby characters (to erase imcomplete words)
        return str.replace('\uFFFD', '')

    def search_print(self, query_str):
        with self.ix.searcher() as searcher:
            query = MultifieldParser(['title', 'content'],
                                     self.ix.schema).parse(query_str)
            results = searcher.search(query)
            for r in results:
                print(r['file_path'])
                print(r['title'])
                print(r.highlights('content'))
                print('')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', default='./config.json')
    parser.add_argument('--query', default='')
    parser.add_argument('--init', help='Initialize database',
                        action='store_true')
    parser.add_argument('--add-dir', default=None)
    parser.add_argument('--add-files', default=None, nargs='+')
    parser.add_argument('--ngram-min', default=1)
    parser.add_argument('--ngram-max', default=2)

    parser.add_argument('--server', action='store_true')

    args = parser.parse_args()

    if args.server:
        # Initialize db if not exist
        im = IndexManager()
        im.check_and_init_db()

        import api_server
        server = api_server.Server()
        Config.logger.info('Starting api server')
        server.start()
        return

    if args.init:
        im = IndexManager()
        im.create_index(ngram_min=args.ngram_min, ngram_max=args.ngram_max)
        return

    if args.query != '':
        try:
            s = Search()
            s.search_print(args.query)
        except Exception as err:
            Config.logger.exception('Error at search: %s', err)
        return

    if args.add_files is not None:
        try:
            im = IndexManager()
            im.check_and_init_db()

            ix = open_dir(Config.database_dir)
            writer = ix.writer()

            for path in args.add_files:
                _, ext = os.path.splitext(path)
                if ext in ['.pdf', '.PDF']:
                    im.add_pdf_file(writer, path)
                elif ext in ['.txt', '.TXT']:
                    im.add_text_page_file(writer, path)
                else:
                    raise ValueError(path)

            writer.commit()

        except Exception as err:
            Config.logger.exception('Error at add_files: %s', err)

        ix.close()
        return

    if args.add_dir is not None:
        im = IndexManager()
        ix = open_dir(Config.database_dir)
        writer = ix.writer()
        im.add_dir(writer, args.add_dir)
        writer.commit()
        ix.close()
        return

    parser.print_help()
    return

if __name__ == '__main__':
    main()
