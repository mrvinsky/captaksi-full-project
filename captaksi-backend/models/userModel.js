// models/userModel.js
const db = require('../db');

// Yeni kullanıcı oluştur
async function createUser({ ad, soyad, telefon_numarasi, email, sifre_hash }) {
  const result = await db.query(
    `
    INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id
    `,
    [ad, soyad, telefon_numarasi, email, sifre_hash]
  );
  return result.rows[0];
}

// Email ile kullanıcı bul
async function findUserByEmail(email) {
  const result = await db.query(
    `SELECT * FROM users WHERE email = $1`,
    [email]
  );
  return result.rows[0] || null;
}

// ID ile kullanıcı bul
async function findUserById(id) {
  const result = await db.query(
    `SELECT id, ad, soyad, email, telefon_numarasi FROM users WHERE id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

// Kullanıcının istatistikleri
async function getUserStats(userId) {
  const result = await db.query(
    `
    SELECT 
      COUNT(*) AS total_rides,
      COALESCE(SUM(gerceklesen_ucret), 0) AS total_spent,
      COALESCE(
        SUM(
          ST_Distance(baslangic_konumu::geography, bitis_konumu::geography)
        ) / 1000,
        0
      ) AS total_distance_km
    FROM rides
    WHERE kullanici_id = $1 AND durum = 'tamamlandi'
    `,
    [userId]
  );

  const row = result.rows[0];
  return {
    total_rides: Number(row.total_rides),
    total_spent: parseFloat(row.total_spent).toFixed(2),
    total_distance_km: parseFloat(row.total_distance_km).toFixed(2),
  };
}

// Kullanıcının geçmiş yolculukları
async function getUserRides(userId) {
  const result = await db.query(
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

  return result.rows;
}

module.exports = {
  createUser,
  findUserByEmail,
  findUserById,
  getUserStats,
  getUserRides,
};
