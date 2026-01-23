const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkAll() {
    try {
        console.log('Checking Users...');
        const users = await pool.query('SELECT id, ad, soyad, email, telefon_numarasi FROM users');
        console.table(users.rows);

        console.log('\nChecking Drivers...');
        const drivers = await pool.query('SELECT id, ad, soyad, email, telefon_numarasi FROM drivers');
        console.table(drivers.rows);

        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

checkAll();
