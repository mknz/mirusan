from whoosh.index import create_in, open_dir, exists_in
from whoosh.fields import TEXT, DATETIME, NUMERIC, KEYWORD, ID, Schema
from whoosh.analysis import NgramTokenizer, StandardAnalyzer, LanguageAnalyzer
from whoosh.qparser import QueryParser, MultifieldParser
from whoosh.query import Every, Term, Wildcard
from whoosh.lang import languages

from dateutil.parser import parse

import logging
import argparse
import os
import datetime
import re
import sys
import json
import unicodedata
import uuid
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
    def __init__(self):
        # Initialize db if not exist
        if not exists_in(Config.database_dir):
            self.create_index()

        self.ix = open_dir(Config.database_dir)
        self.writer = self.ix.writer()

    def open(self):
        self.ix = open_dir(Config.database_dir)
        self.writer = self.ix.writer()

    def close(self):
        del self.writer
        self.ix.close()

    def create_index(self, ngram_min=1, ngram_max=2):
        ngram_tokenizer = NgramTokenizer(minsize=ngram_min, maxsize=ngram_max)
        schema = Schema(file_path        = ID(stored=True, unique=True),  # primary key
                        gid              = ID(stored=True),  # document group id (pdf + texts)
                        parent_file_path = ID(stored=True),
                        title            = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        authors          = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
                        publisher        = TEXT(stored=True, sortable=True, analyzer=ngram_tokenizer),
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
        """Normalize type-unknown date object."""
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

    def add_pdf_file(self, file_path, gid=None, summary="", published_date=None):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        # set initial title: filename without ext
        title = os.path.splitext(os.path.basename(file_path))[0]

        fields = {}
        fields['gid']              = gid
        fields['file_path']        = file_path
        fields['title']            = title
        fields['summary']          = summary
        fields['document_format']  = 'pdf'
        fields['created_at']       = datetime.datetime.now()

        # prepare published date
        if published_date is not None:
            pdatetime = self.secure_datetime(published_date)
            fields['published_at'] = pdatetime
        self.writer.update_document(**fields)
        Config.logger.info('Added :' + file_path)

    def detect_lang(self, text):
        try:
            lang = langdetect.detect(text)
            lang_field_name = 'content_' + lang
            return lang, lang_field_name
        except:
            return None, None

    def add_lang_field(self, text):
        """Auto-detect language and add field if necessary."""
        lang, lang_field_name = self.detect_lang(text)

        if lang is None:
            return

        # Add field to schema only in new language
        if lang_field_name not in self.ix.schema.names():
            self.writer.commit()
            self.open()
            if lang == 'en':
                self.writer.add_field(lang_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=StandardAnalyzer()))
            elif lang in languages:
                self.writer.add_field(lang_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=LanguageAnalyzer(lang)))
            else:
                ngram_tokenizer = NgramTokenizer(minsize=1, maxsize=2)
                self.writer.add_field(lang_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=ngram_tokenizer))
            self.writer.commit()
            self.open()

    def add_text_file(self, text_file_path, gid=None, parent_file_path='', title='',
                      num_page=1, published_date=None):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        _, ext = os.path.splitext(text_file_path)
        if ext != '.txt':
            raise ValueError('Input file is not text file: ' + text_file_path)

        with open(text_file_path, 'r', encoding='utf-8') as f:
            content_text = f.read()

        content_text_normalized = normalize(content_text)

        # detect language from text
        self.add_lang_field(content_text_normalized)
        lang, lang_field_name = self.detect_lang(content_text_normalized)

        # set initial title: filename without ext
        if title == "":
            title = os.path.splitext(os.path.basename(parent_file_path))[0]

        # prepare published date
        fields = {}
        fields['gid']              = gid
        fields['file_path']        = text_file_path
        fields['parent_file_path'] = parent_file_path
        fields['title']            = title
        if lang is not None:
            fields[lang_field_name]    = content_text_normalized
            fields['language']         = lang
        fields['page']             = num_page
        fields['document_format']  = 'txt'
        fields['created_at']       = datetime.datetime.now()

        if published_date is not None:
            pdatetime = self.secure_datetime(published_date)
            fields['published_at'] = pdatetime,
        self.writer.update_document(**fields)
        Config.logger.info('Added :' + text_file_path)

    def add_text_page_file(self, text_file_path, gid=None):
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

        self.add_text_file(text_file_path=text_file_path,
                           gid=gid,
                           parent_file_path=doc_file_path,
                           num_page=num_page)

    def add_dir(self, text_dir_path):
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
            self.add_text_page_file(self.writer, path)
            # show progress
            print(str(i + 1) + ' / ' + str(len(text_file_paths)))


class Search:
    def __init__(self):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)
        self.ix = open_dir(Config.database_dir)

    def search(self, query_str, sort_field, reverse=False, n_page=1, pagelen=10):
        Config.logger.debug('Get query: ' + query_str)

        content_fields = []  # langauge-wise content fields
        for name in self.ix.schema.names():
            if re.search(r'^content_', name):
                content_fields.append(name)
        search_fields = content_fields + ['title']

        with self.ix.searcher() as searcher:
            query = MultifieldParser(search_fields,
                                     self.ix.schema).parse(query_str)

            # search onlyt text file
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

                content_field_name = 'content_' + r['language']
                d['content'] = r[content_field_name]

                # remove garbled characters
                d['highlighted_body'] = self.remove_garble(r.highlights(content_field_name))
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


def separate_files(files):
    pdfs = []
    for file in files:
        filename, ext = os.path.splitext(file)
        if ext in ['.pdf', '.PDF']:
            pdfs.append(file)

    groups = []
    for pdf in pdfs:
        title, ext = os.path.splitext(pdf)
        title = os.path.basename(title)
        group = {}
        # assign random uuid for document group
        group['id'] = str(uuid.uuid4())
        group['pdf_file'] = pdf
        group['text_files'] = []
        for file in files:
            filename, ext = os.path.splitext(file)
            if ext in ['.txt', '.TXT']:
                if re.search(r'^' + title, os.path.basename(filename)):
                    group['text_files'].append(file)
        groups.append(group)

    return groups


def add_files(files):
    """Using from electron, this argument consists of multiple pdf/txt file
    pairs, due to the restriction in JS code.
    """
    try:
        file_groups = separate_files(files)
        im = IndexManager()
        for group in file_groups:
            gid = group['id']
            im.add_pdf_file(group['pdf_file'], gid)
            for tf in group['text_files']:
                im.add_text_page_file(tf, gid)

        im.writer.commit()

    except Exception as err:
        Config.logger.exception('Error at add_files: %s', err)

    im.ix.close()
    return


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
        im = IndexManager()
        im.close()
        del im
        import api_server
        server = api_server.Server()
        Config.logger.info('Starting api server')
        server.start()
        return

    if args.init:
        im = IndexManager()
        return

    if args.query != '':
        try:
            s = Search()
            s.search_print(args.query)
        except Exception as err:
            Config.logger.exception('Error at search: %s', err)
        return

    if args.add_files is not None:
        add_files(args.add_files)

    if args.add_dir is not None:
        im = IndexManager()
        im.add_dir(args.add_dir)
        im.writer.commit()
        im.ix.close()
        return

    parser.print_help()
    return

if __name__ == '__main__':
    main()
