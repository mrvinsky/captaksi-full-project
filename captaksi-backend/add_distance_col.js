
const db = require('./db');

async function migrate() {
    try {
        console.log('🔌 Connecting to DB...');
        // Add mesafe_km to rides if not exists
        await db.query(`
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='rides' AND column_name='mesafe_km') THEN
                    ALTER TABLE rides ADD COLUMN mesafe_km NUMERIC DEFAULT 0;
                END IF;
            END
            $$;
        `);
        console.log('✅ Column "mesafe_km" ensured.');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

migrate();
