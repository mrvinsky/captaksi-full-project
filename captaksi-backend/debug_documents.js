const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function debugData() {
    try {
        console.log('--- USERS (Last 3) ---');
        const users = await pool.query('SELECT id, ad, soyad, email FROM users ORDER BY id DESC LIMIT 3');
        console.table(users.rows);

        console.log('\n--- DOCUMENTS (All) ---');
        const docs = await pool.query('SELECT id, kullanici_id, surucu_id, belge_tipi, dosya_url FROM documents ORDER BY id DESC');
        console.table(docs.rows);

        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

debugData();
