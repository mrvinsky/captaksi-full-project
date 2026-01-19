
const db = require('./db');
const fetch = global.fetch;


const jwt = require('jsonwebtoken');
const JWT_SECRET = 'captaksi_guvenli_secret_anahtari_2024';

// Generate Fresh Token for Driver 2
const DRIVER_TOKEN = jwt.sign(
    { driver: { id: 2 } },
    JWT_SECRET,
    { expiresIn: '1h' }
);

const BASE_URL = 'http://127.0.0.1:3000/api/rides';

async function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function runSimulation() {
    try {
        console.log('🔍 Aktif (kabul edilmiş) yolculuk aranıyor...');

        // Find the last accepted ride for Driver 2
        // We look for 'kabul_edildi' or 'basladi' to be robust
        const res = await db.query("SELECT * FROM rides WHERE surucu_id=2 ORDER BY id DESC LIMIT 1");

        if (res.rows.length === 0) {
            console.log('❌ Bu sürücüye ait yolculuk bulunamadı!');
            process.exit(1);
        }

        const ride = res.rows[0];
        console.log(`✅ Yolculuk Bulundu! ID: ${ride.id}, Durum: ${ride.durum}`);

        // 1. Notify At Pickup
        if (ride.durum === 'kabul_edildi') {
            console.log('\n--- 1. SÜRÜCÜ KAPIDA (Notify At Pickup) ---');
            await delay(2000);

            const notifyRes = await fetch(`${BASE_URL}/${ride.id}/notify-arrival`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'x-auth-token': DRIVER_TOKEN }
            });
            console.log('Response:', await notifyRes.json());
        }

        // 2. Start Trip
        if (ride.durum === 'kabul_edildi' || ride.durum === 'basladi') { // Idempotency check loosely
            console.log('\n--- 2. YOLCULUK BAŞLIYOR (Start Ride) ---');
            console.log('⏳ 5 saniye bekleniyor (Yolcu araca biniyor)...');
            await delay(5000);

            const startRes = await fetch(`${BASE_URL}/${ride.id}/start`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'x-auth-token': DRIVER_TOKEN }
            });
            console.log('Response:', await startRes.json());
        }

        // 3. Complete Trip
        console.log('\n--- 3. YOLCULUK TAMAMLANIYOR (Complete Ride) ---');
        console.log('⏳ 10 saniye bekleniyor (Yolculuk sürüyor)...');
        await delay(10000);

        const completeRes = await fetch(`${BASE_URL}/${ride.id}/complete`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'x-auth-token': DRIVER_TOKEN }
        });
        console.log('Response:', await completeRes.json());

        console.log('\n🎉 SİMÜLASYON TAMAMLANDI!');
        process.exit(0);

    } catch (e) {
        console.error('Hata:', e);
        process.exit(1);
    }
}

runSimulation();
