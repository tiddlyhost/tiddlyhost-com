#!/bin/bash

(
  echo date: $( date )
  echo sha: $( git log -n1 --format=%H )
  echo build_number: $( git rev-list --count $( git describe --tags --abbrev=0 )..HEAD )
  echo commit: "\"$( git log -n1 --format=%s )\""
  echo branch: $( git rev-parse --abbrev-ref HEAD )
)
