
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function getLastRider() {
    try {
        // 1. Get last ride's user ID
        const rideRes = await pool.query('SELECT kullanici_id FROM rides ORDER BY id DESC LIMIT 1');

        if (rideRes.rows.length === 0) {
            console.log('❌ Hiç yolculuk bulunamadı.');
            process.exit(0);
        }

        const userId = rideRes.rows[0].kullanici_id;

        // 2. Get User Details
        const userRes = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
        const user = userRes.rows[0];

        console.log('🔍 Son Yolcu Bulundu:', user.email);

        // 3. Reset Password to '123456'
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash('123456', salt);

        await pool.query('UPDATE users SET sifre_hash = $1 WHERE id = $2', [hash, userId]);

        console.log('✅ Şifre "123456" olarak güncellendi.');
        console.log('--- KİMLİK BİLGİLERİ ---');
        console.log(`Email: ${user.email}`);
        console.log(`Şifre: 123456`);

        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

getLastRider();
