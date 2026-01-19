
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function listUsers() {
    try {
        const res = await pool.query('SELECT id, ad, soyad, email, telefon_numarasi FROM users ORDER BY id DESC LIMIT 5');
        console.log('👥 Kullanıcılar:');
        console.table(res.rows);
        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

listUsers();
