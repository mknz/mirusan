import os
import unicodedata
import uuid
import re


def normalize(string):
    return unicodedata.normalize('NFKC', string)


def separate_files(files):
    pdfs = []
    for file in files:
        filename, ext = os.path.splitext(file)
        if ext in ['.pdf', '.PDF']:
            pdfs.append(file)

    groups = []
    for pdf in pdfs:
        title, ext = os.path.splitext(pdf)
        title = os.path.basename(title)
        group = {}
        # assign random uuid for document group
        group['id'] = str(uuid.uuid4())
        group['pdf_file'] = pdf
        group['text_files'] = []
        for file in files:
            filename, ext = os.path.splitext(file)
            if ext in ['.txt', '.TXT']:
                if re.search(r'^' + title, os.path.basename(filename)):
                    group['text_files'].append(file)
        groups.append(group)

    return groups
