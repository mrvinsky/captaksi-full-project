
const db = require('./db');

async function createTables() {
  try {
    console.log('🔌 Connecting to DB...');

    // 1. Create Drivers Table (No GEOMETRY, use FLOAT)
    await db.query(`
      CREATE TABLE IF NOT EXISTS drivers (
        id SERIAL PRIMARY KEY,
        ad VARCHAR(100),
        soyad VARCHAR(100),
        telefon_numarasi VARCHAR(20),
        email VARCHAR(100) UNIQUE,
        sifre_hash VARCHAR(255),
        aktif_mi BOOLEAN DEFAULT FALSE,
        latitude DOUBLE PRECISION DEFAULT 0.0,
        longitude DOUBLE PRECISION DEFAULT 0.0,
        puan_ortalamasi NUMERIC DEFAULT 5.0,
        hesap_onay_durumu VARCHAR(50) DEFAULT 'bekliyor',
        kayit_tarihi TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ Table "drivers" ensured (with lat/lon).');

    // 2. Create Vehicle Types Table
    await db.query(`
      CREATE TABLE IF NOT EXISTS vehicle_types (
        id SERIAL PRIMARY KEY,
        tip_adi VARCHAR(50)
      );
    `);
    console.log('✅ Table "vehicle_types" ensured.');

    // 3. Create Rides Table (No GEOMETRY, use FLOAT)
    await db.query(`
      CREATE TABLE IF NOT EXISTS rides (
        id SERIAL PRIMARY KEY,
        kullanici_id INTEGER REFERENCES users(id),
        surucu_id INTEGER REFERENCES drivers(id),
        baslangic_lat DOUBLE PRECISION,
        baslangic_lng DOUBLE PRECISION,
        bitis_lat DOUBLE PRECISION,
        bitis_lng DOUBLE PRECISION,
        baslangic_adres_metni TEXT,
        bitis_adres_metni TEXT,
        gerceklesen_ucret NUMERIC,
        durum VARCHAR(50) DEFAULT 'beklemede',
        talep_tarihi TIMESTAMP DEFAULT NOW(),
        rating NUMERIC,
        rating_comment TEXT
      );
    `);
    console.log('✅ Table "rides" ensured (with lat/lon).');

    console.log('🎉 All tables initialized successfully (No PostGIS Mode)!');
    process.exit(0);

  } catch (err) {
    console.error('❌ Error creating tables:', err);
    process.exit(1);
  }
}

createTables();
