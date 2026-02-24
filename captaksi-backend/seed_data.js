const db = require('./db');

async function seed() {
    try {
        console.log("Seeding started...");

        // Users
        await db.query(`
            INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash, aktif_mi) VALUES
            ('Ahmet', 'Yılmaz', '5551234567', 'ahmet@example.com', 'hash', true),
            ('Ayşe', 'Kaya', '5559876543', 'ayse@example.com', 'hash', true)
            ON CONFLICT (email) DO NOTHING;
        `);

        // Drivers
        await db.query(`
            INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash, aktif_mi, hesap_onay_durumu) VALUES
            ('Mehmet', 'Şoför', '5321112233', 'mehmet@taxi.com', 'hash', true, 'onaylandi'),
            ('Ali', 'Kaptan', '5334445566', 'ali@taxi.com', 'hash', true, 'bekliyor')
            ON CONFLICT (email) DO NOTHING;
        `);

        // Vehicle Types (if not exists)
        await db.query(`
            INSERT INTO vehicle_types (id, tip_adi, taban_ucret, km_ucreti) VALUES
            (1, 'Standart', 25.0, 15.0),
            (2, 'VIP', 50.0, 30.0)
            ON CONFLICT (id) DO UPDATE SET taban_ucret = EXCLUDED.taban_ucret;
        `);

        // Get IDs
        const userRes = await db.query("SELECT id FROM users LIMIT 1");
        const driverRes = await db.query("SELECT id FROM drivers WHERE hesap_onay_durumu = 'onaylandi' LIMIT 1");

        if(userRes.rows.length > 0 && driverRes.rows.length > 0) {
           const uId = userRes.rows[0].id;
           const dId = driverRes.rows[0].id;
           
           // Rides
           await db.query(`
               INSERT INTO rides (kullanici_id, surucu_id, baslangic_adres_metni, bitis_adres_metni, gerceklesen_ucret, durum) VALUES
               ($1, $2, 'Kızılay Meydanı', 'Tunalı Hilmi Caddesi', 125.50, 'tamamlandi'),
               ($1, $2, 'AŞTİ', 'Bahçelievler 7. Cadde', 85.00, 'tamamlandi'),
               ($1, null, 'Ulus', 'Eryaman', 0, 'beklemede')
           `, [uId, dId]);
        }

        console.log("Seeding completed successfully!");
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
seed();
