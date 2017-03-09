set BUILD_DIR=..\..\search
set EXE_FILE=mirusan_search.exe
set TARGET_DIR=..\electron\dist

copy build.spec %BUILD_DIR%
cd %BUILD_DIR%
pyinstaller build.spec
copy dist\%EXE_FILE% %TARGET_DIR%
