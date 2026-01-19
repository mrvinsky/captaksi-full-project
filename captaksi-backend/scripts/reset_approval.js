const db = require('../db');

async function resetApproval() {
    try {
        const res = await db.query(`
      UPDATE drivers 
      SET is_approved = false, hesap_onay_durumu = 'bekliyor'
      WHERE id = (SELECT id FROM drivers ORDER BY id DESC LIMIT 1)
      RETURNING email;
    `);
        console.log(`✅ ${res.rows[0].email} onayı GERİ ALINDI. Panelden tekrar onayla.`);
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}
resetApproval();
