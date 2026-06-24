<?php
$file = '/usr/src/typecho/usr/plugins/AxS3Upload/Plugin.php';
$code = file_get_contents($file);

// 1. Try-catch for attachmentHandle to prevent write-post.php 500
$target = 'public static function attachmentHandle(array $content)';
$replace = 'public static function attachmentHandle(array $content) { try { return self::_attachmentHandle($content); } catch (Throwable $e) { error_log("S3: " . $e->getMessage()); return $content["attachment"]->url ?? ""; } } private static function _attachmentHandle(array $content)';
if (strpos($code, $target) !== false) {
    $code = str_replace($target, $replace, $code);
    echo "Patched attachmentHandle OK\n";
}

// 2. Add disable_content_sha256 for MinIO compatibility
$target2 = "'use_path_style_endpoint' => true,";
$replace2 = "'use_path_style_endpoint' => true,
            'disable_content_sha256' => true,";
if (strpos($code, $target2) !== false) {
    $code = str_replace($target2, $replace2, $code);
    echo "Added disable_content_sha256 OK\n";
}

file_put_contents($file, $code);
echo "Plugin.php patched successfully\n";
