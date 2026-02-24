const crypto = require('crypto');
const axios = require('axios');
const db = require('../db');

// --- DİKKAT: CİDDİ EKSİK VERİ ---
// Gerçek ortam (Prod) için Müşteri, PayTR Merchant ID, Anahtarı (Key) ve Tuzu (Salt) bilgilerini
// .env dosyasına (PAYTR_MERCHANT_ID, PAYTR_MERCHANT_KEY, PAYTR_MERCHANT_SALT) olarak eklemelidir.
// ---------------------------------

const merchant_id = process.env.PAYTR_MERCHANT_ID || 'MOCK_MERCHANT_ID';
const merchant_key = process.env.PAYTR_MERCHANT_KEY || 'MOCK_MERCHANT_KEY';
const merchant_salt = process.env.PAYTR_MERCHANT_SALT || 'MOCK_MERCHANT_SALT';

// PayTR iFrame Token Oluşturma Endpoint'i
exports.getPaymentToken = async (req, res) => {
    try {
        const { kullanici_email, odeme_tutari, yolculuk_id } = req.body;

        if (!kullanici_email || !odeme_tutari || !yolculuk_id) {
            return res.status(400).json({ status: "error", message: "Eksik parametreler" });
        }

        const user_ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
        const merchant_oid = `ORDER_${yolculuk_id}_${Date.now()}`;
        const user_basket = Buffer.from(JSON.stringify([
            ["Taksi Ucreti", odeme_tutari, 1]
        ])).toString("base64");

        const payment_amount = odeme_tutari * 100; // Kuruş cinsinden

        // MOCK YANIT: Eğer gerçek anahtarlar yoksa sahte bir token dön
        if (merchant_id === 'MOCK_MERCHANT_ID') {
            console.warn(`[PAYTR MOCK] Gerçek PayTR anahtarları bulunamadı. MOCK token üretiliyor. (Sipariş: ${merchant_oid})`);
            return res.json({
                status: "success",
                token: "MOCK_PAYTR_TOKEN_READY_FOR_IFRAME",
                mocked: true
            });
        }

        // [GERÇEK PAYTR İŞLEMİ] 
        // Hash oluşturma: merchant_id + user_ip + merchant_oid + email + payment_amount + user_basket + no_installment + max_installment + currency + test_mode + merchant_salt
        const hashStr = `${merchant_id}${user_ip}${merchant_oid}${kullanici_email}${payment_amount}${user_basket}00TL0${merchant_salt}`;
        const paytr_token = crypto.createHmac('sha256', merchant_key).update(hashStr).digest('base64');

        const params = new URLSearchParams();
        params.append("merchant_id", merchant_id);
        params.append("user_ip", user_ip);
        params.append("merchant_oid", merchant_oid);
        params.append("email", kullanici_email);
        params.append("payment_amount", payment_amount);
        params.append("paytr_token", paytr_token);
        params.append("user_basket", user_basket);
        params.append("debug_on", "1");
        params.append("no_installment", "0");
        params.append("max_installment", "0");
        params.append("user_name", "Captaksi Yolcusu");
        params.append("user_address", "Belirtilmedi");
        params.append("user_phone", "0000000000");
        params.append("merchant_ok_url", "http://localhost:3000/api/payments/paytr/success");
        params.append("merchant_fail_url", "http://localhost:3000/api/payments/paytr/fail");
        params.append("timeout_limit", "30");
        params.append("currency", "TL");
        params.append("test_mode", "0");

        const response = await axios.post('https://www.paytr.com/odeme/api/get-token', params.toString(), {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        });

        if (response.data.status === 'success') {
            res.json({ status: "success", token: response.data.token });
        } else {
            res.status(400).json({ status: "error", message: response.data.reason });
        }

    } catch (err) {
        console.error("PayTR Token Hatası:", err);
        res.status(500).json({ status: "error", message: "Sunucu hatası" });
    }
};

// PayTR Bildirim (Webhook) Endpoint'i - Asenkron olarak ödeme sonucunu alır
exports.paymentCallback = async (req, res) => {
    try {
        const { merchant_oid, status, total_amount, hash } = req.body;

        // Callback doğrulaması
        const hashStr = `${merchant_oid}${merchant_salt}${status}${total_amount}`;
        const expectedHash = crypto.createHmac('sha256', merchant_key).update(hashStr).digest('base64');

        // MOCK işlemi atla, gerçekten PayTR ise doğrula.
        if (merchant_id !== 'MOCK_MERCHANT_ID' && hash !== expectedHash) {
            console.error('PAYTR: Callback doğrulama hatası! (Geçersiz HASH)');
            return res.send('PAYTR notification failed: bad hash');
        }

        const yolculukId = merchant_oid.split('_')[1]; // ORDER_{ID}_{TIMESTAMP}

        if (status === 'success') {
            console.log(`PAYTR: Sipariş ${merchant_oid} başarıyla ödendi.`);
            // Burada yolculuk tablosundaki statüyü "ödendi" yapabilirsin
            // await db.query('UPDATE rides SET odeme_durumu = $1 WHERE id = $2', ['basarili', yolculukId]);
        } else {
            console.warn(`PAYTR: Sipariş ${merchant_oid} ödenemedi. Hata: ${req.body.failed_reason_msg}`);
            // await db.query('UPDATE rides SET odeme_durumu = $1 WHERE id = $2', ['basarisiz', yolculukId]);
        }

        // PayTR'nin bildirimi tekrar göndermemesi için 'OK' dönmek zorunludur.
        res.send('OK');
    } catch (err) {
        console.error("PayTR Callback Hatası:", err);
        res.status(500).send("Sunucu hatası");
    }
};

// Sürücü Para Çekme İsteği Endpoint'i
exports.requestWithdrawal = async (req, res) => {
    try {
        const driverId = req.user.id;
        const { amount, iban } = req.body;

        if (!amount || amount <= 0 || !iban) {
            return res.status(400).json({ message: "Geçerli bir tutar ve IBAN giriniz." });
        }

        // İleride burada 'withdrawals' tablosuna kayıt atılır ve Admin panele düşer
        console.log(`[WITHDRAWAL] Sürücü ID ${driverId}, ${amount} ₺ çekim talebinde bulundu. IBAN: ${iban}`);

        res.json({ message: "Para çekme talebiniz başarıyla alındı ve onay için Admin'e iletildi." });
    } catch (err) {
        console.error("Para çekme hatası:", err);
        res.status(500).json({ message: "Sunucu hatası" });
    }
};
