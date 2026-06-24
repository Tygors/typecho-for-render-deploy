<?php
/**
 * Patch editor-js.php: replace dialog-based Markdown file insertion
 * with direct Markdown syntax insertion.
 *
 * Problem: In Markdown mode, Typecho's insertFileToEditor triggers
 * Pagedown's dialog (image/link prompt) and fills in the URL, but
 * the dialog still requires the user to click OK. This is fragile and
 * unreliable — especially for images, where the expected result is an
 * <img> tag in non-Markdown mode or ![](url) in Markdown mode.
 *
 * Fix: Bypass the dialog entirely and insert Markdown syntax directly
 * into the textarea. For images: ![filename](url), for links: [filename](url).
 * Then trigger 'input' so Pagedown refreshes the preview.
 */
$file = '/usr/src/typecho/admin/editor-js.php';
$code = file_get_contents($file);

$target = 'Typecho.insertFileToEditor = function (file, url, isImage) {
            const button = isImage ? imageButton : linkButton;

            options.strings[isImage ? \'imagename\' : \'linkname\'] = file;
            button.trigger(\'click\');

            let checkDialog = setInterval(function () {
                if ($(\'.wmd-prompt-dialog\').length > 0) {
                    $(\'.wmd-prompt-dialog input\').val(url).select();
                    clearInterval(checkDialog);
                    checkDialog = null;
                }
            }, 10);
        };';

$replace = 'Typecho.insertFileToEditor = function (file, url, isImage) {
            const md = isImage ? \'![\' + file + \'](\' + url + \')\' : \'[\' + file + \'](\' + url + \')\',
                sel = textarea.getSelection(),
                offset = (sel ? sel.start : 0) + md.length;

            textarea.replaceSelection(md);
            textarea.setSelection(offset, offset);
            textarea.trigger(\'input\');
        };';

if (strpos($code, $target) !== false) {
    $code = str_replace($target, $replace, $code);
    file_put_contents($file, $code);
    echo "Patched editor-js.php insertFileToEditor (Markdown mode) OK\n";
} else {
    echo "WARNING: Target pattern not found in editor-js.php\n";
    exit(1);
}

echo "editor-js.php patched successfully\n";
