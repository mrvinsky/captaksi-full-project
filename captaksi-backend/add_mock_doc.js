const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function addMockDoc() {
    try {
        const userId = 2; // Niko Williams
        const docType = 'SABIKA_KAYDI';
        const fileUrl = '/uploads/sabika_kaydi_mock.pdf';

        console.log(`Adding document for User ${userId}...`);

        const res = await pool.query(
            `INSERT INTO documents (kullanici_id, belge_tipi, dosya_url, onay_durumu, yuklenme_tarihi) 
             VALUES ($1, $2, $3, 'yuklendi', NOW()) 
             RETURNING *`,
            [userId, docType, fileUrl]
        );

        console.log('✅ Document added:', res.rows[0]);
        await pool.end();
    } catch (err) {
        console.error('Error adding document:', err);
    }
}

addMockDoc();
