// controllers/rideController.js
exports.createRide = async (req, res) => {
  try {
    // Henüz tamamlanmadı (server.js stub ile birebir)
    return res.status(501).json({
      message: "Ride oluşturma endpoint'i henüz implement edilmedi."
    });
  } catch (err) {
    console.error("Yolculuk oluşturulurken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};
