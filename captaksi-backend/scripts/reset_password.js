const db = require('../db');
const bcrypt = require('bcryptjs');

async function resetPassword() {
    try {
        const salt = await bcrypt.genSalt(10);
        const newPasswordHash = await bcrypt.hash('123456', salt);

        // En son eklenen sürücüyü bul ve güncelle
        const res = await db.query(`
      UPDATE drivers 
      SET sifre_hash = $1
      WHERE id = (SELECT id FROM drivers ORDER BY id DESC LIMIT 1)
      RETURNING email;
    `, [newPasswordHash]);

        if (res.rows.length > 0) {
            console.log(`✅ ${res.rows[0].email} kullanıcısının şifresi '123456' olarak güncellendi.`);
        } else {
            console.log("❌ Sürücü bulunamadı.");
        }
        process.exit(0);
    } catch (err) {
        console.error("Hata:", err);
        process.exit(1);
    }
}

resetPassword();
