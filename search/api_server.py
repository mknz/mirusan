# -*- coding: utf-8 -*-
from search import Config, Search, IndexManager

import falcon

from wsgiref import simple_server
import json
import traceback
import subprocess


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
        json_str = req.get_param('json')
        json_file_paths = json.loads(json_str)
        file_paths = json_file_paths['paths']

        # start async process
        if Config.platform == 'linux':
            pid = subprocess.Popen(['python3', './search.py', '--add-files'] + file_paths).pid

        resp_json = {}
        resp_json['message'] = 'Start adding files.'
        resp.body = json.dumps(resp_json, ensure_ascii=False)

api = falcon.API()
api.add_route('/search', SearchDB())
api.add_route('/add-file', AddFileToDB())

if __name__ == "__main__":
    httpd = simple_server.make_server("127.0.0.1", 8000, api)
    httpd.serve_forever()
