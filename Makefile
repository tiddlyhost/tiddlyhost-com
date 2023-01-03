MAKEFLAGS+=--no-print-directory

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

#----------------------------------------------------------

# The idea here is that I want to pin the base image in Dockerfile.base
# for reproducibility but also have an easy way to keep it updated when
# a new version is available.
#
DOCKER_FILE=docker/Dockerfile.base
RUBY_TAG=3.1-slim

pull-ruby:
	$(D) pull ruby:$(RUBY_TAG)

check-digest:
	@\
	export BASE_IMAGE_WITH_DIGEST="$$( \
	  $(D) image inspect ruby:3.1-slim --format '{{index .RepoDigests 0}}' | sed 's/ruby@/ruby:$(RUBY_TAG)@/' )" && \
	export REQUIRED="FROM $${BASE_IMAGE_WITH_DIGEST}" && \
	export CURRENT=$$( grep -E '^FROM' $(DOCKER_FILE) ) && \
	\
	if [[ "$$REQUIRED" == "$$CURRENT" ]]; then \
	  echo "$${CURRENT} is correct for ruby:$(RUBY_TAG)"; \
	else \
	  echo "Please update $(DOCKER_FILE) as follows:" && \
	  echo "-$${CURRENT}" && \
	  echo "+$${REQUIRED}" && \
	  exit 1; \
	fi

# Build base docker image
# (The build args are important here, the build will fail without them)
build-base: cleanup pull-ruby check-digest
	$(DC) build --no-cache --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) app

# Use this if you're hacking on docker/Dockerfile.base and building repeatedly
fast-build-base:
	$(DC) build --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) app

# There's no need to run db:migrate for CI because the tests don't need it
rails-init-ci:
	mkdir -p docker/postgresql-data docker/bundle node_modules
	$(DC) run --rm app bash -c "bin/bundle install && bin/rails yarn:install && bin/rails db:create"

# To set up your environment right after doing a git clone
rails-init: rails-init-ci
	$(DC) run --rm app bash -c "bin/rails db:migrate"

#----------------------------------------------------------

docker/secrets:
	@mkdir -p $@

docker/secrets/master.key: docker/secrets
	@cp rails/config/master.key $@

docker/secrets/credentials.yml.enc: docker/secrets
	@cp rails/config/credentials.yml.enc $@

prod-secrets: docker/secrets/master.key docker/secrets/credentials.yml.enc

PROD_PRERELEASE=docker/config/prerelease.html
$(PROD_PRERELEASE):
	curl -s https://tiddlywiki.com/prerelease/empty.html -o $@

prod-prerelease: $(PROD_PRERELEASE)

#----------------------------------------------------------

# Fun way to reuse the ansible templates to create local config
docker/%: ansible/templates/docker/%.j2
	@mkdir -p $$(dirname $@)
	@env primary_host=tiddlyhost.local tiddlyspot_host=tiddlyspot.local \
	  python -c "import os,sys,jinja2; print(jinja2.Template(sys.stdin.read()).render(os.environ))" \
	  < $< > $@
	@echo $@ created using $<

local-nginx: docker/nginx-conf/app.conf docker/nginx-conf/commonconf
local-rails: docker/config/settings_local.yml

local-config: local-nginx local-rails

#----------------------------------------------------------

# Brings up the web container only and runs bash in it
run-base:
	-$(DC) run --rm --no-deps app bash

# Brings up the db and the web container and runs bash in the web container
shell:
	-$(DC) run --rm app bash

# Figure out if there's already a container running and use exec or run accordingly
EXEC_OR_RUN=$(shell [[ $$($(DC) ps --services --filter status=running | grep app ) ]] && echo 'exec' || echo 'run --rm')
D=docker
DC=docker-compose
DC_PROD=docker-compose -f docker-compose-prod.yml
DCC=-$(DC) $(EXEC_OR_RUN) app bash -c

join:
	$(DCC) bash

sandbox:
	$(DCC) 'bin/rails console --sandbox'

console:
	$(DCC) 'bin/rails console'

docker/log:
	mkdir -p docker/log

app-log: docker/log

#----------------------------------------------------------

