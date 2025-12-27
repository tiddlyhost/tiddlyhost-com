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

DOCKER_PUSH_ORG ?= docker.io/sbaird
DOCKER_PUSH_REPO ?= $(DOCKER_PUSH_ORG)/tiddlyhost
DOCKER_PUSH_REPO_BASE ?= $(DOCKER_PUSH_REPO)-base

#----------------------------------------------------------

# The idea here is that I want to pin the base image in Dockerfile.base
# for reproducibility but also have an easy way to keep it updated when
# a new version is available.
#
RUBY_VER=3.4
RUBY_TAG=$(RUBY_VER)-slim

# Set it to plain for detailed build output
ifdef PROGRESS
  PROGRESS_OPT=--progress $(PROGRESS)
endif

pull-ruby:
	$(D) pull ruby:$(RUBY_TAG)
	NO_COMMIT=1 bin/pin-digest.sh docker.io/library/ruby:$(RUBY_TAG) docker/Dockerfile.base "Newer ruby base image pulled from docker hub"

# Build base docker image
# (The build args are important here, the build will fail without them)
build-base:
	$(DC) $(PROGRESS_OPT) build --no-cache --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) app

# Use this if you're hacking on docker/Dockerfile.base and building repeatedly
fast-build-base:
	$(DC) $(PROGRESS_OPT) build --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) app

build-push-base: cleanup build-base push-base
	NO_COMMIT=1 bin/pin-digest.sh $(DOCKER_PUSH_REPO_BASE):latest docker/Dockerfile.prod "Tiddlyhost base image rebuilt"

# To set up your environment right after doing a git clone
# Beware: This command runs `rails db:setup` which will clear out your local database
DB_VOL_MOUNT=docker/postgresql-data/data16
APP_VOL_MOUNTS=docker/bundle docker/node_modules docker/log docker/config docker/secrets docker/dotcache
rails-init: build-info js-math download-empty-prerelease gzip-core-js-files
	mkdir -p $(DB_VOL_MOUNT) $(APP_VOL_MOUNTS)
	$(DC) run --rm app bash -c "bin/bundle install && bin/rails yarn:install && bin/rails db:setup"

# Identical to the above but with an extra chown command since the user id in
# the container doesn't match the local user id when running in GitHub workflow
rails-init-ci:
	mkdir -p $(DB_VOL_MOUNT) $(APP_VOL_MOUNTS)
	sudo chown $(USER_ID):$(GROUP_ID) -R rails $(APP_VOL_MOUNTS)
	$(DC) run --rm app bash -c "bin/bundle install && bin/rails yarn:install && bin/rails db:setup"

#----------------------------------------------------------

docker/secrets:
	@mkdir -p $@

docker/secrets/master.key: docker/secrets
	@cp rails/config/master.key $@

docker/secrets/credentials.yml.enc: docker/secrets
	@cp rails/config/credentials.yml.enc $@

prod-secrets: docker/secrets/master.key docker/secrets/credentials.yml.enc

#----------------------------------------------------------

# Fun way to reuse the ansible templates to create local config
docker/%: ansible/playbooks/templates/docker/%.j2
	@mkdir -p $$(dirname $@)
	@env primary_host=tiddlyhost.local tiddlyspot_host=tiddlyspot.local \
	  python -c "import os,sys,jinja2; print(jinja2.Template(sys.stdin.read()).render(os.environ))" \
	  < $< > $@
	@echo $@ created using $<

local-nginx: docker/nginx-conf/nginx.conf docker/nginx-conf/server-common.conf
local-rails: docker/config/settings_local.yml

local-config: local-nginx local-rails

#----------------------------------------------------------

# Brings up the web container only and runs bash in it
run-base:
	-$(DC) run --rm --no-deps app bash

# Brings up the db and the web container and runs bash in the web container
shell:
	-$(DC) run --rm app bash

D=docker
DC=docker compose
DC_PROD=docker compose -f docker-compose-prod.yml

