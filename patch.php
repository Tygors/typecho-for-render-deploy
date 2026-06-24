<?php
$file = '/usr/src/typecho/usr/plugins/AxS3Upload/Plugin.php';
$code = file_get_contents($file);

// 1. Try-catch for attachmentHandle + debug logging
$target = 'public static function attachmentHandle(array $content)';
$replace = 'public static function attachmentHandle($content) {
    try {
        $url = self::_attachmentHandle($content);
        error_log("AxS3Upload OK: " . $url);
        return $url;
    } catch (Throwable $e) {
        error_log("AxS3Upload ERR: " . (string)$e);
        $opt = self::getConfig();
        $url = rtrim($opt->endpoint, "/") . "/" . $opt->bucket . "/" . ltrim($content["attachment"]->path ?? "", "/");
        error_log("AxS3Upload FALLBACK: " . $url);
        return $url;
    }
}
private static function _attachmentHandle($content)';
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

// 3. Fix uploadHandle: 'type' must be file extension, not MIME type
//    Otherwise isImage check fails (compares extension against 'png' not 'image/png')
$target3 = "'type' => \$file['type'],";
$replace3 = "'type' => strtolower(pathinfo(\$file['name'], PATHINFO_EXTENSION)),";
if (strpos($code, $target3) !== false) {
    $code = str_replace($target3, $replace3, $code);
    echo "Fixed uploadHandle type field OK\n";
}

// 4. Fix uploadHandle: 'mime' cannot use mime_content_type() with S3 path
//    Change from Typecho_Common::mimeContentType($fullPath) to $file['type']
$target4 = "'mime'  =>  Typecho_Common::mimeContentType(\$fullPath)";
$replace4 = "'mime'  =>  \$file['type']";
if (strpos($code, $target4) !== false) {
    $code = str_replace($target4, $replace4, $code);
    echo "Fixed uploadHandle mime field OK\n";
}

file_put_contents($file, $code);
echo "Plugin.php patched successfully\n";
