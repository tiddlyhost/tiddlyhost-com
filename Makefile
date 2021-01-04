
_help:
	@echo Available tasks:
	@grep '^[^_#[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

build-base:
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

# Just for poking around...
run-base:
	-docker-compose run --rm --no-deps base bash

github-url:
	@echo https://github.com/simonbaird/tiddlyhost
