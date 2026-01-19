// controllers/userController.js
const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { sendVerificationEmail } = require('../services/emailService');

// =========================
// REGISTER USER
// =========================
exports.registerUser = async (req, res) => {
  try {
    const { ad, soyad, telefon_numarasi, email, sifre, fcm_token } = req.body;

    const salt = await bcrypt.genSalt(10);
    const sifre_hash = await bcrypt.hash(sifre, salt);

    // 6 haneli doğrulama kodu
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // is_verified default FALSE (DB defaultu)
    const newUser = await db.query(
      "INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash, fcm_token, verification_code) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, is_verified",
      [ad, soyad, telefon_numarasi, email, sifre_hash, fcm_token, verificationCode]
    );

    const newUserId = newUser.rows[0].id;
    const isVerified = newUser.rows[0].is_verified;

    // Email Gönder
    await sendVerificationEmail(email, verificationCode);

    const payload = { user: { id: newUserId } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.status(201).json({
          message: "Kullanıcı başarıyla oluşturuldu! Lütfen emailinizi doğrulayın.",
          token,
          is_verified: isVerified
        });
      }
    );
  } catch (err) {
    console.error("Yolcu kaydı sırasında hata:", err.message);

    if (err.code === '23505') {
      return res.status(400).json({
        message: 'Bu email veya telefon numarası zaten kayıtlı.'
      });
    }

    res.status(500).send("Sunucu hatası");
  }
};

// =========================
// LOGIN USER
// =========================
exports.loginUser = async (req, res) => {
  try {
    const { email, sifre, fcm_token } = req.body;

    const user = await db.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );

    if (user.rows.length === 0) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    const isMatch = await bcrypt.compare(sifre, user.rows[0].sifre_hash);
    if (!isMatch) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    // FCM Token Güncelle
    if (fcm_token) {
      await db.query("UPDATE users SET fcm_token = $1 WHERE id = $2", [fcm_token, user.rows[0].id]);
    }

    const payload = { user: { id: user.rows[0].id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.json({
          token,
          is_verified: user.rows[0].is_verified
        });
      }
    );
  } catch (err) {
    console.error("Yolcu girişi sırasında hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};

// =========================
// GET USER PROFILE + STATS
// =========================
exports.getMyProfile = async (req, res) => {
  try {
    const user = await db.query(
      'SELECT id, ad, soyad, email, telefon_numarasi FROM users WHERE id = $1',
      [req.user.id]
    );

    const stats = await db.query(
      `
      SELECT 
        COUNT(*) AS total_rides,
        COALESCE(SUM(gerceklesen_ucret), 0) AS total_spent,
        COALESCE(SUM(mesafe_km), 0) AS total_distance_km
      FROM rides
      WHERE kullanici_id = $1 AND durum = 'tamamlandi'
      `,
      [req.user.id]
    );

    res.json({
      ...user.rows[0],
      stats: {
        total_rides: Number(stats.rows[0].total_rides),
        total_spent: parseFloat(stats.rows[0].total_spent).toFixed(2),
        total_distance_km: parseFloat(stats.rows[0].total_distance_km).toFixed(2)
      }
    });
  } catch (err) {
    console.error('Kullanıcı bilgisi alınırken hata:', err.message);
    res.status(500).send('Sunucu hatası');
  }
};

// =========================
// GET USER RIDE HISTORY
// =========================
exports.getMyRides = async (req, res) => {
  try {
    const userId = req.user.id;

    const rides = await db.query(
      `
      SELECT 
        r.id, 
        r.baslangic_adres_metni,
        r.bitis_adres_metni, 
        r.gerceklesen_ucret, 
        r.durum, 
        r.rating,
        r.rating_comment,
        r.talep_tarihi,
        d.ad AS surucu_ad,
        d.soyad AS surucu_soyad
      FROM rides r
      LEFT JOIN drivers d ON r.surucu_id = d.id
      WHERE r.kullanici_id = $1
      ORDER BY r.talep_tarihi DESC
      `,
      [userId]
    );

    res.json(rides.rows);
  } catch (err) {
    console.error("Yolcu geçmiş yolculukları alınırken hata:", err.message);
    res.status(500).send("Sunucu Hatası");
  }
};
