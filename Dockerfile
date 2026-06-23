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
    curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cd /usr/src/typecho/usr/plugins/AxS3Upload && \
    composer require aws/aws-sdk-php --no-interaction --no-dev --quiet && \
    sed -i '2i require_once __DIR__ . "/vendor/autoload.php";' /usr/src/typecho/usr/plugins/AxS3Upload/Plugin.php && \
    rm -rf /root/.composer && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
