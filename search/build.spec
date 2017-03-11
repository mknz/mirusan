# -*- mode: python -*-

import langdetect
import os

langdetect_path = os.path.dirname(langdetect.__file__)
langdetect_util_file = os.path.join(langdetect_path, 'utils', 'messages.properties')
langdetect_profiles = os.path.join(langdetect_path, 'profiles')

block_cipher = None

added_files = [
  (langdetect_util_file, 'langdetect/utils'),
  (langdetect_profiles, 'langdetect/profiles')
]

# Add import directory to pathex
a = Analysis(['search.py'],
             pathex=['.'],
             binaries=None,
             datas= added_files,
             hiddenimports=['search', 'six', 'langdetect', 'packaging', 'packaging.version', 'packaging.specifiers', 'packaging.requirements'],
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

