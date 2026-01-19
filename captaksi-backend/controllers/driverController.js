// controllers/driverController.js
const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sendVerificationEmail } = require('../services/emailService');

// ---------------- REGISTER ----------------
exports.registerDriver = async (req, res) => {
  try {
    const { ad, soyad, telefon_numarasi, email, sifre, fcm_token, plaka, marka, model, renk } = req.body;
    // req.body içinden düz alanlar okunuyor. Multipart olduğu için vehicle objesi olarak gelmeyebilir.

    // Email kontrolü
    const existingDriver = await db.query("SELECT id FROM drivers WHERE email=$1", [email]);
    if (existingDriver.rows.length > 0) {
      return res.status(400).json({ message: "Bu email adresi zaten kayıtlı." });
    }

    const salt = await bcrypt.genSalt(10);
    const sifre_hash = await bcrypt.hash(sifre, salt);

    // 6 haneli kod
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Transaction Başlat
    await db.query('BEGIN');

    const newDriver = await db.query(
      "INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash, fcm_token, verification_code) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id, is_verified, is_approved",
      [ad, soyad, telefon_numarasi, email, sifre_hash, fcm_token, verificationCode]
    );

    const driverId = newDriver.rows[0].id;

    // Araç Ekleme
    // Araç Ekleme
    // Varsayılan tip_id=1 (Taksi)
    const vehicleType = 1;

    // Araç da zorunlu olsun mu? Evet.
    if (plaka) {
      await db.query(
        "INSERT INTO vehicles (surucu_id, tip_id, plaka, marka, model, renk) VALUES ($1, $2, $3, $4, $5, $6)",
        [driverId, vehicleType, plaka, marka, model, renk]
      );
    }

    // Transaction Bitiş
    await db.query('COMMIT');

    // Email gönder
    await sendVerificationEmail(email, verificationCode);

    const payload = { driver: { id: driverId } };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "5h" });

    res.status(201).json({
      message: "Sürücü oluşturuldu! Lütfen emailinizi doğrulayın.",
      token,
      id: driverId,
      is_verified: newDriver.rows[0].is_verified,
      is_approved: newDriver.rows[0].is_approved || false
    });
  } catch (err) {
    await db.query('ROLLBACK');
    console.log(err);
    if (err.code === '23505') { // Unique constraint violation için yedek kontrol
      return res.status(400).json({ message: "Bu email veya telefon zaten kayıtlı." });
    }
    res.status(500).json({ message: "Sunucu hatası: " + err.message });
  }
};

// ---------------- LOGIN ----------------
exports.loginDriver = async (req, res) => {
  try {
    const { email, sifre, fcm_token } = req.body;

    const driver = await db.query("SELECT * FROM drivers WHERE email=$1", [email]);
    if (driver.rows.length === 0)
      return res.status(400).json({ message: "Geçersiz giriş" });

    const isMatch = await bcrypt.compare(sifre, driver.rows[0].sifre_hash);
    if (!isMatch)
      return res.status(400).json({ message: "Geçersiz giriş" });

    // FCM Token Güncelle
    if (fcm_token) {
      await db.query("UPDATE drivers SET fcm_token = $1 WHERE id = $2", [fcm_token, driver.rows[0].id]);
    }

    const payload = { driver: { id: driver.rows[0].id } };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "5h" });

    res.json({
      token,
      is_verified: driver.rows[0].is_verified,
      is_approved: driver.rows[0].is_approved // [YENİ]
    });
  } catch (err) {
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// ---------------- DURUM / KONUM ----------------
exports.updateDriverStatus = async (req, res) => {
  try {
    const driverId = req.driver.id;
    const { aktif, konum } = req.body;

    await db.query(
      `UPDATE drivers SET 
         aktif_mi=$1,
         latitude=$2,
         longitude=$3
       WHERE id=$4`,
      [aktif, konum.latitude, konum.longitude, driverId]
    );

    res.json({ message: "Güncellendi" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// ---------------- PROFİL GETIR ----------------
exports.getDriverProfile = async (req, res) => {
  try {
    const id = req.driver.id;

    const result = await db.query(
      "SELECT id, ad, soyad, email, telefon_numarasi, aktif_mi, is_approved FROM drivers WHERE id=$1",
      [id]
    );

    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// ---------------- İSTATİSTİKLER ----------------
exports.getDriverStats = async (req, res) => {
  try {
    const id = req.driver.id;

    // PostGIS olmadığı için distance hesabını şimdilik 0 geçiyoruz veya JS tarafında hesaplanabilir.
    // Basit olması adına şimdilik 0.
    const stats = await db.query(`
      SELECT 
        COUNT(*) AS rides,
        COALESCE(SUM(gerceklesen_ucret),0) AS earnings,
        0 AS distance
      FROM rides
      WHERE surucu_id=$1 AND durum='tamamlandi'
    `, [id]);

    res.json(stats.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// ---------------- PROFİL GÜNCELLE ----------------
exports.updateDriverProfile = async (req, res) => {
  try {
    const id = req.driver.id;
    const { ad, soyad, email, telefon_numarasi } = req.body;

    await db.query(
      `UPDATE drivers 
         SET ad=$1, soyad=$2, email=$3, telefon_numarasi=$4
       WHERE id=$5`,
      [ad, soyad, email, telefon_numarasi, id]
    );

    res.json({ message: "Profil güncellendi" });
  } catch (err) {
    res.status(500).json({ message: "Sunucu hatası" });
  }
};
// ---------------- ARAÇ BİLGİLERİ GET ----------------
// ---------------- ARAÇ BİLGİLERİ GET ----------------
exports.getDriverVehicle = async (req, res) => {
  try {
    const id = req.driver.id;

    const result = await db.query(
      "SELECT * FROM vehicles WHERE surucu_id = $1 LIMIT 1",
      [id]
    );

    if (result.rows.length === 0) {
      return res.json({ vehicle: null });
    }

    res.json({ vehicle: result.rows[0] });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};


// ---------------- ARAÇ EKLE ----------------
exports.addDriverVehicle = async (req, res) => {
  try {
    const id = req.driver.id;
    const { marka, model, plaka, renk } = req.body;

    const result = await db.query(
      `INSERT INTO vehicles (surucu_id, marka, model, plaka, renk)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [id, marka, model, plaka, renk]
    );

    res.status(201).json({ vehicle: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// ---------------- ARAÇ GÜNCELLE ----------------
exports.updateDriverVehicle = async (req, res) => {
  try {
    const id = req.driver.id;
    const { marka, model, plaka, renk } = req.body;

    const result = await db.query(
      `UPDATE vehicles
       SET marka=$1, model=$2, plaka=$3, renk=$4
       WHERE surucu_id=$5
       RETURNING *`,
      [marka, model, plaka, renk, id]
    );

    res.json({ vehicle: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Sunucu hatası" });
  }
};