# Figure out if there's already a container running and use exec or run accordingly
# Call it DCC for "Docker Compose Command"
EXEC_OR_RUN=$(shell [[ $$($(DC) ps --services --filter status=running | grep app ) ]] && echo 'exec' || echo 'run --rm')
DCCF=$(DC) $(EXEC_OR_RUN) app bash -c
DCC=-$(DCCF)

# This is faster if you don't need the database or anything else
# Let's call it DR for "Docker Run"
DRF=$(DC) run --rm --no-deps app bash -c
DR=-$(DRF)

join:
	$(DCC) bash

sandbox:
	$(DCC) 'bin/rails console --sandbox'

console:
	$(DCC) 'bin/rails console'

db-migrate:
	$(DCC) 'bin/rails db:migrate'

tmp-clear:
	$(DCC) 'bin/rails tmp:clear'

log-clear:
	$(DCC) 'rm -f log/*.log'

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
	$(DR) "bin/bundle install"

# Run bundle-update
bundle-update:
	$(DR) "bin/bundle update --all --quiet"

# Run bundle-clean
bundle-clean:
	$(DR) "bin/bundle clean"

app-update:
	$(DR) "bin/rails app:update"

# Run yarn install
yarn-install:
	$(DR) "bin/yarn install"

# Run yarn upgrade
yarn-upgrade:
	$(DR) "bin/yarn upgrade --silent --no-progress"

# For debugging assets build
assets-precompile:
	$(DR) "bin/rails assets:clean assets:precompile"

prod-assets-precompile:
	$(DR) "RAILS_ENV=production bin/rails assets:clean assets:precompile"

# Precompile the bootstrap email sass, see lib/tasks/bootstrap_email.rake
# Note: This was created initially because of the many SASS warnings which are
# now all fixed, see https://github.com/bootstrap-email/bootstrap-email/pull/282
# Keep it here anyway I guess.
bootstrap-email-sass-precompile:
	$(DR) "bin/rails bootstrap_email:sass_precompile"

# Update deps, make a commit, run tests
LOCK_FILES=rails/Gemfile.lock rails/yarn.lock
deps-update: pull-ruby build-push-base bundle-update yarn-upgrade
	git add $(LOCK_FILES)
	git commit -m 'chore: Refresh base images and update dependencies' \
	  -m 'Commit created with `make deps-update`'
	$(MAKE) bootstrap-email-sass-precompile test delint

#----------------------------------------------------------

haml-lint:
	$(DCCF) "bundle exec haml-lint"

rubocop:
	$(DRF) "bin/rubocop"

brakeman:
	$(DR) "bin/brakeman"

# Example usage:
#   ONLY=Layout/EmptyLinesAroundModuleBody,Layout/EmptyLinesAroundClassBody make rubycop-fix
rubocop-fix:
	$(DR) "bin/rubocop --only $(ONLY) --autocorrect-all"
	git commit -a \
	  -m "rubocop: $$(echo $(ONLY) | cut -d, -f1)..." \
	  -m "Rubocop autocorrect for the following:" \
	  -m "$$(echo $(ONLY) | tr , '\n' | sed 's/^/- /')"

haml-lint-refresh-todos:
	$(DR) "bundle exec haml-lint --auto-gen-config"

haml-lint-with-todo:
	$(DR) "bundle exec haml-lint --config .haml-lint_todo.yml"

delint: haml-lint-with-todo rubocop

ansible-lint:
	@ansible-lint -p ansible/playbooks/deploy.yml -x yaml[indentation],no-handler

#----------------------------------------------------------

# View or edit encrypted secrets
# (Todo maybe: Switch to newer per-environment credentials and use
# `--environment=production` and `--environment=development` here)
#
secrets:
	$(DR) "EDITOR=vi bin/rails credentials:edit"

dump-secrets:
	@$(DR) "EDITOR=cat bin/rails credentials:edit" | tail -n +2

#----------------------------------------------------------

# Run test suite
run-tests:
	$(DCC) 'bin/rails test:all'

test-ci:
	$(DC) run --rm app bash -c "bin/rails test:all"

coverage:
	$(DCC) 'env COVERAGE=1 bin/rails test:all'

onetest:
	$(DCC) 'bin/rails test $(TEST)'

test: run-tests
tests: run-tests

#----------------------------------------------------------

