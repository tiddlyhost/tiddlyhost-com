#!/bin/bash

# Clear stale pid
rm -f tmp/pids/server.pid

# Start rails
exec bin/rails s -p 3333 -b '0.0.0.0'
