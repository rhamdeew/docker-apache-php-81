FROM php:8.1-apache-trixie
# Upstream backport for EOL 8.1: https://github.com/php/php-src/commit/1d7dec178a094e6e75b229ce22754045f8c6070a
COPY patches/CVE-2026-109618-109619.patch /tmp/
RUN apt-get update && \
    apt-get -y install libmcrypt4 libfreetype6 libjpeg62-turbo libpng16-16t64 libxpm4 libzip5 wget mariadb-client msmtp gcc && \
    apt-get -y install autoconf dpkg-dev file g++ make pkg-config re2c apache2-dev libargon2-dev libcurl4-openssl-dev libonig-dev libreadline-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev && \
    docker-php-source extract && \
    cd /usr/src/php && patch -p1 < /tmp/CVE-2026-109618-109619.patch && \
    eval "./configure $(php-config --configure-options) CFLAGS='$PHP_CFLAGS' CPPFLAGS='$PHP_CPPFLAGS' LDFLAGS='$PHP_LDFLAGS'" && \
    make -j "$(nproc)" && make install && \
    (find /usr/local/bin /usr/local/sbin /usr/lib/apache2/modules -type f -perm '/0111' -exec strip --strip-all '{}' + 2>/dev/null || true) && \
    cd / && \
    apt-get -y install libmcrypt-dev libicu-dev libpng-dev libjpeg-dev libfreetype6-dev libxpm-dev libzip-dev && \
    docker-php-ext-install pdo_mysql && \
    wget -q --tries=5 --waitretry=10 --retry-on-http-error=429,500,502,503,504 https://pecl.php.net/get/mcrypt-1.0.5.tgz -O /tmp/mcrypt.tgz && \
    pecl install /tmp/mcrypt.tgz && \
    docker-php-ext-enable mcrypt && \
    docker-php-ext-install opcache && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-xpm && \
    docker-php-ext-install gd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install zip && \
    apt-get remove -y libmcrypt-dev libicu-dev libpng-dev libjpeg-dev libfreetype6-dev libxpm-dev gcc && \
    apt-get remove -y autoconf dpkg-dev file g++ make pkg-config re2c apache2-dev libargon2-dev libcurl4-openssl-dev libonig-dev libreadline-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev && \
    apt-get autoremove -y && apt-get clean && rm -rf /usr/src/* /tmp/*.patch /tmp/mcrypt.tgz /var/lib/apt/lists/*

RUN (cd /etc/apache2/mods-enabled && ln -s ../mods-available/rewrite.load .)
RUN wget https://getcomposer.org/composer-stable.phar -O /usr/local/bin/composer && chmod +x /usr/local/bin/composer
