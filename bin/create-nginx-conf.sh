#!/bin/bash

TEMPLATE=$1
OUTPUT=$2

mkdir -p $(dirname $OUTPUT)

if [[ "$OUTPUT" == *"prod"* ]]; then
  TH_HOST=tiddlyhost.com
  TS_HOST=tiddlyspot.com
else
  TH_HOST=tiddlyhost.local
  TS_HOST=tiddlyspot.local
fi

export TH_HOST TS_HOST
envsubst '${TH_HOST} ${TS_HOST}' < $TEMPLATE > $OUTPUT

echo Created $OUTPUT
