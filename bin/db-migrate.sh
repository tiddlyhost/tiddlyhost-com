#!/bin/bash
set -euo pipefail
#
# Intended to be used for a postgres upgrade.
#
# See also ansible/playbooks/templates/bin/db-dump-to-file.j2
# which is similar but for a different purpose.
#
# Example usage:
#  # Dump from the app_development running on docker compose service db
#  bin/db-migrate.sh dump db app_development | gzip > dump.sql.gz
#
#  # Load into the app_development db running on docker compose service dbnew
#  zcat dump.sql.gz | bin/db-migrate.sh restore dbnew
#
ACTION=$1
DB_SERVICE=$2
DB_USER=postgres

case "$ACTION" in
  restore)
    # Load the database from a pg_dump file
    sudo docker compose exec -T "$DB_SERVICE" bash -c \
      "psql --username=$DB_USER --set ON_ERROR_STOP=on"
    ;;

  *)
    # Dump out the database using pg_dump
    DB_NAME=$3
    sudo docker compose exec -T "$DB_SERVICE" bash -c \
      "pg_dump --dbname=$DB_NAME --username=$DB_USER --create"
    ;;

esac
