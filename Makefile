
_help:
	@echo Available tasks:
	@grep '^[^_#[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

# The build args are important here, the build will fail without them
build-base: cleanup cert
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

rails-init:
	docker-compose run --rm base bash -c "bundle install && \
	  bundle exec rails webpacker:install && \
	  bundle exec rails db:create && \
	  bundle exec rails db:migrate"

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

bundle-install:
	-docker-compose run --rm --no-deps base bash -c "bin/bundle install"

secrets:
	-docker-compose run --rm --no-deps base bash -c "EDITOR=vi bin/rails credentials:edit"

# Try to be smart about how to run the tests
# TODO: Refactor and integrate with "shell" and "join"
tests:
	@if [[ -z $$(docker-compose ps --services --filter status=running | grep base ) ]]; then \
	  echo Starting new container to run tests...; \
	  docker-compose run --rm base bin/rails test\:all; \
	else \
	  echo Running tests in existing container...; \
	  docker-compose exec base bin/rails test\:all; \
	fi

# Stop and remove containers
cleanup:
	docker-compose stop
	docker-compose rm -f

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
cert: etc/certs/localssl.cert

etc/certs/localssl.cert:
	@cd ./etc && ./create-local-ssl-cert.sh

clear-cert:
	@rm ./etc/certs/localssl.cert
	@rm ./etc/certs/localssl.key

redo-cert: clear-cert cert

github-url:
	@echo https://github.com/simonbaird/tiddlyhost
