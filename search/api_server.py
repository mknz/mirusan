# -*- coding: utf-8 -*-
from search import Config, Search, IndexManager

import falcon

from wsgiref import simple_server
import json
import traceback


class DataBaseResource:
    def on_delete(self, req, resp):
        pass


class SearchDB:
    search = Search()

    def on_get(self, req, resp):
        query_str = req.get_param('query')
        items = self.search.search(query_str)
        resp_json = {}
        resp_json['results'] = items
        resp.body = json.dumps(resp_json, ensure_ascii=False)


class AddFileToDB:
    im = IndexManager()

    def on_get(self, req, resp):
        file_path = req.get_param('file')
        try:
            self.im.add_text_page_file(file_path)
            exit_status_str = 'Success'
        except Exception as e:
            traceback.print_exc()
            exit_status_str = e.args
        resp_json = {}
        resp_json['exit-status'] = exit_status_str
        resp.body = json.dumps(resp_json, ensure_ascii=False)

api = falcon.API()
api.add_route('/search', SearchDB())
api.add_route('/add-file', AddFileToDB())

if __name__ == "__main__":
    httpd = simple_server.make_server("127.0.0.1", 8000, api)
    httpd.serve_forever()
