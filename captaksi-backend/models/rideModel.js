// models/rideModel.js
const db = require('../db');

// İleride gerçek ride oluşturmayı buraya koyacağız
async function createRidePlaceholder(data) {
  // data: { kullanici_id, baslangic_konumu, bitis_konumu, arac_tipi, tahmini_ucret, ... }
  // Şimdilik implement yok, sadece iskelet.
  throw new Error("createRidePlaceholder henüz implement edilmedi.");
}

// Örnek: bir kullanıcının aktif yolculuğunu getir (ileride lazım olabilir)
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
  createRidePlaceholder,
  findActiveRideByUserId,
};
