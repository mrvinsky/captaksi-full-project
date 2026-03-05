<?php
header('Content-Type: application/json; charset=utf-8');

// ─── SMTP YAPILANDIRMASI ───────────────────────────────────
// Bunları kendi hosting/SMTP bilgilerinle değiştir:
define('SMTP_HOST', 'mail.alibinali.com');     // SMTP sunucu adresi
define('SMTP_PORT', 587);                      // TLS için 587, SSL için 465
define('SMTP_USER', 'iletisim@alibinali.com'); // Gönderen mail
define('SMTP_PASS', 'SMTP_SIFRENIZI_GIRIN'); // SMTP şifresi
define('MAIL_TO',   'iletisim@alibinali.com'); // Gelen maillerin düşeceği adres
define('MAIL_FROM_NAME', 'Ali Bin Ali Web');

// ─── YALNIZCA POST İSTEKLERİ ──────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Yöntem izin verilmiyor.']);
    exit;
}

// ─── VERİ ALMA & TEMİZLEME ───────────────────────────────
$name    = trim(htmlspecialchars($_POST['name']    ?? ''));
$email   = trim(htmlspecialchars($_POST['email']   ?? ''));
$subject = trim(htmlspecialchars($_POST['subject'] ?? 'Genel'));
$message = trim(htmlspecialchars($_POST['message'] ?? ''));

// ─── DOĞRULAMA ────────────────────────────────────────────
if (!$name || !$email || !$message) {
    echo json_encode(['success' => false, 'message' => 'Lütfen tüm alanları doldurun.']);
    exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Geçersiz e-posta adresi.']);
    exit;
}
if (strlen($message) < 10) {
    echo json_encode(['success' => false, 'message' => 'Mesaj çok kısa.']);
    exit;
}

// ─── SMTP ÜZERİNDEN MAIL GÖNDER ───────────────────────────
function sendSmtpMail($to, $fromName, $fromEmail, $replyTo, $subject, $body) {
    $socket = @fsockopen(SMTP_HOST, SMTP_PORT, $errno, $errstr, 10);
    if (!$socket) {
        return ['ok' => false, 'err' => "Bağlantı hatası: $errstr ($errno)"];
    }

    $read = fgets($socket, 512);
    if (substr($read, 0, 3) !== '220') {
        fclose($socket);
        return ['ok' => false, 'err' => "Sunucu yanıtı: $read"];
    }

    $cmds = [
        "EHLO " . SMTP_HOST . "\r\n",
        "STARTTLS\r\n",
    ];

    foreach ($cmds as $cmd) {
        fputs($socket, $cmd);
        $resp = fgets($socket, 512);
    }

    // TLS yükseltme
    stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);

    $authCmds = [
        "EHLO " . SMTP_HOST . "\r\n",
        "AUTH LOGIN\r\n",
        base64_encode(SMTP_USER) . "\r\n",
        base64_encode(SMTP_PASS) . "\r\n",
        "MAIL FROM:<" . SMTP_USER . ">\r\n",
        "RCPT TO:<{$to}>\r\n",
        "DATA\r\n",
    ];

    foreach ($authCmds as $cmd) {
        fputs($socket, $cmd);
        $resp = fgets($socket, 512);
    }

    // Mail içeriği
    $headers  = "From: {$fromName} <" . SMTP_USER . ">\r\n";
    $headers .= "Reply-To: {$replyTo}\r\n";
    $headers .= "To: {$to}\r\n";
    $headers .= "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n";
    $headers .= "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
    $headers .= "Content-Transfer-Encoding: base64\r\n";

    fputs($socket, $headers . "\r\n" . base64_encode($body) . "\r\n.\r\n");
    $resp = fgets($socket, 512);

    fputs($socket, "QUIT\r\n");
    fclose($socket);

    if (substr(trim($resp), 0, 3) !== '250') {
        return ['ok' => false, 'err' => "Mail gönderilemedi: $resp"];
    }
    return ['ok' => true];
}

