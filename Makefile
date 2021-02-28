
_help:
	@echo Available tasks:
	@grep '^[^_#\\$$[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

# The build args are important here, the build will fail without them
build-base: cleanup cert
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

build-prod:
	./etc/create-build-info.sh
	docker-compose -f docker-compose-prod.yml build prod

push-prod:
	docker --config etc/docker-conf push sbaird/tiddlyhost

build-deploy: tests build-prod push-prod deploy-app

full-build-deploy: cleanup build-base tests build-prod push-prod deploy

rails-init:
	mkdir -p .postgresql-data
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

# Same thing but use the prod container
shell-prod:
	-docker-compose -f docker-compose-prod.yml run --rm prod bash

# Runs bash in an already running web container
join:
	-docker-compose exec base bash

# Same thing but use the prod container
join-prod:
	-docker-compose -f docker-compose-prod.yml exec prod bash

# Start the dev container
start:
	-docker-compose up

# Start the prod container locally
start-prod:
	-RAILS_MASTER_KEY=`cat rails/config/master.key` docker-compose -f docker-compose-prod.yml up

bundle-install:
	-docker-compose run --rm --no-deps base bash -c "bin/bundle install"

secrets:
	-docker-compose run --rm --no-deps base bash -c "EDITOR=vi bin/rails credentials:edit"

# Currently we need the prerelease, later we'll switch to stable versions
EMPTY_URL=https://tiddlywiki.com/prerelease/empty.html
EMPTY_TARGET=rails/empties/tw5.html
$(EMPTY_TARGET):
	curl -s $(EMPTY_URL) -o $(EMPTY_TARGET)

empty: $(EMPTY_TARGET) empty-version

update-empty: clear-empty empty

empty-version:
	@grep '<meta name="tiddlywiki-version"' $(EMPTY_TARGET) | cut -d\" -f4

clear-empty:
	@rm -f $(EMPTY_TARGET)

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

# Stop and remove containers, clean up unused images
cleanup:
	docker-compose stop
	docker-compose rm -f
	docker image prune -f

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
cert: certs/ssl.cert

certs/ssl.cert:
	@cd ./etc && ./create-local-ssl-cert.sh

clear-cert:
	@rm -f ./certs/ssl.cert
	@rm -f ./certs/ssl.key

redo-cert: clear-cert cert

github-url:
	@echo https://github.com/simonbaird/tiddlyhost

PLAY = ansible-playbook -i ansible/inventory.yml $(V)

deploy:
	$(PLAY) ansible/deploy.yml

deploy-deps:
	$(PLAY) ansible/deploy.yml --tags=deps

deploy-certs:
	$(PLAY) ansible/deploy.yml --tags=certs

deploy-app:
	$(PLAY) ansible/deploy.yml --tags=app

deploy-scripts:
	$(PLAY) ansible/deploy.yml --tags=scripts

fast-upgrade:
	$(PLAY) ansible/deploy.yml --tags=fast-upgrade

faster-upgrade:
	$(PLAY) ansible/deploy.yml --tags=fast-upgrade --skip-tags=migration

db-backup:
	mkdir -p backups
	$(PLAY) -v ansible/backup.yml
	ls -l backups

#
# Assume you have suitable credentials available
#
s3-backup:
	aws s3 sync s3://$(BUCKET_NAME) ./s3-backup

prod-ssh:
	@ssh fedora@tiddlyhost.com

#
# For credentials:
#   source etc/openrc.sh
#
openstack-info:
	openstack server show thost
