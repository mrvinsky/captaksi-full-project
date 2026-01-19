const db = require('../db');

async function forceApprove() {
    try {
        const res = await db.query(`
      UPDATE drivers 
      SET is_verified = true, is_approved = true
      WHERE id = (SELECT id FROM drivers ORDER BY id DESC LIMIT 1)
      RETURNING email;
    `);
        console.log(`✅ ${res.rows[0].email} MANUEL OLARAK onaylandı ve doğrulandı.`);
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}
forceApprove();
