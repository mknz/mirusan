from whoosh.index import create_in, open_dir
from whoosh.fields import TEXT, Schema
from whoosh.analysis import NgramTokenizer
from whoosh.qparser import QueryParser, MultifieldParser

import argparse
import os


class Config:
    database_dir = os.environ.get('DATABASE_DIR')
    if database_dir is None:
        raise ValueError('DATABASE_DIR is not set in env.')


class IndexManager:
    ngram_tokenizer = NgramTokenizer(minsize=2, maxsize=2)

    def create_index(self):
        if not os.path.exists(Config.database_dir):
            os.mkdir(Config.database_dir)

        schema = Schema(file_name=TEXT(stored=True,
                                       analyzer=self.ngram_tokenizer),
                        content=TEXT(stored=True,
                                     analyzer=self.ngram_tokenizer))

        ix = create_in(Config.database_dir, schema)
        print('Created db: ' + Config.database_dir)
        ix.close()

    def add_file(self, text_file_path):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)

        _, ext = os.path.splitext(text_file_path)
        if ext != '.txt':
            raise ValueError('Input file is not text file: ' + text_file_path)

        with open(text_file_path, 'r') as f:
            text = f.read()

        ix = open_dir(Config.database_dir)
        try:
            writer = ix.writer()
            writer.add_document(file_name=os.path.basename(text_file_path),
                                content=text)
            writer.commit()
            print('Added :' + text_file_path)
            ix.close()
        except:
            ix.close()

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
            self.add_file(path)
            print(str(i + 1) + ' / ' + str(len(text_file_paths)))


class Search:
    def __init__(self):
        if not os.path.exists(Config.database_dir):
            raise ValueError('DB dir does not exist: ' + Config.database_dir)
        self.ix = open_dir(Config.database_dir)

    def search(self, query_str):
        with self.ix.searcher() as searcher:
            query = MultifieldParser(['title', 'content'],
                                     self.ix.schema).parse(query_str)
            results = searcher.search(query)
            for r in results:
                print(r['file_name'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--query')
    args = parser.parse_args()
    s = Search()
    s.search(args.query)
