const db = require('../db');

async function addApprovalColumn() {
    try {
        // is_approved sütunu ekle (Varsayılan FALSE).
        // Mevcut sürücüler için TRUE yapabiliriz ki sistem bozulmasın, ama yeni kayıtlar FALSE olsun.
        // Ancak kullanıcı "sürücüler kayıt olduğunda admin onayı beklesin" dediği için default FALSE.

        await db.query(`
      ALTER TABLE drivers 
      ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
    `);

        // Mevcut (test amaçlı açılmış) sürücüleri onaylı yapalım ki testler aksamasın,
        // VEYA hepsini onaysız yapıp admin panelinden onaylatabiliriz. 
        // Kullanıcıya kolaylık olsun diye mevcutları onaylayalım.
        await db.query(`UPDATE drivers SET is_approved = TRUE WHERE is_approved IS NULL`);

        console.log("✅ is_approved sütunu eklendi.");
        process.exit(0);
    } catch (err) {
        console.error("❌ Hata:", err);
        process.exit(1);
    }
}

addApprovalColumn();
