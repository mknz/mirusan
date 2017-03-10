# -*- coding: utf-8 -*-
from helper import normalize
from index_manager import IndexManager
from search_manager import Search

import falcon

from wsgiref import simple_server
import json


class DataBaseResource:
    def on_delete(self, req, resp):
        pass


class SearchDB:
    search = Search()

    def on_get(self, req, resp):
        qstr = req.get_param('q')
        if qstr is None:
            return
        if qstr is '':
            return

        qstr = normalize(qstr)  # normalize query string

        sort_field = req.get_param('sort-field')
        if sort_field is None:
            sort_field = 'title'

        rev = req.get_param('reverse')
        if rev == '1':
            reverse = True
        else:
            reverse = False

        rp = req.get_param('result-page')
        if rp is None:
            n_result_page = 1
        else:
            n_result_page = int(rp)

        pl = req.get_param('pagelen')
        if pl is None:
            pagelen = 10  # number of articles per result page
        else:
            pagelen = int(pl)

        search_result = self.search.search(query_str=qstr,
                                           sort_field=sort_field,
                                           reverse=reverse,
                                           n_page=n_result_page,
                                           pagelen=pagelen)

        resp.body = json.dumps(search_result, indent=4, ensure_ascii=False)


class DeleteDocument:
    def on_get(self, req, resp):
        im = IndexManager()
        gid = req.get_param('gid')
        message = im.delete_document(gid)
        res = {'message': message}
        resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class SortedIndex:
    search = Search()

    def on_get(self, req, resp):
        field = req.get_param('field')
        if field is None:
            return
        if field is '':
            return

        rev = req.get_param('reverse')
        if rev == '1':
            reverse = True
        else:
            reverse = False

        rp = req.get_param('result-page')
        if rp is None:
            n_result_page = 1
        else:
            n_result_page = int(rp)

        pl = req.get_param('pagelen')
        if pl is None:
            pagelen = 10  # number of articles per result page
        else:
            pagelen = int(pl)

        res = self.search.get_sorted_index(field=field, n_page=n_result_page,
                                           pagelen=pagelen, reverse=reverse)
        resp.body = json.dumps(res, indent=4, ensure_ascii=False)


class Server:
    api = falcon.API()
    api.add_route('/search', SearchDB())
    api.add_route('/sorted-index', SortedIndex())
    api.add_route('/delete', DeleteDocument())

    def start(self):
        httpd = simple_server.make_server("127.0.0.1", 8000, self.api)
        httpd.serve_forever()
