<?php
// upload.php - المعالج الرئيسي
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('max_execution_time', 300); // 5 دقائق
ini_set('memory_limit', '512M');

$startTime = microtime(true);

function cleanOutput($output) {
    return htmlspecialchars($output, ENT_QUOTES, 'UTF-8');
}

function formatResult($crackedHashes, $speed, $duration, $rawOutput) {
    $html = '';
    
    if (!empty($crackedHashes)) {
        $html .= '<div style="background: #d4edda; padding: 15px; border-radius: 8px; margin-bottom: 20px;">';
        $html .= '<strong style="color: #155724;">✅ تم العثور على ' . count($crackedHashes) . ' هاش مكسور!</strong>';
        $html .= '</div>';
        
        $html .= '<table style="width: 100%; border-collapse: collapse;">';
        $html .= '<thead><tr style="background: #667eea; color: white;"><th style="padding: 10px; text-align: right;">الهاش</th><th style="padding: 10px; text-align: right;">كلمة المرور</th></tr></thead>';
        $html .= '<tbody>';
        foreach ($crackedHashes as $line) {
            if (strpos($line, ':') !== false) {
                list($hash, $password) = explode(':', $line, 2);
                $html .= "<tr style='border-bottom: 1px solid #e0e0e0;'>";
                $html .= "<td style='padding: 10px;'><code>" . cleanOutput($hash) . "</code></td>";
                $html .= "<td style='padding: 10px;'><strong>" . cleanOutput($password) . "</strong></td>";
                $html .= "</tr>";
            }
        }
        $html .= '</tbody></table>';
    } else {
        $html .= '<div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin-bottom: 20px;">';
        $html .= '<strong style="color: #856404;">⚠️ لم يتم العثور على هاشات مكسورة</strong>';
        $html .= '<p style="margin-top: 10px; font-size: 14px;">جرب ملف كلمات أكبر أو نوع هاش مختلف.</p>';
        $html .= '</div>';
    }
    
    $html .= '<div style="background: #e7f3ff; padding: 15px; border-radius: 8px; margin-top: 20px;">';
    $html .= '<strong>📈 الإحصائيات:</strong><br>';
    $html .= '⚡ سرعة التكسير: ' . cleanOutput($speed) . '<br>';
    $html .= '⏱️ الوقت المستغرق: ' . round($duration, 2) . ' ثانية<br>';
    $html .= '</div>';
    
    $html .= '<details style="margin-top: 20px;">';
    $html .= '<summary style="cursor: pointer; color: #667eea; font-weight: bold;">📋 عرض السجل الكامل</summary>';
    $html .= '<pre style="background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 8px; overflow-x: auto; margin-top: 10px; font-size: 11px;">' . cleanOutput($rawOutput) . '</pre>';
    $html .= '</details>';
    
    return $html;
}

// التحقق من رفع الملف
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die("طلب غير صحيح");
}

if (!isset($_FILES['hashfile']) || $_FILES['hashfile']['error'] !== UPLOAD_ERR_OK) {
    die("❌ خطأ في رفع الملف");
}

// إنشاء مجلد مؤقت
$uploadDir = "/tmp/hashcat_" . uniqid() . "/";
mkdir($uploadDir, 0777, true);

$uploadedFile = $uploadDir . basename($_FILES['hashfile']['name']);
move_uploaded_file($_FILES['hashfile']['tmp_name'], $uploadedFile);

$hashType = escapeshellarg($_POST['hash_type']);
$wordlist = escapeshellarg($_POST['wordlist']);
$attackMode = escapeshellarg($_POST['attack_mode']);

// التحقق من وجود ملف الكلمات
if (!file_exists($_POST['wordlist'])) {
    die("❌ ملف كلمات المرور غير موجود: " . $_POST['wordlist']);
}

$outputFile = $uploadDir . "cracked.txt";
$potFile = $uploadDir . "hashcat.pot";

// بناء أمر Hashcat
$targetFile = $uploadedFile;
$fileExtension = strtolower(pathinfo($uploadedFile, PATHINFO_EXTENSION));

// إذا كان ملف CAP، نحتاج إلى تحويله باستخدام hcxpcapngtool
if ($fileExtension == 'cap' || $fileExtension == 'pcap') {
    $hc22000File = $uploadDir . "hash.hc22000";
    $hcxtool = shell_exec("which hcxpcapngtool");
    if (!empty($hcxtool)) {
        exec("hcxpcapngtool -o " . escapeshellarg($hc22000File) . " " . escapeshellarg($uploadedFile) . " 2>&1", $extractOut);
        if (file_exists($hc22000File) && filesize($hc22000File) > 0) {
            $targetFile = $hc22000File;
        }
    }
}

$hashcatCmd = "hashcat -m " . $hashType . " -a " . $attackMode . " " . escapeshellarg($targetFile) . " " . $wordlist . " -o " . escapeshellarg($outputFile) . " --potfile-path=" . escapeshellarg($potFile) . " --force 2>&1";

exec($hashcatCmd, $fullOutput, $retVal);

// قراءة النتائج
$crackedHashes = [];
if (file_exists($outputFile) && filesize($outputFile) > 0) {
    $crackedHashes = file($outputFile, FILE_IGNORE_NEW_LINES);
}

// استخراج السرعة
$outputStr = implode("\n", $fullOutput);
preg_match('/(\d+\.?\d*)\s*([kKmMgG]?)\s*H\/s/', $outputStr, $matches);
$speedValue = isset($matches[1]) ? $matches[1] : '0';
$speedUnit = isset($matches[2]) ? $matches[2] : '';
$speed = $speedValue . " " . $speedUnit . "H/s";

$duration = microtime(true) - $startTime;

// تنظيف الملفات المؤقتة
$cleanup = function($dir) {
    $files = glob($dir . "*");
    foreach ($files as $file) {
        if (is_file($file)) unlink($file);
    }
    rmdir($dir);
};
$cleanup($uploadDir);

echo formatResult($crackedHashes, $speed, $duration, $outputStr);
?>
