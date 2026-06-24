<?php
$file = '/usr/src/typecho/usr/plugins/AxS3Upload/Plugin.php';
$code = file_get_contents($file);

// ==================== Plugin.php patches ====================

// 1. Fix uploadHandle: 'type' must be file extension, not MIME type
$target1 = "'type' => \$file['type'],";
$replace1 = "'type' => strtolower(pathinfo(\$file['name'], PATHINFO_EXTENSION)),";
if (strpos($code, $target1) !== false) {
    $code = str_replace($target1, $replace1, $code);
    echo "Fixed uploadHandle type field OK\n";
}

// 2. Touch backup trigger after successful upload
$target2 = "'mime'  =>  Typecho_Common::mimeContentType(\$fullPath)";
$replace2 = "'mime'  =>  \$file['type']";
if (strpos($code, $target2) !== false) {
    $code = str_replace($target2, $replace2, $code);
    echo "Fixed uploadHandle mime field OK\n";
}
// add touch before the return ]
$target2b = "            ];\n        } catch (AwsException \$e) {";
$replace2b = "            @touch('/tmp/typecho-backup-trigger');\n            ];\n        } catch (AwsException \$e) {";
if (strpos($code, $target2b) !== false) {
    $code = str_replace($target2b, $replace2b, $code);
    echo "Added backup trigger on upload OK\n";
}

// 3. Touch backup trigger on delete
$target3 = "'Key'    => \$content['attachment']->path,\n            ]);\n            return true;";
$replace3 = "'Key'    => \$content['attachment']->path,\n            ]);\n            @touch('/tmp/typecho-backup-trigger');\n            return true;";
if (strpos($code, $target3) !== false) {
    $code = str_replace($target3, $replace3, $code);
    echo "Added backup trigger on delete OK\n";
}

file_put_contents($file, $code);
echo "Plugin.php patched successfully\n";

// ==================== Contents.php: use stored url ====================
$file2 = '/usr/src/typecho/var/Widget/Base/Contents.php';
$code2 = file_get_contents($file2);

$target4 = "\$attachment->url = Upload::attachmentHandle(\$attachment);";
$replace4 = "\$attachment->url = \$content['url'] ?? Upload::attachmentHandle(\$attachment);";
if (strpos($code2, $target4) !== false) {
    $code2 = str_replace($target4, $replace4, $code2);
    file_put_contents($file2, $code2);
    echo "Patched Contents.php ___attachment to use stored url OK\n";
} else {
    echo "WARNING: Contents.php target not found\n";
    exit(1);
}

// ==================== Post/Edit.php: backup trigger on write ====================
$file3 = '/usr/src/typecho/var/Widget/Contents/Post/Edit.php';
$code3 = file_get_contents($file3);

$target5 = "self::pluginHandle()->call('finishPublish', \$contents, \$this);";
$replace5 = "@touch('/tmp/typecho-backup-trigger');\n            self::pluginHandle()->call('finishPublish', \$contents, \$this);";
if (strpos($code3, $target5) !== false) {
    $code3 = str_replace($target5, $replace5, $code3);
    echo "Added backup trigger on post publish OK\n";
}
$target5b = "self::pluginHandle()->call('finishSave', \$contents, \$this);";
$replace5b = "@touch('/tmp/typecho-backup-trigger');\n            self::pluginHandle()->call('finishSave', \$contents, \$this);";
if (strpos($code3, $target5b) !== false) {
    $code3 = str_replace($target5b, $replace5b, $code3);
    echo "Added backup trigger on post save OK\n";
}
file_put_contents($file3, $code3);
echo "Post/Edit.php patched successfully\n";
