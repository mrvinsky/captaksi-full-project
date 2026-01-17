// models/driverModel.js
const db = require('../db');

// Yeni sürücü oluştur
async function createDriver({ ad, soyad, telefon_numarasi, email, sifre_hash }) {
  const result = await db.query(
    `
    INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id
    `,
    [ad, soyad, telefon_numarasi, email, sifre_hash]
  );
  return result.rows[0];
}

// Email ile sürücü bul
async function findDriverByEmail(email) {
  const result = await db.query(
    `SELECT * FROM drivers WHERE email = $1`,
    [email]
  );
  return result.rows[0] || null;
}

// Sürücünün durum + konum güncelleme
async function updateDriverStatus({ driverId, aktif, longitude, latitude }) {
  const query = `
    UPDATE drivers 
    SET aktif_mi = $1, 
        longitude = $2,
        latitude = $3 
    WHERE id = $4
  `;
  const values = [aktif, longitude, latitude, driverId];

  await db.query(query, values);
}

// Yakındaki sürücüleri getir
async function findNearbyDrivers({ lat, lon }) {
  const result = await db.query(
    `
    SELECT 
      d.id, 
      d.ad, 
      d.puan_ortalamasi, 
      d.latitude,
      d.longitude,
      v.tip_id as vehicle_type_id, 
      vt.tip_adi as vehicle_type_name
    FROM drivers d
    JOIN vehicles v ON d.id = v.surucu_id
    JOIN vehicle_types vt ON v.tip_id = vt.id
    WHERE 
      d.aktif_mi = true AND 
      (POW(d.longitude - $1, 2) + POW(d.latitude - $2, 2)) < 0.1 
    `,
    [lon, lat]
  );

  return result.rows;
}

// Sürücü için belge kaydı
async function insertDriverDocument({ driverId, belge_tipi, dosya_url }) {
  await db.query(
    `
    INSERT INTO documents (surucu_id, belge_tipi, dosya_url)
    VALUES ($1, $2, $3)
    `,
    [driverId, belge_tipi, dosya_url]
  );
}

module.exports = {
  createDriver,
  findDriverByEmail,
  updateDriverStatus,
  findNearbyDrivers,
  insertDriverDocument,
};
