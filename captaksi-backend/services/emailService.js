const nodemailer = require('nodemailer');

// Mock Transport (Eğer SMTP ayarı yoksa console'a basar)
let transporter;

if (process.env.SMTP_HOST && process.env.SMTP_USER) {
    transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT || 587,
        secure: false, // true for 465, false for other ports
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
} else {
    // Geliştirme ortamı için JSON transport (sadece loglar)
    // Veya Ethereal kullanılabilir ama basitlik için console
    console.log("ℹ️ SMTP Ayarları bulunamadı. Email servisi 'console' modunda çalışacak.");
}

/**
 * Doğrulama kodu gönderir
 * @param {string} toEmail 
 * @param {string} code 
 */
async function sendVerificationEmail(toEmail, code) {
    const subject = "Ali Bin Ali Hesap Doğrulama Kodu";
    const text = `Merhaba,\n\nAli Bin Ali hesap doğrulama kodunuz: ${code}\n\nBu kodu kimseyle paylaşmayın.`;
    const html = `
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
      <h2 style="color: #FFD600;">Ali Bin Ali Doğrulama</h2>
      <p>Merhaba,</p>
      <p>Hesap güvenliğiniz için doğrulama kodunuz aşağıdadır:</p>
      <h1 style="letter-spacing: 5px; background: #f4f4f4; padding: 10px; display: inline-block;">${code}</h1>
      <p>Bu kodu uygulamadaki doğrulama ekranına giriniz.</p>
    </div>
  `;

    if (transporter) {
        try {
            let info = await transporter.sendMail({
                from: '"Ali Bin Ali Security" <security@alibinali.com>',
                to: toEmail,
                subject: subject,
                text: text,
                html: html
            });
            console.log("📧 Email gönderildi: %s", info.messageId);
        } catch (err) {
            console.error("❌ Email gönderilemedi:", err);
        }
    } else {
        // Mock Gönderim
        console.log("================ MOCK EMAIL ================");
        console.log(`To: ${toEmail}`);
        console.log(`Verification Code: ${code}`);
        console.log("============================================");
    }
}

module.exports = {
    sendVerificationEmail
};
