#!/bin/bash

(
  echo date: `date`
  echo sha: `git log -n1 --format=%H`
  echo commit: `git log -n1 --format=%s`
  echo branch: `git rev-parse --abbrev-ref HEAD`
  echo tag: `git describe --tags --abbrev=0`
  echo empty: `make -s empty-version`
) > etc/build-info.txt

cp etc/build-info.txt rails/public/