// ─── HTML MAIL ŞABLONU ────────────────────────────────────
$subjectLabels = [
    'genel'   => 'Genel Soru',
    'kaptan'  => 'Kaptan Başvurusu',
    'destek'  => 'Teknik Destek',
    'sikayet' => 'Şikayet / Öneri',
    'basin'   => 'Basın & İletişim',
];
$subjectLabel = $subjectLabels[$subject] ?? $subject;

$htmlBody = "
<!DOCTYPE html>
<html lang='tr'>
<head><meta charset='UTF-8'/><meta name='viewport' content='width=device-width'/></head>
<body style='margin:0;padding:0;background:#13131D;font-family:Arial,sans-serif;'>
  <table width='100%' cellpadding='0' cellspacing='0' style='background:#13131D;padding:40px 20px;'>
    <tr><td align='center'>
      <table width='600' style='background:#1E1E2C;border-radius:20px;overflow:hidden;border:1px solid rgba(255,255,255,.06);'>
        <tr><td style='background:linear-gradient(135deg,#1a1a2e,#13131d);padding:36px 40px;border-bottom:1px solid rgba(255,214,0,.15);'>
          <h1 style='margin:0;color:#FFD600;font-size:24px;letter-spacing:2px;'>🚖 ALI BIN ALI</h1>
          <p style='margin:8px 0 0;color:rgba(255,255,255,.5);font-size:13px;'>Yeni İletişim Mesajı</p>
        </td></tr>
        <tr><td style='padding:36px 40px;'>
          <table width='100%' cellpadding='0' cellspacing='0'>
            <tr>
              <td style='padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05);'>
                <span style='color:rgba(255,255,255,.4);font-size:12px;text-transform:uppercase;letter-spacing:1px;'>Gönderen</span><br/>
                <span style='color:#fff;font-size:16px;font-weight:bold;'>{$name}</span>
              </td>
            </tr>
            <tr>
              <td style='padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05);'>
                <span style='color:rgba(255,255,255,.4);font-size:12px;text-transform:uppercase;letter-spacing:1px;'>E-posta</span><br/>
                <span style='color:#FFD600;font-size:15px;'>{$email}</span>
              </td>
            </tr>
            <tr>
              <td style='padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05);'>
                <span style='color:rgba(255,255,255,.4);font-size:12px;text-transform:uppercase;letter-spacing:1px;'>Kategori</span><br/>
                <span style='display:inline-block;margin-top:6px;padding:4px 14px;background:rgba(255,214,0,.12);color:#FFD600;border-radius:50px;font-size:13px;font-weight:bold;'>{$subjectLabel}</span>
              </td>
            </tr>
            <tr>
              <td style='padding:16px 0 0;'>
                <span style='color:rgba(255,255,255,.4);font-size:12px;text-transform:uppercase;letter-spacing:1px;'>Mesaj</span><br/>
                <p style='color:rgba(255,255,255,.85);font-size:15px;line-height:1.8;background:rgba(255,255,255,.03);padding:18px;border-radius:12px;margin:10px 0 0;border:1px solid rgba(255,255,255,.05);'>{$message}</p>
              </td>
            </tr>
          </table>
        </td></tr>
        <tr><td style='padding:20px 40px;text-align:center;border-top:1px solid rgba(255,255,255,.05);'>
          <p style='color:rgba(255,255,255,.3);font-size:12px;margin:0;'>Bu mesaj alibinali.com üzerinden gönderildi.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
";

// ─── GÖNDER ───────────────────────────────────────────────
$mailSubject = "[Ali Bin Ali] {$subjectLabel} – {$name}";
$result = sendSmtpMail(MAIL_TO, MAIL_FROM_NAME, SMTP_USER, $email, $mailSubject, $htmlBody);

if ($result['ok']) {
    echo json_encode([
        'success' => true,
        'message' => '✅ Mesajınız başarıyla gönderildi! En kısa sürede dönüş yapacağız.'
    ]);
} else {
    error_log('Ali Bin Ali Mail Hatası: ' . $result['err']);
    echo json_encode([
        'success' => false,
        'message' => 'Mesaj gönderilemedi. Lütfen daha sonra tekrar deneyin.'
    ]);
}
