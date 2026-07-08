#!/bin/sh
set -e

# Check for env variables
: "${APP_KEY:?APP_KEY environment variable is required}"
: "${DB_HOST:?DB_HOST environment variable is required}"
: "${DB_DATABASE:?DB_DATABASE environment variable is required}"
: "${DB_USERNAME:?DB_USERNAME environment variable is required}"
: "${DB_PASSWORD:?DB_PASSWORD environment variable is required}"

# Clear optimization if the cache already exists
php artisan optimize:clear

# Rebuild Laravel's caches using the environment that's present NOW
# (at container start), when the real config values are injected.
# Doing this here rather than at build time means the same image can
# run in staging or prod with different env, no rebuild needed.
php artisan package:discover --ansi
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run migrations
# If running multiple replicas, remove this and run this manually after boot:
#-- docker compose -f docker-compose.prod.yml exec app php artisan migrate --force
php artisan migrate --force

# Hand off to the CMD (php-fpm).
exec "$@"
