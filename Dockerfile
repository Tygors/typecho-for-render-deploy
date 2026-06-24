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
    cat > /usr/src/typecho/usr/plugins/AxS3Upload/patch.php <<'PATCHEOF'
<?php
$file = 'Plugin.php';
$code = file_get_contents($file);

// 1. Try-catch for attachmentHandle
$target = 'public static function attachmentHandle(array $content)';
$replace = 'public static function attachmentHandle(array $content) { try { return self::_attachmentHandle($content); } catch (Throwable $e) { error_log("S3: " . $e->getMessage()); return $content["attachment"]->url ?? ""; } } private static function _attachmentHandle(array $content)';
if (strpos($code, $target) !== false) {
    $code = str_replace($target, $replace, $code);
    echo "Patched attachmentHandle OK\n";
}

// 2. Add disable_content_sha256
$target2 = "'use_path_style_endpoint' => true,";
$replace2 = "'use_path_style_endpoint' => true,
            'disable_content_sha256' => true,";
if (strpos($code, $target2) !== false) {
    $code = str_replace($target2, $replace2, $code);
    echo "Added disable_content_sha256 OK\n";
}

file_put_contents($file, $code);
PATCHEOF
    php /usr/src/typecho/usr/plugins/AxS3Upload/patch.php && \
    rm -f /usr/src/typecho/usr/plugins/AxS3Upload/patch.php && \
    rm -f aws.phar && \
    rm -rf /root/.composer && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
