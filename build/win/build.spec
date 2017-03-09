# -*- mode: python -*-

import langdetect
import os

langdetect_util_file = os.path.join(os.path.dirname(langdetect.__file__), 'utils', 'messages.properties')

block_cipher = None

added_files = [
  (langdetect_util_file, 'site-packages/langdetect/utils')
]

# Add import directory to pathex
a = Analysis(['search.py'],
             pathex=['.'],
             binaries=None,
             datas= added_files,
             hiddenimports=['search', 'six','packaging', 'packaging.version', 'packaging.specifiers', 'packaging.requirements'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='mirusan_search',
          debug=False,
          strip=False,
          upx=False,
          console=True)

