
require('dotenv').config();
const db = require('./db');
const fetch = global.fetch;
const jwt = require('jsonwebtoken');

// Generate Fresh Driver Token
function generateDriverToken(driverId) {
    const payload = {
        driver: { id: driverId }
    };
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });
}

async function approveLastRide() {
    try {
        console.log('🔍 Bekleyen yolculuklar aranıyor...');

        // 1. Son 5 Yolculuğu Getir
        const res = await db.query("SELECT * FROM rides ORDER BY id DESC LIMIT 5");
        console.log(`🔎 Veritabanındaki son ${res.rows.length} yolculuk:`);
        res.rows.forEach(r => console.log(`   - ID: ${r.id}, Durum: ${r.durum}, User: ${r.kullanici_id}`));

        const pendingRide = res.rows.find(r => r.durum === 'beklemede');

        if (!pendingRide) {
            console.log('❌ Bekleyen (beklemede) statüsünde yolculuk bulunamadı!');
            console.log('⏳ (Henüz istek gelmemiş olabilir)');
            process.exit(0);
        }

        const ride = pendingRide;
        console.log(`✅ Yolculuk Bulundu! ID: ${ride.id}, Kalkış: ${ride.kalkis_adresi}`);

        // 2. Token Oluştur
        const driverId = 2; // Simulation Driver ID
        const token = generateDriverToken(driverId);
        console.log(`🔑 Sürücü Token Oluşturuldu (Driver ID: ${driverId})`);

        // 3. Kabul Etme İsteği Gönder
        console.log(`🚖 Sürücü olarak kabul ediliyor...`);

        const acceptRes = await fetch(`http://127.0.0.1:3000/api/rides/${ride.id}/accept`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                'x-auth-token': token
            }
        });

        if (acceptRes.ok) {
            const data = await acceptRes.json();
            console.log('🎉 Yolculuk Başarıyla Kabul Edildi!');
            console.log('Response:', data);
        } else {
            console.error('❌ Hata:', await acceptRes.text());
        }

        process.exit(0);

    } catch (error) {
        console.error('💥 Beklenmedik Hata:', error);
        process.exit(1);
    }
}

approveLastRide();
