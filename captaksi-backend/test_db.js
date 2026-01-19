
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function testConnection() {
    try {
        console.log('🔌 Veritabanına bağlanılıyor...');
        const res = await pool.query('SELECT NOW() as zaman, version()');
        console.log('✅ Bağlantı BAŞARILI!');
        console.log('🕒 Sunucu Zamanı:', res.rows[0].zaman);
        console.log('ℹ️  Versiyon:', res.rows[0].version);
        await pool.end();
        process.exit(0);
    } catch (err) {
        console.error('❌ Bağlantı HATASI:', err.message);
        process.exit(1);
    }
}

testConnection();
