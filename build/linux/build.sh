#!/bin/bash

BUILD_DIR=../../search
EXEC_FILE=mirusan_search

cp build.spec $BUILD_DIR
cd $BUILD_DIR
pyinstaller build.spec
cp ./dist/$EXEC_FILE ../electron
