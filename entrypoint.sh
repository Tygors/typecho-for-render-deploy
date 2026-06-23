#!/usr/bin/env sh
set -e

# ──────────────────────────────────────────────────
# Typecho MinIO backup/restore for SQLite persistence
# ──────────────────────────────────────────────────

DB_FILE="${TYPECHO_DB_FILE:-/app/usr/db/typecho.db}"
BACKUP_BUCKET="${MINIO_BACKUP_BUCKET:-typecho-backup}"
TRIGGER_FILE="/tmp/typecho-backup-trigger"

do_backup() {
    if [ ! -f "$DB_FILE" ]; then
        return 0
    fi
    sqlite3 "$DB_FILE" ".backup $(dirname "$DB_FILE")/.backup_tmp" && \
    mc cp "$(dirname "$DB_FILE")/.backup_tmp" "typecho-backup/$BACKUP_BUCKET/typecho.db" >/dev/null 2>&1 && \
    rm -f "$(dirname "$DB_FILE")/.backup_tmp"
}

# MinIO backup/restore
if command -v mc >/dev/null 2>&1 && [ -n "$MINIO_ENDPOINT" ]; then
    if mc alias set typecho-backup "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" >/dev/null 2>&1; then
        echo "MinIO backup alias configured for bucket: $BACKUP_BUCKET"
    else
        echo "WARNING: Failed to configure MinIO backup alias" >&2
    fi

    if [ ! -f "$DB_FILE" ]; then
        if mc stat "typecho-backup/$BACKUP_BUCKET/typecho.db" >/dev/null 2>&1; then
            echo "Restoring typecho.db from backup..."
            mkdir -p "$(dirname "$DB_FILE")"
            mc cp "typecho-backup/$BACKUP_BUCKET/typecho.db" "$DB_FILE" >/dev/null 2>&1 && echo "Restore complete" || echo "WARNING: restore failed" >&2
        fi
    fi

    (
        while true; do
            sleep "${MINIO_BACKUP_INTERVAL:-720}"
            do_backup && echo "Backup complete" || echo "WARNING: backup failed" >&2
        done
    ) &

    (
        while true; do
            sleep 60
            if [ -f "$TRIGGER_FILE" ]; then
                rm -f "$TRIGGER_FILE"
                do_backup && echo "Triggered backup complete" || echo "WARNING: triggered backup failed" >&2
            fi
        done
    ) &
fi

# ──────────────────────────────────────────────────
# Typecho source extraction (one-time at /usr/src/typecho/)
# ──────────────────────────────────────────────────
if [ ! -f /app/index.php ] && [ -d /usr/src/typecho ]; then
    echo "Extracting Typecho source..."
    cp -Rf /usr/src/typecho/* /app/ 2>/dev/null && chown -Rf www-data:www-data /app/ 2>/dev/null
fi

# ──────────────────────────────────────────────────
# Ensure database directory exists and is writable
# ──────────────────────────────────────────────────
mkdir -p "$(dirname "$DB_FILE")" 2>/dev/null
chown www-data:www-data "$(dirname "$DB_FILE")" 2>/dev/null

# ──────────────────────────────────────────────────
# Typecho headless install (triggered by env vars)
# ──────────────────────────────────────────────────
if [ "$TYPECHO_INSTALL" = "1" ]; then
    if [ ! -f "$(dirname "$DB_FILE")/config.inc.php" ]; then
        echo "Running Typecho auto-install..."
        su -p www-data -s /usr/bin/env php /app/install.php && echo "Install complete" || echo "WARNING: install failed (may already be installed)" >&2
    fi
fi

echo "Starting Apache..."
# Enable PHP error display and create a phpinfo endpoint
cat > /usr/local/etc/php/conf.d/00-typecho.ini <<'INIEOF'
display_errors = On
display_startup_errors = On
error_reporting = E_ALL
INIEOF
# Create diagnostic endpoints
echo '<?php phpinfo();' > /app/phpinfo.php 2>/dev/null
echo '<?php
error_reporting(E_ALL);
ini_set("display_errors", 1);
echo "<h2>Plugin Test</h2>";
try {
    $f = "/app/usr/plugins/AxS3Upload/Plugin.php";
    echo "Plugin file exists: " . (file_exists($f) ? "YES" : "NO") . "<br>";
    echo "Vendor autoload exists: " . (file_exists("/app/usr/plugins/AxS3Upload/vendor/autoload.php") ? "YES" : "NO") . "<br>";
    if (file_exists("/app/usr/plugins/AxS3Upload/vendor/autoload.php")) {
        require_once "/app/usr/plugins/AxS3Upload/vendor/autoload.php";
        echo "Autoload loaded OK<br>";
        echo "S3Client class exists: " . (class_exists("Aws\S3\S3Client") ? "YES" : "NO") . "<br>";
    }
    $content = file_get_contents($f);
    if (preg_match("/vendor.*autoload/", $content)) {
        echo "Plugin.php autoload: vendor/autoload.php ✓<br>";
    } elseif (preg_match("/aws\.phar/", $content)) {
        echo "Plugin.php autoload: aws.phar ✗<br>";
    } else {
        echo "Plugin.php autoload: MISSING ✗<br>";
    }
    // Test loading the plugin class directly
    require_once $f;
    echo "Plugin class loaded OK<br>";
    echo "AxS3Upload_Plugin exists: " . (class_exists("AxS3Upload_Plugin") ? "YES" : "NO") . "<br>";
    // Try initConnection
    try {
        \AxS3Upload_Plugin::initConnection();
        echo "S3 connection init: OK<br>";
    } catch (Throwable $e) {
        echo "S3 connection init ERROR: " . $e->getMessage() . "<br>";
    }
} catch (Throwable $e) {
    echo "FATAL: " . $e->getMessage() . "<br>";
    echo nl2br($e->getTraceAsString());
}
' > /app/plugin-test.php 2>/dev/null
chown www-data:www-data /app/phpinfo.php /app/plugin-test.php 2>/dev/null || true

exec apache2-foreground
