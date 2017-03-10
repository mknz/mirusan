from config import Config
from helper import separate_files
from index_manager import IndexManager
from search_manager import Search

import argparse


def add_files(files):
    """Using from electron, this argument consists of multiple pdf/txt file
    pairs, due to the restriction in JS code.
    """
    file_groups = separate_files(files)
    if file_groups == []:
        raise ValueError('Empty document group: ' + str(files))

    im = IndexManager()
    for group in file_groups:
        Config.logger.debug('Add document group: ' + str(group))
        gid = group['id']
        im.add_pdf_file(group['pdf_file'], gid)
        for tf in group['text_files']:
            im.add_text_page_file(tf, gid)

    im.writer.commit()
    im.ix.close()
    return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', default='./config.json')
    parser.add_argument('--query', default='')
    parser.add_argument('--init', help='Initialize database',
                        action='store_true')
    parser.add_argument('--add-dir', default=None)
    parser.add_argument('--add-files', default=None, nargs='+')
    parser.add_argument('--ngram-min', default=1)
    parser.add_argument('--ngram-max', default=2)

    parser.add_argument('--server', action='store_true')

    args = parser.parse_args()

    if args.server:
        im = IndexManager()
        im.close()
        del im
        import api_server
        server = api_server.Server()
        print('Starting api server')
        server.start()
        return

    if args.init:
        im = IndexManager()
        return

    if args.query != '':
        print('search: ' + args.query)
        try:
            s = Search()
            s.search_print(args.query)
        except Exception as err:
            Config.logger.exception('Error in search: %s', err)
            print(err)
        return

    if args.add_files is not None:
        print('add files: ' + str(args.add_files))
        try:
            add_files(args.add_files)
        except Exception as err:
            Config.logger.exception('Could not add files: %s', err)
            print(err)
        return

    if args.add_dir is not None:
        print('add dir: ' + str(args.add_dir))
        try:
            im = IndexManager()
            im.add_dir(args.add_dir)
            im.writer.commit()
            im.ix.close()
        except Exception as err:
            Config.logger.exception('Could not add dir: %s', err)
            print(err)
        return

    parser.print_help()
    return

if __name__ == '__main__':
    main()
