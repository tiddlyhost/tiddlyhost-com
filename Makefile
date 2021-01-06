
_help:
	@echo Available tasks:
	@grep '^[^_#[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

# The build args are important here, the build will fail without them
build-base: cleanup
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

# Brings up the web container only and runs bash in it
run-base:
	-docker-compose run --rm --no-deps base bash

# Brings up the db and the web container and runs bash in the web container
shell:
	-docker-compose run --rm base bash

# Runs bash in an already running web container
join:
	-docker-compose exec base bash

# Not sure if we really need this...
start:
	-docker-compose up

# Stop and remove containers
cleanup:
	docker-compose stop
	docker-compose rm -f

github-url:
	@echo https://github.com/simonbaird/tiddlyhost
