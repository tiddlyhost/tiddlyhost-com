#!/bin/bash
#
# A simpler way to download empty files if you don't want to use ansible
#

EMPTIES_DIR=rails/tw_content/empties
mkdir -p $EMPTIES_DIR
curl -s https://tiddlywiki.com/prerelease/empty.html -o $EMPTIES_DIR/tw5.html
curl -s https://classic.tiddlywiki.com/empty.html -o $EMPTIES_DIR/classic.html
ls -l $EMPTIES_DIR
