<?php
// upload.php - نسخة متوافقة مع Railway
$startTime = microtime(true);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die("طلب غير صحيح");
}

// دالة لعرض النتائج بشكل جميل
function formatOutput($output, $speed, $crackedHashes) {
    $html = "<h3>✅ نتائج التكسير</h3>";
    $html .= "<p>⚡ السرعة: <strong>{$speed}</strong> هاش/ثانية</p>";
    $html .= "<h4>🔓 الهاشات المكسورة:</h4><pre>";
    if (empty($crackedHashes)) {
        $html .= "لا توجد هاشات مكسورة (جرب ملف كلمات أكبر أو نوع هاش صحيح)";
    } else {
        $html .= implode("\n", $crackedHashes);
    }
    $html .= "</pre><hr><details><summary>📋 السجل الكامل</summary><pre>" . htmlspecialchars($output) . "</pre></details>";
    return $html;
}

if (!isset($_FILES['capfile']) || $_FILES['capfile']['error'] !== UPLOAD_ERR_OK) {
    die("خطأ في رفع ملف CAP");
}

$uploadDir = "/tmp/hashcat_uploads/";
if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

$capPath = $uploadDir . uniqid() . "_" . basename($_FILES['capfile']['name']);
move_uploaded_file($_FILES['capfile']['tmp_name'], $capPath);

$hashType = escapeshellarg($_POST['hash_type']);
$wordlist = $_POST['wordlist'];

// التحقق من وجود ملف كلمات المرور
if (!file_exists($wordlist)) {
    die("⚠️ ملف كلمات المرور غير موجود: $wordlist");
}

// استخراج الهاش من ملف CAP (لـ WPA/WPA2)
$hashFile = $uploadDir . "hash_" . uniqid() . ".hc22000";

// محاولة استخراج الهاش باستخدام hcxpcapngtool (إذا كان موجوداً)
$hcxtools = shell_exec("which hcxpcapngtool");
if (empty($hcxtools)) {
    // إذا لم يكن hcxtools موجوداً، استخدم طريقة بديلة: hashcat -m 2500 تدعم .cap مباشرة
    $targetHash = $capPath;
    $isDirectCap = true;
} else {
    $cmd_extract = "hcxpcapngtool -o " . escapeshellarg($hashFile) . " " . escapeshellarg($capPath) . " 2>&1";
    exec($cmd_extract, $extractOut, $extractRet);
    if (file_exists($hashFile) && filesize($hashFile) > 0) {
        $targetHash = $hashFile;
        $isDirectCap = false;
    } else {
        $targetHash = $capPath;
        $isDirectCap = true;
    }
}

// تشغيل Hashcat
$outputFile = $uploadDir . "result_" . uniqid();
$hashcatCmd = "hashcat -m " . $hashType . " -a 0 " . escapeshellarg($targetHash) . " " . escapeshellarg($wordlist) . " -o " . escapeshellarg($outputFile) . " --potfile-disable 2>&1";

exec($hashcatCmd . "; echo 'EXIT_CODE:' . $?", $fullOutput, $retVal);

// قراءة النتائج
$cracked = [];
if (file_exists($outputFile)) {
    $cracked = file($outputFile, FILE_IGNORE_NEW_LINES);
}

// استخراج السرعة من مخرجات hashcat
$speedOutput = implode("\n", $fullOutput);
preg_match('/(\d+\.?\d*)\s+[kKmMgG]?H\/s/', $speedOutput, $matches);
$speed = isset($matches[1]) ? $matches[1] . " H/s" : "غير متاحة";

$duration = round(microtime(true) - $startTime, 2);
$speedText = $speed . " (زمن: {$duration} ثانية)";

// تنظيف الملفات المؤقتة
@unlink($capPath);
@unlink($hashFile);
if (!$isDirectCap && file_exists($targetHash)) @unlink($targetHash);

echo formatOutput(implode("\n", $fullOutput), $speedText, $cracked);
