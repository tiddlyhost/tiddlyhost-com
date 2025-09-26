#!/bin/bash

# Test script for nginx crawler blocking mechanism
# Usage: ./test_nginx_blocking.sh [tag_name]

TAG=asdf
USER=bob
BASE_URL="https://tiddlyhost.local"

function check_url() {
  local url="$1"
  local referer="${2:-""}"

  printf "%-40s %-30s" $url $referer
  if [ -n "$referer" ]; then
    curl -I -k -H "Referer: $referer" "$BASE_URL$url" 2>/dev/null | grep HTTP
  else
    curl -I -k "$BASE_URL$url" 2>/dev/null | grep HTTP
  fi
}

printf "%-40s %-30s%s\n" "URL" "REFERER" "RESPONSE"
printf "%-40s %-30s%s\n" "---" "-------" "--------"

printf "** Should be 200\n"
check_url "/explore"
check_url "/explore/"
check_url "/explore/tag/$TAG"
check_url "/explore/user/$USER"

check_url "/templates/?t=1"
check_url "/templates/tag/$TAG?t=1"
check_url "/templates/user/$USER?t=1"

printf "\n** Should be 404 due missing referer\n"
check_url "/explore/tag/$TAG?k=tw&s=c"
check_url "/explore/user/$USER?k=tw&s=c"
check_url "/templates/tag/$TAG?t=1&k=tw&s=c"
check_url "/templates/user/$USER?t=1&k=tw&s=c"

printf "\n** Should be 200 because there is a referer\n"
check_url "/explore/tag/$TAG?k=tw&s=c" $BASE_URL
check_url "/explore/user/$USER?k=tw&s=c" $BASE_URL
check_url "/templates/tag/$TAG?t=1&k=tw&s=c" $BASE_URL
check_url "/templates/user/$USER?t=1&k=tw&s=c" $BASE_URL

printf "\n** Should be 200 also because actually any referer is fine currently\n"
check_url "/explore/tag/$TAG?k=tw&s=c" example.com
check_url "/explore/user/$USER?k=tw&s=c" example.com
check_url "/templates/tag/$TAG?t=1&k=tw&s=c" example.com
check_url "/templates/user/$USER?t=1&k=tw&s=c" example.com

printf "\n** Should be a 302 due to the weird t=1 thing\n"
check_url "/templates/tag/$TAG" $BASE_URL
check_url "/templates/tag/$TAG?k=tw" $BASE_URL

printf "\n** Edge case, a /templates url without t=1, should be a 404 I guess\n"
check_url "/templates/tag/$TAG?k=tw"
