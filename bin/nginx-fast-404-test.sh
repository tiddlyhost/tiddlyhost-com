#!/usr/bin/bash
set -euo pipefail

# A quick little script to test if the regexes defined in
# ansible/playbooks/templates/docker/nginx-conf/commonconf.j2
# work the way I think they do

TIDDLYHOST=https://tiddlyhost.local
#TIDDLYHOST=https://tiddlyhost.com

PATHS='
  /store.php
  /foo.php
  /wp-includes/
  /wp-includes/foo.php
  /wp-includes/foo.php?bar=123
  /foo/wp-includes/
  /foo/wp-content/
  /foo/wp-includes/foo.php
  /foo/wp-content/foo.php
  /foo/wp-includes/foo.php?bar=123
  /.git/config
  /foo/.git/config
  /foo/.git/HEAD
  /foo/db.sql
  /foo/db.sql.gz
  /.well-known/whatever
  /foo/.well-known/whatever
  /index.xml
  /foo/wlwmanifest.xml
  /_ts/
  /_ts_sites/
  /_sites/foo
  /known-elephant
'

max_len=0
for path in $PATHS; do
  ((${#path} > max_len)) && max_len=${#path}
done

printf "%-${max_len}s  %s\n" "Path" "Matched"
printf "%-${max_len}s  %s\n" "----" "-------"

for path in $PATHS; do
  printf "%-${max_len}s     " $path

  content=$(curl -s -k "$TIDDLYHOST$path")

  # Nginx 404 page is short and basic
  grep -q '<center><h1>404 Not Found</h1></center>' <<<"$content" && echo -e "\e[32m✓\e[0m"

  # Rails 404 page is longer and prettier
  grep -q 'You may have mistyped the address' <<<"$content" && echo -e "\e[31m🗴\e[0m"

  # Local rails shows the exception
  grep -q '<title>Action Controller: Exception caught</title>' <<<"$content" && echo -e "\e[31m🗴\e[0m"
done
