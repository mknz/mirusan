from config import Config
from helper import separate_files
from index_manager import IndexManager
from search_manager import Search

import argparse
import langdetect
import os


def add_files(files):
    """Using from electron, this argument consists of multiple pdf/txt file
    pairs, due to the restriction in JS code.
    """
    file_groups = separate_files(files)
    if file_groups == []:
        raise ValueError('Empty document group: ' + str(files))

    im = IndexManager()

    num_g = len(file_groups)
    for i, group in enumerate(file_groups):
        Config.logger.debug('Add document group: ' + str(group))
        gid = group['id']
        im.add_pdf_file(group['pdf_file'], gid)
        for tf in group['text_files']:
            im.add_text_page_file(tf, gid)

        # record progress, read from api server
        progress = (i + 1) / num_g
        with open('progress_add_db', 'w') as f:
            f.write(str(progress))

    with open('progress_add_db', 'w') as f:
        f.write('Finished')

    im.writer.commit()
    im.ix.close()
    return


def add_summary(title, summary_file):
    if not os.path.exists(summary_file):
        raise FileNotFoundError(summary_file)
    with open(summary_file) as f:
        summary = f.read()

    im = IndexManager()
    im.add_summary(title, summary)
    im.writer.commit()
    im.ix.close()
    return


def delete_by_title(title):
    im = IndexManager()
    Config.logger.debug('Delete by title: ' + title)
    im.delete_by_title(title)
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

    parser.add_argument('--add-summary', default=None, nargs='+')

    parser.add_argument('--delete-by-title', default=None)

    parser.add_argument('--ngram-min', default=1)
    parser.add_argument('--ngram-max', default=2)

    parser.add_argument('--server', action='store_true')
    parser.add_argument('--lang-detect', default=None)  # for debug

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
        if args.add_files == ['addfiles']:
            with open('addfiles', 'r') as f:
                text = f.read()
            add_file_list = text.split(',')
        else:
            add_file_list = args.add_files

        try:
            add_files(add_file_list)
        except Exception as err:
            Config.logger.exception('Could not add files: %s', err)
            print(err)
        return

    if args.add_summary is not None:
        print('add summary: ' + str(args.add_summary))
        title = args.add_summary[0]
        summary_file = args.add_summary[1]
        add_summary(title, summary_file)
        return

    title = args.delete_by_title
    if title is not None:
        print('delete by title: ' + title)
        delete_by_title(title)
        return

    if args.lang_detect:
        print(langdetect.detect(args.lang_detect))
        return

    parser.print_help()
    return

if __name__ == '__main__':
    main()
