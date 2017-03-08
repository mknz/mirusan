from nose.tools import eq_, ok_
from whoosh.index import open_dir, exists_in
from whoosh.query import Every, Term, Wildcard

import unittest
import sys
import os
import shutil

sys.path.append(os.path.dirname(__file__) + '/../')

from search import Config, Search, IndexManager, normalize

test_pdf = '../electron/pdfjs/web/compressed.tracemonkey-pldi-09.pdf'


class TestSearch(unittest.TestCase):
    def setup(self):
        if exists_in(Config.database_dir):
            raise IOError(Config.database_dir + ': data exists. Abort.')

        im = IndexManager()

        im.add_pdf_file(test_pdf)

        im.writer.commit()
        im.ix.close()

    def test_add_text(self):
        test_text = 'abc def'
        test_file = 'test_p1.txt'
        test_file_path = os.path.join(Config.txt_dir, test_file)

        test_pdf_file = 'test.pdf'
        with open(os.path.join(Config.pdf_dir, test_pdf_file), 'w'):
            pass

        with open(test_file_path, 'w') as f:
            f.write(test_text)

        im = IndexManager()
        im.add_text_page_file(test_file_path)
        im.writer.commit()
        im.ix.close()

    def test_confirm_index(self):
        ix = open_dir(Config.database_dir)
        query = Every()
        with ix.searcher() as searcher:
            results = searcher.search(query)
            eq_(len(results), 2)  # expect number of records

    def test_search(self):
        search = Search()
        qstr = 'abc'
        res = search.search(query_str=qstr, sort_field='title')
        eq_(res['rows'][0]['title'], 'test')

    def teardown(self):
        print('Delete test data dir')
        shutil.rmtree(Config.data_dir)
