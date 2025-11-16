// models/vehicleModel.js
const db = require('../db');

// Tüm araç tiplerini getir
async function getAllVehicleTypes() {
  const result = await db.query(
    `
    SELECT id, tip_adi, aciklama, taban_ucret, km_ucreti
    FROM vehicle_types
    ORDER BY id ASC
    `
  );
  return result.rows;
}

module.exports = {
  getAllVehicleTypes,
};
