#!/bin/bash

# Clear stale pid
rm -f tmp/pids/server.pid

# Start rails
exec bin/rails s -p 3000 -b 'ssl://0.0.0.0?key=/opt/certs/localssl.key&cert=/opt/certs/localssl.cert'
