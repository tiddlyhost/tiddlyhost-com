#!/bin/bash

# Run delayed job
# Todo maybe: multiple workers
exec bin/delayed_job -n 1 run
