const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkConstraints() {
    try {
        const res = await pool.query(`
            SELECT consrc 
            FROM pg_constraint 
            WHERE conrelid = 'documents'::regclass 
            AND contype = 'c';
        `);
        // Note: consrc is deprecated in newer PG, but let's try. 
        // Or use pg_get_constraintdef(oid)

        const res2 = await pool.query(`
            SELECT pg_get_constraintdef(oid) 
            FROM pg_constraint 
            WHERE conrelid = 'documents'::regclass 
            AND contype = 'c';
        `);

        console.table(res2.rows);
        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

checkConstraints();
