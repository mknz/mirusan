from whoosh.index import create_in, open_dir
from whoosh.fields import TEXT, Schema
from whoosh.analysis import NgramTokenizer
from whoosh.qparser import QueryParser

import argparse
import os


class Search:
    def __init__(self):
        pass

    def create_index(self, index_path):
        schema = Schema(body=TEXT(stored=True,
                                  analyzer=NgramTokenizer(minsize=1,
                                                          maxsize=4)))
        self.ix = create_in(index_path, schema)

    def load_index(self, index_path):
        self.ix = open_dir(index_path)

    def add_to_index(self, doc_path):
        pass

    def search(self, query):
        pass


def main(query_str):
    schema = Schema(body=TEXT(stored=True, analyzer=NgramTokenizer(minsize=2,
                                                                   maxsize=4)))
    database_dir = os.environ.get('DATABASE_DIR')
    if not os.path.exists(database_dir):
        os.mkdir(database_dir)

    ix = create_in(database_dir, schema)
    writer = ix.writer()
    writer.add_document(body='本日は晴天なり')
    writer.add_document(body='我輩は猫である')
    writer.add_document(body='あいうえおかきくけこ')
    writer.commit()

    with ix.searcher() as searcher:
        query = QueryParser('body', ix.schema).parse(query_str)
        results = searcher.search(query)
        for r in results:
            print(r)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--query')
    args = parser.parse_args()
    main(args.query)
