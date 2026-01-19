const db = require('../db');

async function runMigration() {
    try {
        console.log('🔄 Migrasyon başlatılıyor...');

        // Users Tablosu Güncellemeleri
        console.log('👤 Users tablosu güncelleniyor...');
        await db.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS fcm_token TEXT,
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS verification_code VARCHAR(10);
    `);

        // Drivers Tablosu Güncellemeleri
        console.log('🚖 Drivers tablosu güncelleniyor...');
        await db.query(`
      ALTER TABLE drivers 
      ADD COLUMN IF NOT EXISTS fcm_token TEXT,
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS verification_code VARCHAR(10);
    `);

        console.log('✅ Migrasyon başarıyla tamamlandı!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migrasyon hatası:', err);
        process.exit(1);
    }
}

runMigration();
