const db = require('./db');
const bcrypt = require('bcryptjs');

async function seed() {
    try {
        console.log("Seeding comprehensive test data started...");

        // Vehicle Types
        await db.query(`
            ALTER TABLE vehicle_types ADD COLUMN IF NOT EXISTS taban_ucret NUMERIC DEFAULT 0;
            ALTER TABLE vehicle_types ADD COLUMN IF NOT EXISTS km_ucreti NUMERIC DEFAULT 0;
            ALTER TABLE vehicle_types ADD COLUMN IF NOT EXISTS aciklama VARCHAR(255);
        `);

        await db.query(`
            INSERT INTO vehicle_types (id, tip_adi, taban_ucret, km_ucreti, aciklama) VALUES
            (1, 'Standart', 30.0, 15.0, 'Gunluk Standart Tarife'),
            (2, 'VIP', 60.0, 30.0, 'Mercedes Vito Luks Yolculuk')
            ON CONFLICT (id) DO UPDATE SET taban_ucret = EXCLUDED.taban_ucret, km_ucreti = EXCLUDED.km_ucreti;
        `);

        // Hash passwords
        const userHash = await bcrypt.hash('a1b2c3d4e5f6g7h8', 10);
        const driverHash = await bcrypt.hash('hash123', 10);

        // Users
        await db.query(`
            ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255);
        `);

        await db.query(`
            INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash, aktif_mi) VALUES
            ('Ayse', 'Yilmaz', '5551001010', 'ayse@user.com', $1, true),
            ('Fatma', 'Demir', '5551001011', 'fatma@user.com', $1, true),
            ('Ahmet', 'Kaya', '5551001012', 'ahmet@user.com', $1, true),
            ('Mehmet', 'Ozturk', '5551001013', 'mehmet@user.com', $1, true),
            ('Mustafa', 'Aydin', '5551001014', 'mustafa@user.com', $1, true)
            ON CONFLICT (email) DO UPDATE SET sifre_hash = EXCLUDED.sifre_hash;
        `, [userHash]);

        // Drivers
        await db.query(`
            ALTER TABLE drivers ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
            ALTER TABLE drivers ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255);
        `);

        await db.query(`
            INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash, aktif_mi, hesap_onay_durumu, is_approved) VALUES
            ('Ali', 'Kaptan', '5332002020', 'ali@driver.com', $1, true, 'onaylandi', true),
            ('Hasan', 'Usta', '5332002021', 'hasan@driver.com', $1, true, 'onaylandi', true),
            ('Huseyin', 'Sari', '5332002022', 'huseyin@driver.com', $1, true, 'bekliyor', false),
            ('Ibrahim', 'Beyaz', '5332002023', 'ibrahim@driver.com', $1, false, 'reddedildi', false),
            ('Ismail', 'Genc', '5332002024', 'ismail@driver.com', $1, true, 'onaylandi', true)
            ON CONFLICT (email) DO UPDATE SET sifre_hash = EXCLUDED.sifre_hash;
        `, [driverHash]);

        // Get IDs
        const users = await db.query("SELECT id FROM users LIMIT 5");
        const drivers = await db.query("SELECT id FROM drivers WHERE hesap_onay_durumu = 'onaylandi' LIMIT 3");

        if (users.rows.length >= 5 && drivers.rows.length >= 3) {
            const u1 = users.rows[0].id;
            const u2 = users.rows[1].id;
            const u3 = users.rows[2].id;
            const u4 = users.rows[3].id;
            const u5 = users.rows[4].id;

            const d1 = drivers.rows[0].id; // Ali
            const d2 = drivers.rows[1].id; // Hasan
            const d3 = drivers.rows[2].id; // Ismail

            // Rides
            await db.query(`
                ALTER TABLE rides ADD COLUMN IF NOT EXISTS mesafe_km NUMERIC DEFAULT 0;
            `);

            await db.query(`
               INSERT INTO rides (kullanici_id, surucu_id, baslangic_adres_metni, bitis_adres_metni, gerceklesen_ucret, durum, talep_tarihi, mesafe_km) VALUES
               ($1, $6, 'Kizilay Meydani, Ankara', 'Tunali Hilmi Caddesi', 155.50, 'tamamlandi', NOW() - INTERVAL '5 days', 5.2),
               ($2, $7, 'ASTI Otogar', 'Bahcelievler 7. Cadde', 210.00, 'tamamlandi', NOW() - INTERVAL '4 days', 7.1),
               ($3, $8, 'Ulus Heykel', 'Eryaman', 450.00, 'tamamlandi', NOW() - INTERVAL '3 days', 22.4),
               ($4, $6, 'Cankaya Cinnah Cd.', 'Atakule', 90.00, 'tamamlandi', NOW() - INTERVAL '2 days', 3.0),
               ($5, null, 'Etimesgut Havaalani', 'Bilkent Center', 0, 'beklemede', NOW() - INTERVAL '1 hours', 0),
               ($1, $7, 'Umitkoy Metro', 'Gordion AVM', 0, 'iptal', NOW() - INTERVAL '1 days', 0),
               ($2, $8, 'Batikent Meydan', 'Ostim Sanayi', 340.50, 'tamamlandi', NOW(), 12.5)
           `, [u1, u2, u3, u4, u5, d1, d2, d3]);
        }

        console.log("Seeding comprehensive data completed successfully!");
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
seed();
