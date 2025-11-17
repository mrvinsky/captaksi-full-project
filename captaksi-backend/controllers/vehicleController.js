const db = require('../db');

exports.getDriverVehicle = async (req, res) => {
  try {
    const id = req.driver.id;

    const result = await db.query(
      `SELECT * FROM vehicles WHERE surucu_id=$1 LIMIT 1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Araç bulunamadı" });
    }

    res.json({ vehicle: result.rows[0] });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

exports.updateDriverVehicle = async (req, res) => {
  try {
    const id = req.driver.id;
    const { marka, model, plaka, renk } = req.body;

    await db.query(
      `
      UPDATE vehicles 
      SET marka=$1, model=$2, plaka=$3, renk=$4
      WHERE surucu_id=$5
      `,
      [marka, model, plaka, renk, id]
    );

    res.json({ message: "Araç güncellendi" });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};
