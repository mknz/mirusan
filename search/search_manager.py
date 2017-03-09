from config import Config

from whoosh.index import open_dir
from whoosh.qparser import MultifieldParser
from whoosh.query import Every, Term


import os
import datetime
import re


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
