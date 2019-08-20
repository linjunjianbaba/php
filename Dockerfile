# PHP Docker image for Yii 2.0 Framework runtime
# ==============================================


FROM php:7.2-fpm-alpine

# Install system packages & PHP extensions required for Yii 2.0 Framework
RUN apk --update --virtual build-deps add \
        autoconf \
        make \
        gcc \
        g++ \
        libtool \
        icu-dev \
        curl-dev \
        freetype-dev \
        imagemagick-dev \
        pcre-dev \
        postgresql-dev \
        libmcrypt-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev && \
    apk add \
        git \
        curl \
        bash \
        bash-completion \
        icu \
        imagemagick \
        pcre \
        freetype \
        libmcrypt \
        libintl \
        libjpeg-turbo \
        libpng \
        libltdl \
        libxml2 \
		libzip-dev \
        mysql-client \
        nodejs-npm  \
        postgresql && \
    pecl install \
        apcu \
        imagick \
        mcrypt-1.0.0 && \
	pecl install -o -f redis && \
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-configure bcmath && \
    docker-php-ext-install \
        soap \
        zip \
        curl \
        bcmath \
        exif \
        gd \
        iconv \
        intl \
        mbstring \
        opcache \
        pdo_mysql \
        pdo_pgsql && \
    apk del \
        build-deps

RUN echo "extension=apcu.so" > /usr/local/etc/php/conf.d/pecl-apcu.ini \
 && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/pecl-imagick.ini && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev git

# Install xdebug
RUN export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" && \
    apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS && \
    cd /tmp && \
    git clone git://github.com/xdebug/xdebug.git && \
    cd xdebug && \
    git checkout 52adff7539109db592d07d3f6c325f6ee2a7669f && \
    phpize && \
    ./configure --enable-xdebug && \
    make && \
    make install && \
    rm -rf /tmp/xdebug && \
    apk del .phpize-deps

# Install less-compiler
RUN npm install -g \
        less \
        lesshint \
        uglify-js \
        uglifycss

# Configure version constraints
ENV PHP_ENABLE_XDEBUG=0 \
    VERSION_COMPOSER_ASSET_PLUGIN=^1.4.3 \
    VERSION_PRESTISSIMO_PLUGIN=^0.3.0 \
    PATH=/app:/app/vendor/bin:/root/.composer/vendor/bin:$PATH \
    TERM=linux \
    COMPOSER_ALLOW_SUPERUSER=1

# Add configuration files
COPY image-files/ /

# Add GITHUB_API_TOKEN support for composer
RUN chmod 700 \
        /usr/local/bin/docker-entrypoint.sh \
        /usr/local/bin/docker-run.sh \
        /usr/local/bin/composer

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer.phar \
        --install-dir=/usr/local/bin && \
    composer global require --optimize-autoloader \
        "fxp/composer-asset-plugin:${VERSION_COMPOSER_ASSET_PLUGIN}" \
        "hirak/prestissimo:${VERSION_PRESTISSIMO_PLUGIN}" && \
    composer global dumpautoload --optimize && \
    composer clear-cache

WORKDIR /app

# Startup script for FPM
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["docker-run.sh"]