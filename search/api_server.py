# -*- coding: utf-8 -*-
from config import Config
from helper import normalize
from index_manager import IndexManager
from search_manager import Search

import falcon

from wsgiref import simple_server
import json
import os
import threading


class ConfigResource:
    def on_get(self, req, resp):
        try:
            config = Config.get()
            resp.body = json.dumps(config, indent=4, ensure_ascii=False)
        except Exception as err:
            Config.logger.exception('Error in get config: %s', err)
            print(err)
            res = {'message': str(err)}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class DataBaseResource:
    def on_delete(self, req, resp):
        pass


class SearchResource:
    def __init__(self, search):
        self.search = search

    def on_get(self, req, resp):
        try:
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
        except Exception as err:
            Config.logger.exception('Error in search: %s', err)
            print(err)
            res = {'message': str(err)}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class DeleteDocument:
    def on_get(self, req, resp):
        try:
            im = IndexManager()
            gid = req.get_param('gid')
            message = im.delete_document(gid)
            im.writer.commit()
            res = {'message': message}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        except Exception as err:
            Config.logger.exception('Error in delete db: %s', err)
            print(err)
            res = {'message': str(err)}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class UpdateDocument:
    def on_get(self, req, resp):
        try:
            im = IndexManager()
            unique_field_value = req.get_param('primary-key')
            update_field_name = req.get_param('field')
            update_field_value = req.get_param('value')
            if update_field_value is None:
                raise ValueError(
                        'Error: field: {:s} value: {:s}'.
                        format(update_field_name, str(update_field_value)))
            im.update_field('file_path', unique_field_value,
                            update_field_name, update_field_value)

            im.writer.commit()
            res = {'message': 'Update success'}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        except Exception as err:
            Config.logger.exception('Error in update db: %s', err)
            print(err)
            res = {'message': str(err)}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class SortedIndex:
    def __init__(self, search):
        self.search = search

    def on_get(self, req, resp):
        try:
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

            res = self.search.get_sorted_index(field=field,
                                               n_page=n_result_page,
                                               pagelen=pagelen,
                                               reverse=reverse)
            for row in res['rows']:
                if 'published_at' not in row.keys():
                    row['published_at'] = ''
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        except Exception as err:
            Config.logger.exception('Error in sorted index: %s', err)
            print(err)
            res = {'message': str(err)}
            resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class CheckProgress:
    def on_get(self, req, resp):
        def _get_state(file_name):
            if os.path.exists(file_name):
                with open(file_name, 'r') as f:
                    content = f.read()
                    if content == 'Finished':
                        return content
                progress = float(content)
                if progress == 0.:
                    '...'
                else:
                    state = str(round(progress * 100)) + '%'
            else:
                state = ''
            return state

        state = _get_state('progress_text_extraction')
        if state not in ['', 'Finished']:
            message = 'Extracting texts: ' + state
        elif state == 'Finished':
            state = _get_state('progress_add_db')
            if state in ['Finished', '']:
                message = state
            else:
                message = 'Adding to database: ' + state
        else:
            message = ''

        res = {'message': message}
        resp.body = json.dumps(res, indent=4, ensure_ascii=False)
        return


class Server:
    def __init__(self, db_readonly=False):
        search = Search(db_readonly=db_readonly)
        api = falcon.API()
        api.add_route('/config', ConfigResource())
        api.add_route('/search', SearchResource(search))
        api.add_route('/sorted-index', SortedIndex(search))
        api.add_route('/delete', DeleteDocument())
        api.add_route('/progress', CheckProgress())
        api.add_route('/update-document', UpdateDocument())
        self.api = api

    def start(self):
        print('Start server.')
        httpd = simple_server.make_server("127.0.0.1", 8000, self.api)
        is_server_alive = True

        def check_alive():
            if not is_server_alive:
                return  # quit program
            # alive monitor every 2 seconds
            threading.Timer(2.0, check_alive).start()
            if not os.path.exists('main_process_alive'):
                print('Main process is down. Shut down.')
                httpd.shutdown()

        threading.Thread(target=check_alive).start()
        httpd.serve_forever()
        print('Server is shut down.')
        is_server_alive = False

    def start_stand_alone(self):
        print('Start stand alone server.')
        httpd = simple_server.make_server("127.0.0.1", 8000, self.api)
        httpd.serve_forever()
