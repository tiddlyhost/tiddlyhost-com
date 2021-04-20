#!/bin/bash
# See https://lzone.de/cheat-sheet/memcached

MEMCACHED_IP=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' th_cache)
MEMCACHED_PORT=11211

MEMCACHED_COMMAND=$*
[[ -z "$MEMCACHED_COMMAND" ]] && MEMCACHED_COMMAND=stats

echo $MEMCACHED_COMMAND | nc $MEMCACHED_IP $MEMCACHED_PORT
