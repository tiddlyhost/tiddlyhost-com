
# Show a list of available tasks
_help:
	@echo Available tasks:
	@grep '^[^_#\\$$[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

#----------------------------------------------------------

# Build base docker image
# (The build args are important here, the build will fail without them)
build-base: cleanup cert
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

# Set up your environment right after git clone
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

# Figure out if there's already a container running and use exec or run accordingly
EXEC_OR_RUN=$(shell [[ $$(docker-compose ps --services --filter status=running | grep base ) ]] && echo 'exec' || echo 'run --rm')
DCC=-docker-compose $(EXEC_OR_RUN) base bash -c

join:
	$(DCC) bash

sandbox:
	$(DCC) 'bin/rails console --sandbox'

console:
	$(DCC) 'bin/rails console'

# Start Tiddlyhost locally
start:
	-docker-compose up

# Run bundle-install
bundle-install:
	-docker-compose run --rm --no-deps base bash -c "bin/bundle install"

# View or edit encrypted secrets
secrets:
	-docker-compose run --rm --no-deps base bash -c "EDITOR=vi bin/rails credentials:edit"

# Run test suite
tests:
	$(DCC) 'bin/rails test:all'

# (Use these if you want to run the prod container locally)
shell-prod:
	-docker-compose -f docker-compose-prod.yml run --rm prod bash

join-prod:
	-docker-compose -f docker-compose-prod.yml exec prod bash -c bash

start-prod:
	-RAILS_MASTER_KEY=`cat rails/config/master.key` docker-compose -f docker-compose-prod.yml up

# Stop and remove containers, clean up unused images
cleanup:
	docker-compose stop
	docker-compose rm -f
	docker image prune -f

#----------------------------------------------------------

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

#----------------------------------------------------------

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
cert: certs/ssl.cert

certs/ssl.cert:
	@cd ./etc && ./create-local-ssl-cert.sh

clear-cert:
	@rm -f ./certs/ssl.cert
	@rm -f ./certs/ssl.key

redo-cert: clear-cert cert

#----------------------------------------------------------

build-info:
	./etc/create-build-info.sh

build-prod: build-info
	docker-compose -f docker-compose-prod.yml build --build-arg APP_VERSION_BUILD=$$( git log -n1 --format=%h ) prod

push-prod:
	docker --config etc/docker-conf push sbaird/tiddlyhost

build-push:          tests build-prod push-prod
full-build-deploy:   cleanup build-base build-push full-deploy
build-deploy:        build-push deploy-app
fast-build-deploy:   build-push fast-upgrade
faster-build-deploy: build-push faster-upgrade

PLAY = ansible-playbook -i ansible/inventory.yml $(V)

full-deploy:
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

prod-ssh:
	@ssh fedora@tiddlyhost.com

#----------------------------------------------------------

TIMESTAMP := $(shell date +%Y%m%d%H%M%S)

db-backup:
	mkdir -p backups/db/$(TIMESTAMP)
	$(PLAY) -v ansible/backup.yml -e local_backup_subdir=$(TIMESTAMP)
	du -h backups

# Assume you have suitable credentials available
s3-backup:
	aws s3 sync s3://$(BUCKET_NAME) ./backups/s3/$(TIMESTAMP)
	cd ./backups/s3/$(TIMESTAMP) && gzip -v *
	du -h backups

show-backups:
	@du -h backups

#----------------------------------------------------------

# For credentials: source etc/openrc.sh
openstack-info:
	openstack server show thost
