const db = require('./db');

async function fixDriversTable() {
    try {
        console.log('Tablo güncelleniyor...');

        // hesap_onay_durumu ekle
        await db.query(`
            ALTER TABLE drivers 
            ADD COLUMN IF NOT EXISTS hesap_onay_durumu VARCHAR(50) DEFAULT 'bekliyor'
        `);
        console.log('hesap_onay_durumu eklendi.');

        // kayit_tarihi ekle
        await db.query(`
            ALTER TABLE drivers 
            ADD COLUMN IF NOT EXISTS kayit_tarihi TIMESTAMP DEFAULT NOW()
        `);
        console.log('kayit_tarihi eklendi.');

        console.log('İşlem tamamamlandı.');
        process.exit(0);
    } catch (err) {
        console.error('Hata:', err);
        process.exit(1);
    }
}

fixDriversTable();
