# syntax=docker/dockerfile:1
# DEVELOPMENT image. Single stage. Code is bind-mounted, not baked.
# Composer + Node deps are installed at runtime against the mount,
# so this image only needs PHP-FPM + extensions + Composer.

FROM php:8.4-fpm

RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl zip unzip \
        libpng-dev libjpeg-dev libfreetype6-dev \
        libonig-dev libxml2-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

# Composer, copied from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Match the host user so bind-mounted files stay editable on the host.
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" laravel 2>/dev/null || true \
    && useradd -u "${UID}" -g "${GID}" -m -s /bin/bash laravel 2>/dev/null || true

WORKDIR /var/www
USER laravel

EXPOSE 9000
CMD ["php-fpm"]