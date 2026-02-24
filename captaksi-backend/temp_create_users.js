const db = require('./db');
async function run() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      ad VARCHAR(100),
      soyad VARCHAR(100),
      telefon_numarasi VARCHAR(20),
      email VARCHAR(100) UNIQUE,
      sifre_hash VARCHAR(255),
      fcm_token VARCHAR(255),
      verification_code VARCHAR(20),
      is_verified BOOLEAN DEFAULT FALSE,
      aktif_mi BOOLEAN DEFAULT TRUE,
      kayit_tarihi TIMESTAMP DEFAULT NOW()
    );
  `);
  console.log("Users table created");
  process.exit(0);
}
run();
