#!/bin/bash

# Clear stale pid
rm -f tmp/pids/server.pid

# Start rails
if [[ "$RAILS_ENV" != "production" && "$START_WITHOUT_SSL" == "yes" ]]; then
  exec bin/rails s -p 3333 -b '0.0.0.0'
else
  exec bin/rails s -p 3333 -b 'ssl://0.0.0.0?key=/opt/certs/ssl.key&cert=/opt/certs/ssl.cert'
fi