# (Use these if you want to run the prod container locally)
shell-prod: local-config prod-secrets prod-prerelease
	-$(DC_PROD) run --rm app bash

join-prod:
	-$(DC_PROD) exec app bash -c bash

start-prod: local-config prod-secrets prod-prerelease
	-$(DC_PROD) up

#----------------------------------------------------------

# Stop and remove containers, clean up unused images and remove
# the static files volume used by the prod container so to ensure
# it gets recreated fresh on startup
cleanup: tmp-clear log-clear
	$(DC) stop
	$(DC_PROD) stop
	$(DC) rm -f
	$(DC_PROD) rm -f
	$(D) image prune -f
	$(D) volume rm -f th_rails_static

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

EMPTY_URL_tw5=https://tiddlywiki.com/empty.html
EMPTY_URL_tw5x=https://tiddlywiki.com/empty-external-core.html
EMPTY_URL_classic=https://classic.tiddlywiki.com/empty.html
EMPTY_URL_prerelease=https://tiddlywiki.com/prerelease/empty.html

EMPTY_URL_feather=https://feather.wiki/builds/v1.8.x/FeatherWiki_$(FEATHER_BIRD).html
EMPTY_URL_featherx=https://feather.wiki/builds/v1.8.x/FeatherWiki-bones$(FEATHER_BIRD).html
EMPTY_URL_feather_plumage=https://feather.wiki/builds/v1.8.x/FeatherWiki-plumage_$(FEATHER_BIRD).css
EMPTY_URL_feather_bones=https://feather.wiki/builds/v1.8.x/FeatherWiki-bones_$(FEATHER_BIRD).js

CURL_FETCH=curl -sL $(EMPTY_URL_$1) -o $(EMPTY_DIR)/$1.html

download-empty-%: $(EMPTY_DIR)
	$(call CURL_FETCH,$*)

CORE_JS_URL=https://tiddlywiki.com/tiddlywikicore-$(VER).js

download-core-js:
	cd rails/public && curl -sL $(CORE_JS_URL) -O

download-core-js-prerelease:
	PRERELEASE_VER=$$(curl -s --range 0-1000 $(EMPTY_URL_prerelease) | grep '<meta name="tiddlywiki-version"' | cut -d'"' -f4) && \
	CORE_JS_PRERELEASE_URL=https://tiddlywiki.com/prerelease/tiddlywikicore-$${PRERELEASE_VER}.js && \
	  cd rails/public && \
	  curl -sL $${CORE_JS_PRERELEASE_URL} -O

# (No download-empty-featherx yet since I'm building it locally)
download-empties: download-empty-tw5 download-empty-tw5x download-empty-feather download-empty-classic download-empty-prerelease download-core-js download-core-js-prerelease

# For Feather Wiki js and css
# (Actually I'm building the "bones" locally also since it requires the
# changes from https://codeberg.org/Alamantus/FeatherWiki/pulls/208 )
download-plumage-and-bones:
	cd rails/public && curl -sLO $(EMPTY_URL_feather_bones) && curl -sLO $(EMPTY_URL_feather_plumage)

PROD_PRERELEASE=docker/config/prerelease.html
$(PROD_PRERELEASE): $(EMPTY_DIR)/prerelease.html
	cp $< $@

prod-prerelease: $(PROD_PRERELEASE)

# Usually this is downloaded using download-empties, but this can be used
# to copy in locally built Feather Wiki empty
FEATHER_EMPTY=$(EMPTY_DIR)/feather.html
$(FEATHER_EMPTY):
	cp ../FeatherWiki/builds/v1.8.x/FeatherWiki_$(FEATHER_BIRD).html $@

# Built locally with https://codeberg.org/Alamantus/FeatherWiki/pulls/208
FEATHERX_EMPTY=$(EMPTY_DIR)/featherx.html
$(FEATHERX_EMPTY):
	cp ../FeatherWiki/builds/v1.8.x/FeatherWiki-bare_$(FEATHER_BIRD).html $@

feather-empty: $(FEATHER_EMPTY) $(FEATHERX_EMPTY)

refresh-empties: empty-versions clear-empties download-empties

