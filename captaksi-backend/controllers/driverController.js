// controllers/driverController.js
const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// =========================
// GET NEARBY DRIVERS
// =========================
exports.getNearbyDrivers = async (req, res) => {
  try {
    const { lat, lon } = req.query;
    if (!lat || !lon) {
      return res.status(400).json({ message: 'Konum bilgisi (lat, lon) eksik.' });
    }

    const nearbyDrivers = await db.query(
      `
      SELECT 
        d.id, 
        d.ad, 
        d.puan_ortalamasi, 
        ST_AsGeoJSON(d.anlik_konum) as konum, 
        v.tip_id as vehicle_type_id, 
        vt.tip_adi as vehicle_type_name
      FROM drivers d
      JOIN vehicles v ON d.id = v.surucu_id
      JOIN vehicle_types vt ON v.tip_id = vt.id
      WHERE 
        d.aktif_mi = true AND 
        ST_DWithin(d.anlik_konum::geography, ST_MakePoint($1, $2)::geography, 5000)
      `,
      [lon, lat]
    );

    res.json(nearbyDrivers.rows);
  } catch (err) {
    console.error("Yakındaki sürücüler alınırken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};

// =========================
// REGISTER DRIVER
// =========================
exports.registerDriver = async (req, res) => {
  try {
    const { ad, soyad, telefon_numarasi, email, sifre } = req.body;

    if (!ad || !soyad || !telefon_numarasi || !email || !sifre) {
      return res.status(400).json({ message: "Lütfen tüm alanları doldurun." });
    }

    const salt = await bcrypt.genSalt(10);
    const sifre_hash = await bcrypt.hash(sifre, salt);

    const newDriverResult = await db.query(
      "INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id",
      [ad, soyad, telefon_numarasi, email, sifre_hash]
    );

    const newDriverId = newDriverResult.rows[0].id;

    if (req.files && req.files.profileImage) {
      await db.query(
        "INSERT INTO documents (surucu_id, belge_tipi, dosya_url) VALUES ($1, $2, $3)",
        [newDriverId, 'profil_fotografi', `/uploads/drivers/${newDriverId}/profile.jpg`]
      );
    }

    if (req.files && req.files.criminalRecord) {
      await db.query(
        "INSERT INTO documents (surucu_id, belge_tipi, dosya_url) VALUES ($1, $2, $3)",
        [newDriverId, 'sabika_kaydi', `/uploads/drivers/${newDriverId}/criminal_record.pdf`]
      );
    }

    const payload = { driver: { id: newDriverId } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.status(201).json({
          message: "Sürücü başarıyla oluşturuldu! Onay bekleniyor.",
          driver: { id: newDriverId },
          token
        });
      }
    );
  } catch (err) {
    console.error("Sürücü kaydı sırasında hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};

// =========================
// LOGIN DRIVER
// =========================
exports.loginDriver = async (req, res) => {
  try {
    const { email, sifre } = req.body;

    const driver = await db.query(
      "SELECT * FROM drivers WHERE email = $1",
      [email]
    );

    if (driver.rows.length === 0) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    const isMatch = await bcrypt.compare(sifre, driver.rows[0].sifre_hash);
    if (!isMatch) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    const payload = { driver: { id: driver.rows[0].id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (err) {
    console.error("Sürücü girişi sırasında hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};

// =========================
// UPDATE DRIVER STATUS
// =========================
exports.updateDriverStatus = async (req, res) => {
  try {
    const { aktif, konum } = req.body;
    const driverId = req.driver.id;

    const updateQuery = `
      UPDATE drivers 
      SET aktif_mi = $1, 
          anlik_konum = ST_SetSRID(ST_MakePoint($2, $3), 4326) 
      WHERE id = $4
    `;
    const values = [
      aktif,
      konum.longitude,
      konum.latitude,
      driverId
    ];

    await db.query(updateQuery, values);

    res.json({ message: "Durum ve konum başarıyla güncellendi." });
  } catch (err) {
    console.error("Sürücü durumu güncellenirken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};
