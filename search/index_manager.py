from config import Config
from helper import normalize

from whoosh.index import create_in, open_dir, exists_in
from whoosh.fields import TEXT, DATETIME, NUMERIC, KEYWORD, ID, Schema
from whoosh.analysis import NgramTokenizer, StandardAnalyzer, LanguageAnalyzer
from whoosh.lang import languages
from whoosh.qparser import QueryParser
from whoosh.query import Every

from dateutil.parser import parse

import os
import datetime
import re
import langdetect
import shutil


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

    def _delete_files(self, docs):
        for doc in docs:
            fp = doc['file_path']
            if os.path.exists(fp):
                os.remove(fp)
            title = doc['title']
            title_txt_dir = os.path.join(Config.txt_dir, title)
            if os.path.exists(title_txt_dir):
                shutil.rmtree(title_txt_dir)

    def delete_document(self, gid, is_keep_file=False):
        docs = self.get_documents('gid', gid)
        if docs == []:
            Config.logger.info('No document: ' + str(gid))
            return

        if not is_keep_file:
            self._delete_files(docs)

        n_doc = self.writer.delete_by_term('gid', gid)
        message = str(n_doc) + ' documents deleted.'
        Config.logger.info(message)
        return message

    def delete_by_title(self, title, is_keep_file=False):
        docs = self.get_documents('title', title)
        if docs == []:
            raise ValueError('Not found: ' + title)

        for doc in docs:
            self.delete_document(doc['gid'], is_keep_file)
        return

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

    def add_summary(self, title, summary_text):
        docs = self.get_documents('title', title)
        if docs == []:
            raise ValueError('Document not found: ' + title)

        file_path = None
        for doc in docs:
            if doc['document_format'] == 'pdf':
                file_path = doc['file_path']

        if file_path is None:
            raise ValueError('PDF document not found: ' + title)

        self.update_field('file_path', file_path, 'summary', summary_text)
        Config.logger.info('Add summary :' + file_path)
        return

    def detect_lang(self, text):
        try:
            lang = langdetect.detect(text)
            return lang
        except:
            return None

    def add_lang_field(self, text, lang):
        """Add language field if necessary."""
        if lang is None:
            return None

        content_field_name = 'content_' + lang

        # Add field to schema only in new language
        if content_field_name not in self.ix.schema.names():
            Config.logger.info('Add new content field: ' + content_field_name)
            self.writer.commit()
            self.open()
            if lang == 'en':
                self.writer.add_field(content_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=StandardAnalyzer()))
            elif lang in languages:
                self.writer.add_field(content_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=LanguageAnalyzer(lang)))
            else:
                ngram_tokenizer = NgramTokenizer(minsize=1, maxsize=2)
                self.writer.add_field(content_field_name,
                                      TEXT(stored=True, sortable=True,
                                           analyzer=ngram_tokenizer))
            self.writer.commit()
            self.open()

        return content_field_name

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
        lang = self.detect_lang(content_text_normalized)
        if lang is None:
            Config.logger.info('Could not detect language :' + text_file_path)

        # add lang field if necessary
        content_field_name = self.add_lang_field(content_text_normalized, lang)

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
            fields[content_field_name]    = content_text_normalized
            fields['language']         = lang
        fields['page']             = num_page
        fields['document_format']  = 'txt'
        fields['created_at']       = datetime.datetime.now()

        if published_date is not None:
            pdatetime = self.secure_datetime(published_date)
            fields['published_at'] = pdatetime
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

    def _result_to_dic(self, result):
        res_dic = {}
        for r in result:
            res_dic[r] = result[r]
        return res_dic

    def get_documents(self, search_field, query_str):
        query = QueryParser(search_field, self.ix.schema).parse(query_str)
        with self.ix.searcher() as searcher:
            results = searcher.search(query, limit=100000)
            res = [self._result_to_dic(r) for r in results]
        return res

    def update_field(self, unique_field_name, unique_field_value,
                     update_field_name, update_field_value):
        query = QueryParser(unique_field_name, self.ix.schema).parse(unique_field_value)
        with self.ix.searcher() as searcher:
            results = searcher.search(query)
            res = [self._result_to_dic(r) for r in results]
        assert len(res) == 1
        res[0][update_field_name] = update_field_value
        self.writer.update_document(**res[0])

        # Avoid duplicates
        if update_field_name == unique_field_name:
            self.writer.delete_by_term(unique_field_name, unique_field_value)

    def update_fields(self, unique_field_name, unique_field_value,
                      **update_fields):
        query = QueryParser(unique_field_name, self.ix.schema).\
                parse(unique_field_value)
        with self.ix.searcher() as searcher:
            results = searcher.search(query)
            res = [self._result_to_dic(r) for r in results]
        assert len(res) == 1

        for key in update_fields:
            res[0][key] = update_fields[key]
        self.writer.update_document(**res[0])

        # Avoid duplicates
        if unique_field_name in update_fields.keys():
            self.writer.delete_by_term(unique_field_name, unique_field_value)

    def get_all_documents(self):
        query = Every()
        with self.ix.searcher() as searcher:
            results = searcher.search(query, limit=100000)
            res = [self._result_to_dic(r) for r in results]
        return res