# Start Tiddlyhost locally - app only, no container, no SSL
db-start:
	@$(DC) up --detach db

db-stop:
	$(DC) stop

rstart: db-start
	@cd rails && bundle install && rails s

rtest: db-start
	@cd rails && bundle install && rails t

#----------------------------------------------------------

# Start Tiddlyhost locally - containerized full stack with SSL
start: local-config cert app-log
	-$(DC) up

#----------------------------------------------------------

# Run bundle-install
bundle-install:
	@mkdir -p docker/bundle
	-$(DC) run --rm --no-deps app bash -c "bin/bundle install"

# Run bundle-update
bundle-update:
	-$(DC) run --rm --no-deps app bash -c "bin/bundle update --quiet"

# Run bundle-clean
bundle-clean:
	-$(DC) run --rm --no-deps app bash -c "bin/bundle clean"

# Run yarn install
yarn-install:
	-$(DC) run --rm --no-deps app bash -c "bin/yarn install"

# Run yarn upgrade
yarn-upgrade:
	-$(DC) run --rm --no-deps app bash -c "bin/yarn upgrade --silent --no-progress"

# Update deps and make a commit
LOCK_FILES=rails/Gemfile.lock rails/yarn.lock
deps-update: bundle-update yarn-upgrade
	git add $(LOCK_FILES)
	git commit $(LOCK_FILES) -m 'Update ruby and node dependencies' -m 'Commit created with `make deps-update`'

#----------------------------------------------------------

# View or edit encrypted secrets
# (Beware this is not the same as --environment=production)
#
secrets:
	-$(DC) run --rm --no-deps app bash -c "EDITOR=vi bin/rails credentials:edit"

dump-secrets:
	-@$(DC) run --rm --no-deps app bash -c "EDITOR=cat bin/rails credentials:edit" | head -n -1

devel-secrets:
	-$(DC) run --rm --no-deps app bash -c "EDITOR=vi bin/rails credentials:edit --environment=development"

devel-dump-secrets:
	-@$(DC) run --rm --no-deps app bash -c "EDITOR=cat bin/rails credentials:edit --environment=development" | head -n -1

#----------------------------------------------------------

# Run test suite
test:
	$(DCC) 'bin/rails test:all'

test-ci:
	$(DC) run --rm app bash -c "bin/rails test:all"

coverage:
	$(DCC) 'env COVERAGE=1 bin/rails test:all'

tests: test

onetest:
	$(DCC) 'bin/rails test $(TEST)'

#----------------------------------------------------------

# (Use these if you want to run the prod container locally)
shell-prod: local-config prod-secrets prod-prerelease
	-$(DC_PROD) run --rm app bash

join-prod:
	-$(DC_PROD) exec app bash -c bash

start-prod: local-config prod-secrets prod-prerelease
	-$(DC_PROD) up

#----------------------------------------------------------

# Stop and remove containers, clean up unused images
cleanup:
	$(DC) stop
	$(DC_PROD) stop
	$(DC) rm -f
	$(DC_PROD) rm -f
	$(D) image prune -f

#----------------------------------------------------------

# Get the email confirmation link when you sign up a new user locally.
# Grep them in the plain text part of the email.
#
signup-link:
	@$(DCC) 'grep "tiddlyhost.local/users/confirmation?confirmation_token=" log/development.log | grep -v "Started GET" | tail -1 | cut -d" " -f2'

# Get the reset password link after clicking "Forgot your password?" locally
#
forgot-link:
	@$(DCC) 'grep "tiddlyhost.local/users/password/edit?reset_password_token=" log/development.log | grep -v "Started GET" | tail -1 | cut -d" " -f2'

#----------------------------------------------------------

EMPTY_DIR=rails/tw_content/empties

download-empties:
	@mkdir -p $(EMPTY_DIR)
	@$(PLAY) ansible/fetch_empties.yml

# Now that we have Feather Wiki included in ansible/fetch_empties
# this isn't used regularly, but keep it in case I ever want to
# build my own Feather Wiki empty for some reason.
#
FEATHER_BUILD=../FeatherWiki/builds/FeatherWiki_Warbler.html
FEATHER_EMPTY=$(EMPTY_DIR)/feather.html
$(FEATHER_EMPTY): $(FEATHER_BUILD)
	@mkdir -p $(EMPTY_DIR)
	cp $? $@

