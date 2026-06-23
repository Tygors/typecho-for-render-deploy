FROM joyqi/typecho:nightly-php8.2-apache

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl sqlite3 ca-certificates && \
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
