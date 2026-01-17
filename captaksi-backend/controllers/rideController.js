// controllers/rideController.js
// controllers/rideController.js
const rideModel = require('../models/rideModel');

exports.createRide = async (req, res) => {
  try {
    const { origin, destination, originAddress, destinationAddress, vehicleTypeId, estimatedFare } = req.body;

    if (!origin || !destination || !vehicleTypeId) {
      return res.status(400).json({ message: "Eksik bilgi." });
    }

    const ride = await rideModel.createRide({
      kullaniciId: req.user.id,
      baslangicLat: origin.latitude,
      baslangicLng: origin.longitude,
      bitisLat: destination.latitude,
      bitisLng: destination.longitude,
      baslangicAdres: originAddress,
      bitisAdres: destinationAddress,
      tahminiUcret: parseFloat(estimatedFare)
    });

    res.status(201).json({
      message: "Yolculuk talebi başarıyla oluşturuldu.",
      rideId: ride.id,
      ride
    });

    // SOCKET.IO BİLDİRİMİ
    const io = req.app.get("socketio");
    if (io) {
      const roomName = `vehicle_type_${vehicleTypeId}`;
      console.log(`📡 Socket: Odadaki sürücülere bildiriliyor -> ${roomName}`);

      io.to(roomName).emit("new_ride_request", {
        ...ride,
        // Frontend'in beklediği formatta ekstra alanlar eklenebilir
        tahmini_ucret: ride.gerceklesen_ucret,
        baslangic_adres_metni: originAddress,
        bitis_adres_metni: destinationAddress
      });
    }

  } catch (err) {
    console.error("Yolculuk oluşturulurken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
};
