#
# Instalasi PHP Dependencies
#
FROM composer:2.8 AS vendor

# set default working directory to /app
WORKDIR /app
 
# copy composer.json and composer.lock
COPY laravel/composer.json composer.json
COPY laravel/composer.lock composer.lock

# installing dependencies
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

#
# Building assets using Nodejs
#
FROM node:alpine AS frontend

# set default working directory to /app
WORKDIR /app

# copy application resources, package.json, and others (tailwind and vite)
COPY laravel/resources/css ./resources/css
COPY laravel/resources/js ./resources/js
COPY laravel/package*.json laravel/vite.config.js laravel/tailwind.config.js /laravel/postcss.config.js ./

# create /app/directory to store build files
RUN mkdir -p /app/public

# install Node.js deps
RUN npm ci

# build assets
RUN npm run build

#
# Building Image untuk pingcrm
# Memilih alpine karena sizenya kecil, aman, dan minimalis
FROM alpine:3.21

# Setup document root
WORKDIR /var/www/html

# Install packages and no-cache
# Menggunakan PHP 8.4 karena latest stable version
# Untuk pemilihan versi PHP, pastikan sesuai dengan requirement dari aplikasi
# Test tambah
RUN apk add --no-cache \
  bash \
  curl \
  nginx \
  php84 \
  php84-ctype \
  php84-curl \
  php84-dom \
  php84-fileinfo \
  php84-fpm \
  php84-gd \
  php84-intl \
  php84-mbstring \
  php84-mysqli \
  php84-opcache \
  php84-openssl \
  php84-phar \
  php84-session \
  php84-tokenizer \
  php84-xml \
  php84-xmlreader \
  php84-xmlwriter \
  php84-common \
  php84-pdo \
  php84-pdo_mysql \
  php84-pecl-redis \
  php84-mysqli \
  gettext \
  envsubst \
  supervisor

# Configure nginx - http
ENV APPLICATION_DOMAIN app.test.local
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY docker/nginx/conf.d/laravel.conf /etc/nginx/conf.d/laravel.tmp
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
ENV PHP_INI_DIR /etc/php84

# copy www.conf - setting pm.max_children berdasar rumus:
# total memory / current mem usage PHP (gunakan top untuk cek)
# 2048 / 183 = 11
# pm.max_children = 11
COPY docker/php/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf

# copy tambahan php.ini - custom.ini
# setting timezone dan alokasi max memory untuk proses PHP
COPY docker/php/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
# menambahkan proses untuk Laravel queue dan schedule
COPY docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# copy .env file
COPY docker/.env /var/www/html/.env

# Create user and group app - uid and gid 1000
RUN addgroup -g 1000 app && \
    adduser --disabled-password -h /var/www/html -u 1000 -G app app

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
# additional access to nginx/conf.d to modify APPLICATION_DOMAIN via entrypoint
RUN chown -R app:app /var/www/html /var/www/html/.env /run /var/lib/nginx /var/log/nginx /etc/nginx/conf.d/

# copy entrypoint.sh start script
COPY docker/entrypoint.sh.4 /usr/local/bin/start
RUN chmod +x /usr/local/bin/start

# Switch to use a non-root user from here on
#USER app

# TODO: Upload source code laravel - vendor from vendor build - public from frontend build
COPY --chown=app --chmod=755 laravel/ /var/www/html/
COPY --chown=app --chmod=755 --from=vendor /app/vendor /var/www/html/vendor
COPY --chown=app --chmod=755 --from=frontend /app/public /var/www/html/public

# TODO: generate key
RUN php84 artisan key:generate

# Expose the port nginx is reachable on
EXPOSE 9000

# start via entrypoint.sh
CMD ["/usr/local/bin/start"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
