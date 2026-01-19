const admin = require('firebase-admin');
const path = require('path');
const db = require('../db'); // Veritabanı erişimi için

// Firebase Admin SDK Başlatma
try {
    // PROD: Bu dosya kullanıcı tarafından indirilip kök dizine veya config klasörüne konulmalı.
    // Geliştirme aşamasında dosya yoksa hata vermemesi için try-catch
    const serviceAccount = require('../serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("🔥 Firebase Admin SDK başlatıldı.");
} catch (e) {
    console.warn("⚠️ Firebase serviceAccountKey.json bulunamadı veya hatalı. Push Notification çalışmayabilir.");
    // Mock başlatma (uygulama çökmesin diye)
    if (admin.apps.length === 0) {
        // admin.initializeApp(); // Credentialsız başlatma bazen hata verir, duruma göre bakılır.
    }
}

/**
 * Belirli bir kullanıcıya bildirim gönderir.
 * @param {number} userId - Veritabanındaki user ID (Users tablosu)
 * @param {string} title - Bildirim Başlığı
 * @param {string} body - Bildirim İçeriği
 * @param {object} data - Ek veri (payload)
 */
async function sendToUser(userId, title, body, data = {}) {
    try {
        const res = await db.query("SELECT fcm_token FROM users WHERE id = $1", [userId]);
        if (res.rows.length === 0 || !res.rows[0].fcm_token) {
            console.log(`User ${userId} için FCM token bulunamadı, bildirim atılamadı.`);
            return;
        }

        const token = res.rows[0].fcm_token;
        await sendToToken(token, title, body, data);
    } catch (err) {
        console.error(`User ${userId} bildirim hatası:`, err.message);
    }
}

/**
 * Belirli bir sürücüye bildirim gönderir.
 * @param {number} driverId - Drivers tablosu ID
 * @param {string} title 
 * @param {string} body 
 * @param {object} data 
 */
async function sendToDriver(driverId, title, body, data = {}) {
    try {
        const res = await db.query("SELECT fcm_token FROM drivers WHERE id = $1", [driverId]);
        if (res.rows.length === 0 || !res.rows[0].fcm_token) {
            console.log(`Driver ${driverId} için FCM token bulunamadı, bildirim atılamadı.`);
            return;
        }

        const token = res.rows[0].fcm_token;
        await sendToToken(token, title, body, data);
    } catch (err) {
        console.error(`Driver ${driverId} bildirim hatası:`, err.message);
    }
}

/**
 * Token'a bildirim gönderir (Helper).
 */
async function sendToToken(token, title, body, data) {
    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            ...data
        }, // Flutter tarafında data payload
        token: token
    };

    try {
        const response = await admin.messaging().send(message);
        console.log('FCM Başarılı:', response);
    } catch (error) {
        console.error('FCM Gönderim Hatası:', error);
    }
}

module.exports = {
    sendToUser,
    sendToDriver,
    sendToToken
};