clear-empties:
	@rm -rf $(EMPTY_DIR)/*.html

empty-versions:
	@$(DCC) 'bin/rails runner "puts Empty.versions.to_yaml"' \
	  | grep -v 'Spring preloader' | grep -v '\-\-\-'

#----------------------------------------------------------

# Run this at build time since I don't want to check in the gzipped files
gzip-core-js-files:
	@for f in $$( ls rails/public/tiddlywikicore-*.js ); do \
	  gzip -c $$f > $$f.gz; \
	  echo Created $$f.gz; \
	done

#----------------------------------------------------------

EMPTIES_DIR=rails/tw_content/empties

require-var-%:
	@[[ ! -z "$$$(*)" ]] || ( echo "Environment var $(*) is required." && exit 1 )

ver-set: require-var-VER

# All the steps needed for a TiddlyWiki upgrade
# The version number must be provided manually like this:
#   VER=5.3.1 make tw5-update
#
tw5-update: ver-set $(TW5_DIR) download-empty-tw5 download-empty-tw5x download-core-js
	cp $(EMPTIES_DIR)/tw5.html $(EMPTIES_DIR)/tw5/$(VER).html
	cp $(EMPTIES_DIR)/tw5x.html $(EMPTIES_DIR)/tw5x/$(VER).html
	git add \
	  $(EMPTIES_DIR)/tw5.html \
	  $(EMPTIES_DIR)/tw5/$(VER).html \
	  $(EMPTIES_DIR)/tw5x.html \
	  $(EMPTIES_DIR)/tw5x/$(VER).html \
	  rails/public/tiddlywikicore-$(VER).js
	git commit -m 'chore: Upgrade TiddlyWiki empties to version $(VER)' \
	  -m 'Commit created with `VER=$(VER) make tw5-update`'

# Same thing for Feather Wiki
# You must specify the version manually here too:
#   VER=1.7.0 make feather-update
#
FEATHER_BIRD=Woodlark
feather-update: ver-set download-empty-feather
	cp $(EMPTIES_DIR)/feather.html $(EMPTIES_DIR)/feather/$(VER).html
	git add \
	  $(EMPTIES_DIR)/feather.html \
	  $(EMPTIES_DIR)/feather/$(VER).html
	git commit -m 'chore: Upgrade Feather Wiki empties to version $(VER)' \
	  -m 'Commit created with `VER=$(VER) make feather-update`'

# Same thing for Classic
#   VER=2.10.1 make classic-update
classic-update: ver-set download-empty-classic
	cp $(EMPTIES_DIR)/classic.html $(EMPTIES_DIR)/classic/$(VER).html
	git add \
	  $(EMPTIES_DIR)/classic.html \
	  $(EMPTIES_DIR)/classic/$(VER).html
	git commit -m 'chore: Upgrade TiddlyWiki Classic empty to $(VER)' \
	  -m 'Commit created with `VER=$(VER) make classic-update`'

# And for siteleteer
#   VER=1.0.2 make siteleteer-update
SITELETEER_DIR=../siteleteer-tiddlyhost
siteleteer-update: ver-set
	# Beware there's no version tags or downnloads here. Assume that you
	# have prepared the right version in $(SITELETEER_DIR) beforhand.
	cp $(SITELETEER_DIR)/siteleteer.html $(EMPTIES_DIR)/sitelet.html
	cp $(EMPTIES_DIR)/sitelet.html $(EMPTIES_DIR)/sitelet/$(VER).html
	git add \
	  $(EMPTIES_DIR)/sitelet.html \
	  $(EMPTIES_DIR)/sitelet/$(VER).html
	git commit -m 'chore: Upgrade siteleteer empty to $(VER)' \
	  -m 'Commit created with `VER=$(VER) make siteleteer-update`'

#----------------------------------------------------------

# Generate an SSL cert
# (If the cert exists, assume the key exists too.)
CERTS_DIR=docker/letsencrypt/live/tiddlyhost.local
cert: $(CERTS_DIR)/fullchain.pem

$(CERTS_DIR)/fullchain.pem:
	@bin/create-local-ssl-cert.sh $(CERTS_DIR)

clear-cert:
	@rm -f $(CERTS_DIR)/privkey.pem
	@rm -f $(CERTS_DIR)/fullchain.pem

redo-cert: clear-cert cert

#----------------------------------------------------------

no-uncommitted-diffs:
	@# Update the index to avoid bogus diffs due to a stale git
	@# index, or something like that..?
	@git update-index -q --refresh
	@if ! git diff-index --quiet HEAD --; then \
	  echo "Aborting due to uncommitted diffs!"; \
		git diff --stat; \
		git status --short; \
	  exit 1; \
	else \
	  echo "Uncommitted diffs check okay"; \
	fi

no-uncommitted-rails-files:
	@if [[ -n "$$( git status rails --porcelain )" ]]; then \
	  echo "Aborting due to uncommitted files under rails directory!"; \
	  git status rails --porcelain; \
	  exit 1; \
	else \
	  echo "Uncommitted files under rails check okay"; \
	fi

# Avoid accidentally deploying junk
build-ready: no-uncommitted-diffs no-uncommitted-rails-files

build-info:
	@bin/create-build-info.sh | tee rails/public/build-info.txt

build-prod: build-ready build-info js-math download-empty-prerelease download-core-js-prerelease gzip-core-js-files
	$(DC_PROD) $(PROGRESS_OPT) build app

build-prod-ci:
	$(DC_PROD) build app

fast-build-prod: build-info
	$(DC_PROD) $(PROGRESS_OPT) build app

push-base:
	$(D) --config etc/credentials/docker push $(DOCKER_PUSH_REPO_BASE)

push-prod:
	$(D) --config etc/credentials/docker push $(DOCKER_PUSH_REPO)

# Fixme: There are too many options here...
build-push:            delint tests build-prod push-prod
build-full-deploy:     build-push full-deploy
build-deploy:          build-push deploy-app
fast-build-deploy:     fast-build-prod push-prod fast-deploy-app

PLAY=ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory.yml $(V)

DEPLOY=$(PLAY) ansible/playbooks/deploy.yml --limit prod
RESTART=$(PLAY) ansible/playbooks/restart.yml --limit prod
BACKUP=$(PLAY) ansible/playbooks/backup.yml --limit prod
FETCH_LOGS=$(PLAY) ansible/playbooks/fetch-logs.yml --limit prod

full-deploy:
	$(DEPLOY)

deploy-deps:
	$(DEPLOY) --tags=deps

deploy-certs:
	$(DEPLOY) --tags=certs

deploy-scripts:
	$(DEPLOY) --tags=scripts

refresh-prerelease:
	$(DEPLOY) --tags=refresh-prerelease

deploy-app:
	$(DEPLOY) --tags=app

fast-deploy-app:
	$(DEPLOY) --tags=fast-upgrade

deploy-app-bootstrap:
	$(DEPLOY) --tags=app,db-create

deploy-cleanup:
	$(DEPLOY) --tags=cleanup

deploy-secrets:
	$(DEPLOY) --tags=secrets

# If you want to run selected tasks givem them the foo tag
deploy-foo:
	$(DEPLOY) --tags=foo --diff

restart-jobs:
	$(RESTART) -e restart_list=jobs

restart-app:
	$(RESTART) -e restart_list=app

#----------------------------------------------------------

TIMESTAMP := $(shell date +%Y%m%d%H%M%S)

TOP_DIR=$(shell git rev-parse --show-toplevel)
BACKUPS_DIR=$(TOP_DIR)/../thost-backups
S3_BACKUPS=$(BACKUPS_DIR)/s3
DB_BACKUPS=$(BACKUPS_DIR)/db

db-backup:
	mkdir -p $(DB_BACKUPS)/$(TIMESTAMP)
	$(BACKUP) -e local_backup_subdir=$(TIMESTAMP) -e local_backup_dir=$(DB_BACKUPS) --limit=prod
	ls -l $(DB_BACKUPS)/$(TIMESTAMP)
	zcat $(DB_BACKUPS)/$(TIMESTAMP)/dbdump.gz | grep '^-- ' | head -3
	du -h -s $(DB_BACKUPS)/$(TIMESTAMP)
	du -h -s $(DB_BACKUPS)

s3-bucket-name: require-var-BUCKET_NAME

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

LOGS_DIR=../logs

fetch-logs:
	$(FETCH_LOGS)

extract-save-times:
	cat $(LOGS_DIR)/web-*.log | hack/nginx-log-parser.rb csv > $(LOGS_DIR)/save-times-$(TIMESTAMP).csv

# Todo maybe: Deduping and keeping the raw log data would be better
collect-and-dedupe-save-times:
	cat $(LOGS_DIR)/save-times*.csv | sort | uniq > $(LOGS_DIR)/save-times.csv

save-time-stats:
	@hack/save-time-stats.rb < $(LOGS_DIR)/save-times.csv

fresh-save-times: fetch-logs extract-save-times collect-and-dedupe-save-times save-time-stats

#----------------------------------------------------------

PROD_INFO_URL=https://tiddlyhost.com/build-info.txt

prod-info:
	@-curl -s $(PROD_INFO_URL)

prod-diff:
	@-( \
	  echo '## Prod build info' && \
	  $(MAKE) prod-info && \
	  echo '' && \
	  echo '## Prod diff' && \
	  git diff --color=always $$(curl -s $(PROD_INFO_URL) | grep 'sha:' | cut -d: -f2) \
	) | less -REXS

#----------------------------------------------------------
JS_MATH_ZIP=jsMath-3.3g.zip
JS_MATH_FONTS_ZIP=jsMath-fonts-1.3.zip

JS_MATH_ZIP_PATH=$(TOP_DIR)/etc/$(JS_MATH_ZIP)
JS_MATH_FONTS_ZIP_PATH=$(TOP_DIR)/etc/$(JS_MATH_FONTS_ZIP)

JS_MATH_DOWNLOADS=https://master.dl.sourceforge.net/project/jsmath

$(JS_MATH_ZIP_PATH):
	curl -sL $(JS_MATH_DOWNLOADS)/jsMath/3.3g/$(JS_MATH_ZIP) -o $@

$(JS_MATH_FONTS_ZIP_PATH):
	curl -sL $(JS_MATH_DOWNLOADS)/jsMath%20Image%20Fonts/1.3/$(JS_MATH_FONTS_ZIP) -o $@

rails/public/jsMath/jsMath.js: $(JS_MATH_ZIP_PATH) $(JS_MATH_FONTS_ZIP_PATH)
	cd rails/public && unzip -q $(JS_MATH_ZIP_PATH)
	cd rails/public/jsMath && unzip -q $(JS_MATH_FONTS_ZIP_PATH)
	@touch rails/public/jsMath/jsMath.js # so make doesn't think it's stale

js-math: rails/public/jsMath/jsMath.js

js-math-clean:
	rm -rf rails/public/jsMath

js-math-purge: js-math-clean
	rm -f $(JS_MATH_ZIP_PATH) $(JS_MATH_FONTS_ZIP_PATH)

#----------------------------------------------------------

version-bump: require-var-VER
	sed 's/major_version: ".*"/major_version: "$(VER)"/' -i rails/config/settings.yml
	git add rails/config/settings.yml
	git commit -m 'chore: Bump version to $(VER)' \
	  -m 'Commit created with `VER=$(VER) make version-bump`'
	git tag 'v$(VER)'
	@echo 'You probably want to do this also:'
	@echo '  git push origin v$(VER)'

#----------------------------------------------------------

stripe-dev-listen:
	stripe listen --forward-to https://tiddlyhost.local/pay/webhooks/stripe --skip-verify --latest

stripe-api-version:
	@$(DCC) 'bin/rails runner "puts Stripe.api_version"'

#----------------------------------------------------------

# I usually work in devel branch locally and update main now
# and again. (This doesn't really belong here, but nevermind.)

git-push:
	git push origin devel:devel

# Try not to do this often
git-push-hard:
	git push -f origin devel:devel

# Expecting this to be a fast forward
git-update-main: git-push
	git push origin devel:main
	git checkout main && git merge --ff-only devel
	git checkout devel

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
