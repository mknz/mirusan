# -*- coding: utf-8 -*-
import falcon

import json
from wsgiref import simple_server


class TestAPI:
    def on_get(self, req, resp):
        resp_json = {}
        resp_json['results'] = ['test']
        resp.body = json.dumps(resp_json, ensure_ascii=False)

api = falcon.API()
api.add_route('/search', TestAPI())

if __name__ == "__main__":
    httpd = simple_server.make_server("127.0.0.1", 8000, api)
    httpd.serve_forever()
