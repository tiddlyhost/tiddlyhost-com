#!/usr/bin/bash -u

BACKUP_DIR=../thost-backups/s3
#BACKUP_DIR=../thost-backups/s3/latest-20220517
EXTRACT_DIR=../thost-backup-extract
SITE_NAME=$1

# Look for likely content of UploadURL tiddler
# Todo:
# - Search for both of these
# - Support classic and feather wiki
#SEARCH_STRING="<pre>https://$SITE_NAME.tiddlyhost.com</pre>"
SEARCH_STRING="\"text\":\"https://$SITE_NAME.tiddlyhost.com\""

mkdir -p $EXTRACT_DIR

for f in $( find $BACKUP_DIR ); do
  FILE_CHECK=$( file $f | cut -d: -f2 | grep 'zlib compressed' )
  if [[ -n "$FILE_CHECK" ]]; then
    FOUND=$( zlib-flate -uncompress < $f | grep -i "$SEARCH_STRING" )
    if [[ -n "$FOUND" ]]; then
      echo $FOUND | less -SEX
      zlib-flate -uncompress < $f > $EXTRACT_DIR/$( basename $f ).html
      echo Wrote to $EXTRACT_DIR/$( basename $f ).html
    fi
  fi
done
