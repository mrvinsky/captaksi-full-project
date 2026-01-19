const db = require('./db');

async function migrate() {
    try {
        console.log("Adding columns...");
        await db.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS puan_ortalamasi NUMERIC(3,1) DEFAULT 5.0;");
        await db.query("ALTER TABLE rides ADD COLUMN IF NOT EXISTS passenger_rating NUMERIC(3,1);");
        await db.query("ALTER TABLE rides ADD COLUMN IF NOT EXISTS passenger_rating_comment TEXT;");
        console.log("Migration successful!");
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

migrate();
