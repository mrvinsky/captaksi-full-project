
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function debugUserStats(userId) {
    try {
        console.log(`🔍 User ID: ${userId} için istatistikler sorgulanıyor...`);

        // 1. Check User exists
        const userRes = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
        if (userRes.rows.length === 0) {
            console.log('❌ Kullanıcı bulunamadı!');
            return;
        }
        console.log('✅ Kullanıcı mevcut:', userRes.rows[0].email);

        // 2. Check Rides
        const ridesRes = await pool.query('SELECT id, durum, gerceklesen_ucret, mesafe_km FROM rides WHERE kullanici_id = $1', [userId]);
        console.log(`📋 Toplam Yolculuk Sayısı: ${ridesRes.rows.length}`);
        console.table(ridesRes.rows);

        // 3. Run the exact Stats Query
        const statsQuery = `
      SELECT 
        COUNT(*) AS total_rides,
        COALESCE(SUM(gerceklesen_ucret), 0) AS total_spent,
        COALESCE(SUM(mesafe_km), 0) AS total_distance_km
      FROM rides
      WHERE kullanici_id = $1 AND durum = 'tamamlandi'
    `;
        const statsRes = await pool.query(statsQuery, [userId]);
        console.log('📊 İstatistik Sorgusu Sonucu:');
        console.log(statsRes.rows[0]);

        await pool.end();
    } catch (err) {
        console.error('❌ HATA:', err);
    }
}

// User ID 12 was the one we found earlier
debugUserStats(12);
