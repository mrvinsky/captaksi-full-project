const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Veritabanı bağlantısını test etmek için basit bir sorgu
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Veritabanı bağlantı hatası!', err.stack);
  } else {
    console.log('Veritabanına başarıyla bağlanıldı:', res.rows[0].now);
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params),
};