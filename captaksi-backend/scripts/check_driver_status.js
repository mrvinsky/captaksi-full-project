const db = require('../db');

async function checkStatus() {
    try {
        const res = await db.query(`
      SELECT id, email, is_verified, is_approved 
      FROM drivers 
      ORDER BY id DESC LIMIT 1
    `);
        console.log("Sürücü Durumu:", res.rows[0]);
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}
checkStatus();
