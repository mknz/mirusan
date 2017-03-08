from nose.tools import eq_, ok_
from whoosh.index import exists_in

import unittest
import sys
import os
import shutil

sys.path.append(os.path.dirname(__file__) + '/../')

from search import Config, Search, IndexManager, normalize

test_pdf = '../electron/pdfjs/web/compressed.tracemonkey-pldi-09.pdf'


class TestSearch(unittest.TestCase):
    def test_add_pdf(self):
        if exists_in(Config.database_dir):
            raise IOError(Config.database_dir + ': data exists. Abort.')
        im = IndexManager()
        im.add_pdf_file(test_pdf)
        im.writer.commit()
        im.ix.close()
        shutil.rmtree(Config.data_dir)
        print('Deleting test data dir')
