
# Show a list of available tasks
_help:
	@echo Available tasks:
	@grep '^[^_#\\$$[:space:]][^=/[:space:]]*:' Makefile | cut -d: -f1 | xargs -n1 echo ' make'

#----------------------------------------------------------

# On Mac my user's main group id is too low and I get this:
#   addgroup: The GID `20' is already in use.
# Fix it by setting a higher group id, e.g.:
#   GROUP_ID=501 make build-base
# The number shouldn't matter too much.
USER_ID ?= $(shell id -u)
GROUP_ID ?= $(shell id -g)

# Build base docker image
# (The build args are important here, the build will fail without them)
build-base: cleanup cert
	docker-compose build --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) base

# Set up your environment right after git clone
rails-init:
	mkdir -p docker/postgresql-data
	docker-compose run --rm base bash -c "bundle install && \
	  bundle exec rails webpacker:install && \
	  bundle exec rails db:create && \
	  bundle exec rails db:migrate"

#----------------------------------------------------------

# Create two sets of nginx config files from templates
# (Todo: Figure out how to combine the two rules into one..)
#
docker/nginx-conf-prod/%: docker/nginx-%
	@bin/create-nginx-conf.sh $< $@

docker/nginx-conf-local/%: docker/nginx-%
	@bin/create-nginx-conf.sh $< $@

nginx-conf-prod:  docker/nginx-conf-prod/app.conf  docker/nginx-conf-prod/commonconf  docker/nginx-conf-prod/proxyconf
nginx-conf-local: docker/nginx-conf-local/app.conf docker/nginx-conf-local/commonconf docker/nginx-conf-local/proxyconf
nginx-conf: nginx-conf-local nginx-conf-prod

nginx-conf-clear:
	rm -rf docker/nginx-conf-prod docker/nginx-conf-local

nginx-conf-refresh: nginx-conf-clear nginx-conf

#----------------------------------------------------------

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
start: nginx-conf-local
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

start-prod: nginx-conf-prod
	-RAILS_MASTER_KEY=`cat rails/config/master.key` docker-compose -f docker-compose-prod.yml up

# Stop and remove containers, clean up unused images
cleanup:
	docker-compose stop
	docker-compose rm -f
	docker image prune -f

# Use this when you sign up a new user
signup-link:
	@$(DCC) 'cat log/development.log | grep "Confirm my account" | tail -1 | cut -d\" -f2'

#----------------------------------------------------------

EMPTY_DIR=rails/tw_content/empties

download-empties:
	@mkdir -p $(EMPTY_DIR)
	@$(PLAY) -v ansible/fetch_empties.yml
	@$(MAKE) -s empty-versions

refresh-empties: empty-versions clear-empties download-empties

clear-empties:
	@rm -rf $(EMPTY_DIR)/*.html

empty-versions:
	@$(DCC) 'bin/rails runner "puts Empty.versions.to_yaml"' \
	  | grep -v 'Spring preloader' | grep -v '\-\-\-'

#----------------------------------------------------------

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
CERTS_DIR=docker/certs
cert: $(CERTS_DIR)/ssl.cert

$(CERTS_DIR)/ssl.cert:
	@bin/create-local-ssl-cert.sh $(CERTS_DIR)

clear-cert:
	@rm -f $(CERTS_DIR)/ssl.cert
	@rm -f $(CERTS_DIR)/ssl.key

redo-cert: clear-cert cert

#----------------------------------------------------------

build-info:
	@bin/create-build-info.sh | tee rails/public/build-info.txt

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

full-deploy: nginx-conf-prod
	$(PLAY) ansible/deploy.yml

deploy-deps:
	$(PLAY) ansible/deploy.yml --tags=deps

deploy-certs:
	$(PLAY) ansible/deploy.yml --tags=certs

deploy-scripts:
	$(PLAY) ansible/deploy.yml --tags=scripts

deploy-app: nginx-conf-prod
	$(PLAY) ansible/deploy.yml --tags=app

fast-upgrade: nginx-conf-prod
	$(PLAY) ansible/deploy.yml --tags=fast-upgrade

faster-upgrade: nginx-conf-prod
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
	@[[ ! -z "$$BUCKET_NAME" ]] || ( echo "BUCKET_NAME not set!" && exit 1 )
	aws s3 sync s3://$(BUCKET_NAME) ./backups/s3/$(TIMESTAMP)
	cd ./backups/s3/$(TIMESTAMP) && gzip -v *
	du -h backups

show-backups:
	@du -h backups

full-backup: db-backup s3-backup

#----------------------------------------------------------

# For credentials: source etc/openrc.sh
openstack-info:
	openstack server show thost

#----------------------------------------------------------

/tmp/Simon\ Baird.png:
	@curl -s -o '$@' \
	  https://www.gravatar.com/avatar/bfaba91f41f0c01aba1ef0751458b537

gource-image: /tmp/Simon\ Baird.png

pretty-colors: gource-image
	@gource \
	  --user-image-dir /tmp \
	  --seconds-per-day 0.3 \
	  --key \
	  --title 'Tiddlyhost Development' \
	  --fullscreen \
	  --frameless \
	  --auto-skip-seconds 0.3 \
	  --elasticity 0.1 \
	  --font-scale 5 \
	  --font-size 6 \
	  --dir-font-size 5 \
	  --user-font-size 5 \
	  --file-font-size 20 \
	  --bloom-multiplier 0.2 \
	  --bloom-intensity 0.2 \
	  --filename-colour 555555 \
	  --dir-colour 555555 \
	  ;
