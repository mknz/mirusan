# -*- coding: utf-8 -*-
from search import Search

import falcon

import json
from wsgiref import simple_server


class SearchDB:
    search = Search()

    def on_get(self, req, resp):
        query_str = req.get_param('query')
        items = self.search.search(query_str)
        resp_json = {}
        resp_json['results'] = items
        resp.body = json.dumps(resp_json, ensure_ascii=False)

api = falcon.API()
api.add_route('/search', SearchDB())

if __name__ == "__main__":
    httpd = simple_server.make_server("127.0.0.1", 8000, api)
    httpd.serve_forever()
