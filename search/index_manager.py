from config import Config
from helper import normalize

from whoosh.index import create_in, open_dir, exists_in
from whoosh.fields import TEXT, DATETIME, NUMERIC, KEYWORD, ID, Schema
from whoosh.analysis import NgramTokenizer, StandardAnalyzer, LanguageAnalyzer
from whoosh.lang import languages

from dateutil.parser import parse

import os
import datetime
import re
import langdetect


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

    def delete_document(self, gid):
        self.writer.delete_by_term('gid', gid)
        self.writer.commit()
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
