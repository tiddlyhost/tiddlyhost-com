# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About Tiddlyhost

Tiddlyhost (https://tiddlyhost.com/) is a hosting service for TiddlyWiki. This is the source code for the production application.

As well as TiddlyWiki, the following "TiddlyWiki-like" single-page wikis can also be created and hosted on Tiddlyhost:
- TiddlyWiki Classic (legacy)
- FeatherWiki
- Siteleteer

## Development Environment

Tiddlyhost is a Ruby on Rails application that hosts TiddlyWiki sites with Docker-based development. The project structure includes:

- `rails/` - Main Rails application
- `docker/` - Docker configuration and volumes
- `ansible/` - Deployment automation
- `bin/` - Utility scripts

## Common Development Commands

### Building and Setup
```bash
# Build the development Docker image
make build-base

# Initialize Rails (sets up database, installs gems)
make rails-init

# Start the full development stack with SSL
make start
```

### Testing and Quality
```bash
# Run the full test suite
make test
# Or alternatively:
make run-tests

# Run a single test file
make onetest TEST=test/models/site_test.rb

# Run linting
make delint

# This runs both:
make haml-lint-with-todo  # HAML linting
make rubocop              # Ruby linting
```

### Development Tools
```bash
# Shell into running container
make join

# Rails console
make console

# Database migration
make db-migrate

# Clear logs and temp files
make log-clear
make tmp-clear
```

### Bundle and Dependencies
```bash
# Install Ruby gems
make bundle-install

# Update gems
make bundle-update

# Install JavaScript packages
make yarn-install

# Update JavaScript packages
make yarn-upgrade
```

## Architecture Overview

### Core Models
- `Site` - TiddlyWiki sites hosted on tiddlyhost.com with version history
- `TspotSite` - Legacy Tiddlyspot.com sites that can be claimed
- `User` - User accounts with Devise authentication
- `Empty` - Template sites (TiddlyWiki, Feather Wiki, etc.)

### Key Controllers
- `TiddlywikiController` - Serves and saves TiddlyWiki sites
- `SitesController` - Site management (CRUD, history, downloads)
- `TiddlyspotController` - Legacy Tiddlyspot.com compatibility
- `HubController` + variants - Browse/explore public sites

### Routing Architecture
The app uses domain-based routing constraints:
- `tiddlyhost.com` - Main application interface
- `subdomain.tiddlyhost.com` - Individual TiddlyWiki sites
- `subdomain.tiddlyspot.com` - Legacy Tiddlyspot sites

### File Storage
- Uses Active Storage for file attachments
- Multiple storage services: `local1`, `local2`, `thumbs2`, etc.
- Site content stored as blobs with version history
- Thumbnails generated via background jobs

## Configuration

### Settings
Settings are managed through `rails/config/settings.yml` and can be overridden by `settings_local.yml`. Key settings include:
- Host configuration for multi-domain setup
- Feature flags (e.g., `tiddlyspot_enabled`)
- Storage service mappings
- Subscription plan details

### Secrets
Encrypted secrets are managed via Rails credentials:
```bash
# View/edit secrets
make secrets
```

### Docker Development
The development environment runs in Docker containers managed using `docker-compose`:
- `app` - Rails application
- `db` - PostgreSQL database
- `web` - Reverse proxy with SSL
- `jobs` - Rails background jobs
- `cache` - Memcached

Use wildcard DNS entries in `/etc/hosts` for subdomain testing:
```
127.0.0.1 tiddlyhost.local
127.0.0.1 *.tiddlyhost.local
```

## Background Jobs

Uses Delayed Job for:
- Thumbnail generation (`GenerateThumbnailJob`)
- Attachment cleanup (`PruneAttachmentsJob`)

## Important Notes

- TiddlyWiki content is stored as compressed HTML files in Active Storage blobs
- The app supports multiple TiddlyWiki versions via "empties" (templates)
- Save history allows users to view/restore previous versions
- Subscription management via Stripe integration
- Legacy Tiddlyspot compatibility maintains existing site URLs
