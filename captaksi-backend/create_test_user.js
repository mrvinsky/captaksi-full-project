
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

async function createTestUser() {
    try {
        const email = 'yolcu@test.com';
        const password = '123456';

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(password, salt);

        // Check if exists
        const check = await pool.query("SELECT * FROM users WHERE email=$1", [email]);
        if (check.rows.length > 0) {
            console.log('⚠️  Kullanıcı zaten var.');
            console.log('📧 Email:', email);
            console.log('🔑 Şifre:', password);
            // We can optionally update the password here if we wanted to be sure, 
            // but let's assume if it exists it's ours.
            // Let's update it just in case.
            await pool.query("UPDATE users SET sifre_hash=$1 WHERE email=$2", [hash, email]);
            console.log('✅ Şifre güncellendi (123456).');
        } else {
            await pool.query(
                "INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash) VALUES ($1, $2, $3, $4, $5)",
                ['Test', 'Yolcu', '5551112233', email, hash]
            );
            console.log('✅ Yeni test kullanıcısı oluşturuldu!');
            console.log('📧 Email:', email);
            console.log('🔑 Şifre:', password);
        }

        await pool.end();
    } catch (err) {
        console.error(err);
    }
}

createTestUser();
