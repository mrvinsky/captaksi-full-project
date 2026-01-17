// models/rideModel.js
const db = require('../db');

// İleride gerçek ride oluşturmayı buraya koyacağız
// Yeni yolculuk talebi oluştur
async function createRide({
  kullaniciId,
  baslangicLat,
  baslangicLng,
  bitisLat,
  bitisLng,
  baslangicAdres,
  bitisAdres,
  tahminiUcret
}) {
  const result = await db.query(
    `
    INSERT INTO rides (
      kullanici_id, 
      baslangic_lat, 
      baslangic_lng, 
      bitis_lat, 
      bitis_lng, 
      baslangic_adres_metni, 
      bitis_adres_metni, 
      gerceklesen_ucret,
      durum
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'beklemede')
    RETURNING *
    `,
    [
      kullaniciId,
      baslangicLat,
      baslangicLng,
      bitisLat,
      bitisLng,
      baslangicAdres,
      bitisAdres,
      tahminiUcret
    ]
  );
  return result.rows[0];
}

async function findActiveRideByUserId(userId) {
  const result = await db.query(
    `
    SELECT *
    FROM rides
    WHERE kullanici_id = $1
      AND durum IN ('beklemede', 'surucu_buldu', 'yolda')
    ORDER BY talep_tarihi DESC
    LIMIT 1
    `,
    [userId]
  );
  return result.rows[0] || null;
}

module.exports = {
  createRide,
  findActiveRideByUserId,
};
