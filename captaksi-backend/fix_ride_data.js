
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function fixData() {
    try {
        console.log('🛠️ Veri düzeltiliyor...');
        // Ride 7 is the one we completed
        await pool.query("UPDATE rides SET mesafe_km = 5.5 WHERE id = 7");

        // Check results
        const res = await pool.query("SELECT id, mesafe_km FROM rides WHERE id = 7");
        console.log('✅ Veri güncellendi:', res.rows[0]);

        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

fixData();
