FROM joyqi/typecho:nightly-php8.2-apache

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl sqlite3 ca-certificates unzip && \
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc && \
    curl -fsSL -o /tmp/s3-plugin.zip https://github.com/yemaster/Typecho-S3-Plugin/archive/refs/heads/master.zip && \
    unzip -q /tmp/s3-plugin.zip -d /tmp/s3-plugin && \
    cp -Rf /tmp/s3-plugin/Typecho-S3-Plugin-master/AxS3Upload /usr/src/typecho/usr/plugins/ && \
    rm -rf /tmp/s3-plugin* && \
    cd /usr/src/typecho/usr/plugins/AxS3Upload && \
    curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer require aws/aws-sdk-php --no-interaction --update-no-dev --quiet && \
    sed -i "s|require_once.*aws\.phar.*|require_once __DIR__ . '/vendor/autoload.php';|" Plugin.php && \
    rm -f aws.phar && \
    rm -rf /root/.composer && \
    rm -rf /var/lib/apt/lists/*

COPY patch.php /tmp/patch.php
RUN php /tmp/patch.php && rm -f /tmp/patch.php

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
