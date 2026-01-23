const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkAdmins() {
    try {
        console.log('Checking Admins...');
        // Assuming admins table has similar columns or verify columns first?
        // Let's assume generic user columns + username maybe?
        // Best to just select *, or list columns first.
        // Let's try selecting common fields.
        const res = await pool.query('SELECT * FROM admins');
        console.table(res.rows);
        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

checkAdmins();