feather-empty: $(FEATHER_EMPTY)

refresh-empties: empty-versions clear-empties download-empties

clear-empties:
	@rm -rf $(EMPTY_DIR)/*.html

empty-versions:
	@$(DCC) 'bin/rails runner "puts Empty.versions.to_yaml"' \
	  | grep -v 'Spring preloader' | grep -v '\-\-\-'

#----------------------------------------------------------

TW5_REPO=git@github.com:Jermolene/TiddlyWiki5.git
TW5_DIR=../TiddlyWiki5
TW5_OUTPUT=$(TW5_DIR)/output/external-core

TW5_UGLIFY_REPO=git@github.com:flibbles/tw5-uglify.git
TW5_UGLIFY_DIR=../tw5-uglify

EXTERNAL_CORE_EMPTY_NAME=tw5x

clean-external-core-files:
	rm -rf $(TW5_OUTPUT)

$(TW5_DIR):
	mkdir -p $(TW5_DIR) && cd $(TW5_DIR) && git clone $(TW5_REPO) .

$(TW5_UGLIFY_DIR):
	mkdir -p $(TW5_UGLIFY_DIR) && cd $(TW5_UGLIFY_DIR) && git clone $(TW5_UGLIFY_REPO) .

# Do some work to build these files from source.
# Maybe in future they will be built automatically and
# made available somewhere.
#
create-external-core-files-%: $(TW5_DIR) $(TW5_UGLIFY_DIR) clean-external-core-files
	cd $(TW5_DIR) && git reset --hard && git checkout v$* && \
	  node tiddlywiki.js editions/empty \
	    --output $(TW5_OUTPUT) \
	    --rendertiddler '$$:/core/save/offline-external-js' 'empty.html' 'text/plain' && \
	  export TIDDLYWIKI_PLUGIN_PATH=$(TW5_UGLIFY_DIR) && \
	  node tiddlywiki.js +plugins/plugins/uglify editions/empty \
	    --output $(TW5_OUTPUT) \
	    --render '$$:/core/templates/tiddlywiki5.js' '[[tiddlywikicore-]addsuffix<version>addsuffix[.min.js]]' 'text/plain'
# Todo maybe: Uglify the empty as well

external-core-files-%: create-external-core-files-%
	# Use the .min.js uglified version
	cp $(TW5_OUTPUT)/tiddlywikicore-$*.min.js rails/public/tiddlywikicore-$*.js
	# Copy the empty to two places
	cp $(TW5_OUTPUT)/empty.html $(EMPTY_DIR)/$(EXTERNAL_CORE_EMPTY_NAME).html
	cp $(TW5_OUTPUT)/empty.html $(EMPTY_DIR)/$(EXTERNAL_CORE_EMPTY_NAME)/$*.html

# Should be no need to rebuild older versions
#  external-core-files-5.2.3 \
#  external-core-files-5.2.4 \
#
external-core-files: \
  external-core-files-5.2.5

# Run this at build time since I don't want to check in the gzipped files
gzip-core-js-files:
	@for f in $$( ls rails/public/tiddlywikicore-*.js ); do \
	  gzip -c $$f > $$f.gz; \
	  echo Created $$f.gz; \
	done

#----------------------------------------------------------

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
CERTS_DIR=docker/certs
cert: $(CERTS_DIR)/fullchain.pem

$(CERTS_DIR)/fullchain.pem:
	@bin/create-local-ssl-cert.sh $(CERTS_DIR)

clear-cert:
	@rm -f $(CERTS_DIR)/privkey.pem
	@rm -f $(CERTS_DIR)/fullchain.pem

redo-cert: clear-cert cert

#----------------------------------------------------------


build-info:
	@bin/create-build-info.sh | tee rails/public/build-info.txt

prod-assets:
	-$(DC) run --rm --no-deps app bash -c "RAILS_ENV=production bin/rails assets:clean assets:precompile"

# Create a throwaway key and secret because rails will not start without one.
# See https://github.com/rails/rails/issues/32947
#
prod-assets-ci:
	-$(DC) run --rm --no-deps app bash -c "\
	  EDITOR=: bin/rails credentials:edit && \
	  RAILS_ENV=production bin/rails assets:clean assets:precompile"

build-prod: bundle-install bundle-clean prod-assets build-info js-math download-empties gzip-core-js-files
	$(DC_PROD) build app

# FIXME: js-math download is broken
# FIXME: download-empties requires ansible
build-prod-ci: bundle-install bundle-clean prod-assets-ci build-info gzip-core-js-files
	$(DC_PROD) build app

fast-build-prod: prod-assets build-info
	$(DC_PROD) build app

push-prod:
	$(D) --config etc/docker-conf push sbaird/tiddlyhost

# Fixme: There are too many options here...
build-push:            tests build-prod push-prod
build-full-deploy:     build-push full-deploy
build-deploy:          build-push deploy-app
build-upgrade:         build-push upgrade
fast-build-upgrade:    build-push fast-upgrade
faster-build-upgrade:  build-push faster-upgrade
fastest-build-upgrade: fast-build-prod push-prod faster-upgrade

ifdef LIMIT
  LIMIT_OPT=-l $(LIMIT)
endif
PLAY = ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory.yml $(LIMIT_OPT) $(V)

full-deploy:
	$(PLAY) ansible/deploy.yml

deploy-deps:
	$(PLAY) ansible/deploy.yml --tags=deps

deploy-certs:
	$(PLAY) ansible/deploy.yml --tags=certs

deploy-scripts:
	$(PLAY) ansible/deploy.yml --tags=scripts

refresh-prerelease:
	$(PLAY) ansible/deploy.yml --tags=refresh-prerelease

deploy-app:
	$(PLAY) ansible/deploy.yml --tags=app

deploy-app-bootstrap:
	$(PLAY) ansible/deploy.yml --tags=app,db-create

deploy-cleanup:
	$(PLAY) ansible/deploy.yml --tags=cleanup

# If you want to run selected tasks givem them the foo tag
deploy-foo:
	$(PLAY) ansible/deploy.yml --tags=foo --diff

upgrade:
	$(PLAY) ansible/deploy.yml --tags=app --extra-var fast_restart=true

fast-upgrade:
	$(PLAY) ansible/deploy.yml --tags=fast-upgrade --extra-var fast_restart=true

faster-upgrade:
	$(PLAY) ansible/deploy.yml --tags=fast-upgrade --skip-tags=migration --extra-var fast_restart=true

#----------------------------------------------------------

TIMESTAMP := $(shell date +%Y%m%d%H%M%S)

BACKUPS_DIR=../thost-backups
S3_BACKUPS=$(BACKUPS_DIR)/s3
DB_BACKUPS=$(BACKUPS_DIR)/db

db-backup:
	mkdir -p $(DB_BACKUPS)/$(TIMESTAMP)
	$(PLAY) ansible/backup.yml -e local_backup_subdir=$(TIMESTAMP) --limit=prod
	ls -l $(DB_BACKUPS)/$(TIMESTAMP)
	zcat $(DB_BACKUPS)/$(TIMESTAMP)/dbdump.gz | grep '^-- ' | head -3
	du -h -s $(DB_BACKUPS)/$(TIMESTAMP)
	du -h -s $(DB_BACKUPS)

s3-bucket-name:
	@[[ ! -z "$$BUCKET_NAME" ]] || ( echo "BUCKET_NAME not set!" && exit 1 )

# Assume you have suitable s3 credentials available

# Copy down new versions of sites, keeping old versions locally
s3-backup: s3-bucket-name
	aws s3 sync s3://$(BUCKET_NAME) $(S3_BACKUPS)/latest
	du -h $(S3_BACKUPS)

# Copy down new versions of sites, removing old versions locally
s3-backup-and-prune: s3-bucket-name
	aws s3 sync s3://$(BUCKET_NAME) $(S3_BACKUPS)/latest --delete
	du -h $(S3_BACKUPS)

# Ineffiently copy down everything to a timestamp directory
# Deprecated. Use s3-snapshot-and-prune instead.
s3-full-snapshot: s3-bucket-name
	aws s3 sync s3://$(BUCKET_NAME) $(S3_BACKUPS)/$(TIMESTAMP)
	du -h $(S3_BACKUPS)

s3-local-timestamped-copy:
	cp -r $(S3_BACKUPS)/latest $(S3_BACKUPS)/latest-$(TIMESTAMP)

# Keep some deleted sites, but try not to keep multiples of them
s3-snapshot-and-prune: s3-backup s3-local-timestamped-copy s3-backup-and-prune

show-backups:
	@du -h $(BACKUPS_DIR)

show-latest-db-backup:
	@NEWEST=$$( ls -t $(DB_BACKUPS) | head -1 ) && \
	  ls -l $(DB_BACKUPS)/$$NEWEST && \
	  zcat $(DB_BACKUPS)/$$NEWEST/dbdump | wc -l && \
	  zcat $(DB_BACKUPS)/$$NEWEST/dbdump | head && \
	  echo . && echo . && echo . && \
	  zcat $(DB_BACKUPS)/$$NEWEST/dbdump | tail -4

# Example usage:
#   make s3-extract FILEKEY=bc1viib59bbw3cpqvvd2x7dnth9b
s3-extract:
	openssl zlib -d -in $(S3_BACKUPS)/latest/$(FILEKEY) > $(FILEKEY).html

full-backup: db-backup s3-backup
full-backup-and-snapshot: db-backup s3-snapshot-and-prune

#----------------------------------------------------------

# For credentials: source etc/openrc.sh
openstack-info:
	openstack server show thost

# If you can't ping then...
openstack-reboot:
	openstack server reboot thost

openstack-reboot-hard:
	openstack server reboot --hard thost

#----------------------------------------------------------

PROD_INFO_URL=https://tiddlyhost.com/build-info.txt
prod-info:
	@echo '## Prod build info'
	@-curl -s $(PROD_INFO_URL)
	@echo ''
	@echo '## Diff to prod'
	@-git diff --color=always $$(curl -s $(PROD_INFO_URL) | grep 'sha:' | cut -d: -f2) | less -REXS

#----------------------------------------------------------
JS_MATH_DOWNLOADS=http://www.math.union.edu/~dpvc/jsmath/download
JS_MATH_ZIP=jsMath-3.3g.zip
JS_MATH_FONTS_ZIP=jsMath-fonts-1.2.zip

$(JS_MATH_ZIP):
	@echo "Please download $(JS_MATH_DOWNLOADS)/$(JS_MATH_ZIP)"

$(JS_MATH_FONTS_ZIP):
	@echo "Please download $(JS_MATH_DOWNLOADS)/$(JS_MATH_FONTS_ZIP)"

rails/public/jsMath/jsMath.js: ./$(JS_MATH_ZIP) ./$(JS_MATH_FONTS_ZIP)
	@# For some reason the curl download doesn't work any more
	@#curl -sO http://www.math.union.edu/~dpvc/jsmath/download/$(JS_MATH_ZIP)
	@#curl -sO http://www.math.union.edu/~dpvc/jsmath/download/$(JS_MATH_FONTS_ZIP)
	cd rails/public && unzip ../../$(JS_MATH_ZIP)
	cd rails/public/jsMath && unzip ../../../$(JS_MATH_FONTS_ZIP)
	@touch rails/public/jsMath/jsMath.js # so make doesn't think it's stale

js-math: rails/public/jsMath/jsMath.js

js-math-clean:
	rm -rf rails/public/jsMath

#----------------------------------------------------------

/tmp/Simon\ Baird.png:
	@curl -s -o '$@' \
	  https://www.gravatar.com/avatar/bfaba91f41f0c01aba1ef0751458b537

gource-image: /tmp/Simon\ Baird.png

pretty-colors: gource-image
	@SDL_VIDEODRIVER=x11 gource \
	  --user-image-dir /tmp \
	  --seconds-per-day 0.07 \
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
	  --file-font-size 5 \
	  --bloom-multiplier 0.2 \
	  --bloom-intensity 0.2 \
	  --filename-colour 555555 \
	  --dir-colour 555555 \
	  ;
