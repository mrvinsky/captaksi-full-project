// controllers/rideController.js
// controllers/rideController.js
const rideModel = require('../models/rideModel');
const db = require('../db');

exports.createRide = async (req, res) => {
  try {
    const { origin, destination, originAddress, destinationAddress, vehicleTypeId, estimatedFare } = req.body;

    if (!origin || !destination || !vehicleTypeId) {
      return res.status(400).json({ message: "Eksik bilgi." });
    }

    // Mesafe Hesaplama (Haversine)
    const R = 6371; // km
    const dLat = (destination.latitude - origin.latitude) * Math.PI / 180;
    const dLon = (destination.longitude - origin.longitude) * Math.PI / 180;
    const a =
      0.5 - Math.cos(dLat) / 2 +
      Math.cos(origin.latitude * Math.PI / 180) * Math.cos(destination.latitude * Math.PI / 180) *
      (1 - Math.cos(dLon)) / 2;
    const distanceKm = R * 2 * Math.asin(Math.sqrt(a));

    const ride = await rideModel.createRide({
      kullaniciId: req.user.id,
      baslangicLat: origin.latitude,
      baslangicLng: origin.longitude,
      bitisLat: destination.latitude,
      bitisLng: destination.longitude,
      baslangicAdres: originAddress,
      bitisAdres: destinationAddress,
      tahminiUcret: parseFloat(estimatedFare),
      mesafeKm: distanceKm.toFixed(2)
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

// [YENİ] Sürücü Yolculuğu Kabul Eder
exports.acceptRide = async (req, res) => {
  try {
    const { id } = req.params;
    const driverId = req.driver.id;

    console.log(`🚖 Sürücü (${driverId}) yolculuğu (${id}) kabul ediyor...`);

    // 1. Yolculuğu güncelle (Status -> 'kabul_edildi', Sürücü Ata)
    // Not: Gerçek projede status enum olabilir ('matched', 'accepted' vb.)
    const rideResult = await db.query(
      `UPDATE rides 
        SET surucu_id = $1, durum = 'kabul_edildi'
        WHERE id = $2 AND durum = 'beklemede'
       RETURNING *`,
      [driverId, id]
    );

    if (rideResult.rows.length === 0) {
      return res.status(400).json({ message: "Yolculuk bulunamadı veya başkası tarafından alındı." });
    }

    const ride = rideResult.rows[0];

    // 2. Sürücü Bilgilerini Çek (Yolcuya göndermek için)
    const driverRes = await db.query("SELECT id, ad, soyad, telefon_numarasi, puan_ortalamasi, latitude, longitude FROM drivers WHERE id=$1", [driverId]);
    const driverInfo = driverRes.rows[0];

    // 3. Araç Bilgisini Çek
    const vehicleRes = await db.query("SELECT marka, model, plaka, renk FROM vehicles WHERE surucu_id=$1", [driverId]);
    const vehicleInfo = vehicleRes.rows[0] || {};

    const fullResponse = {
      ride,
      driver: driverInfo,
      vehicle: vehicleInfo,
      message: "Yolculuk kabul edildi."
    };

    // 4. SOCKET.IO -> Yolcuya Bildir
    const io = req.app.get("socketio");
    if (io) {
      const userRoom = `user_${ride.kullanici_id}`;
      console.log(`📡 Socket: Yolcuya bildiriliyor -> ${userRoom}`);

      io.to(userRoom).emit("ride_accepted", fullResponse);
    }

    res.json(fullResponse);

  } catch (err) {
    console.error("Yolculuk kabul hatası:", err.message);
    res.status(500).json({ message: "Sunucu hatası" });
  }
};

// [YENİ] Sürücü Kapıya Geldi (Notify At Pickup)
exports.notifyAtPickup = async (req, res) => {
  try {
    const { id } = req.params;
    const driverId = req.driver.id;

    console.log(`🚖 Sürücü (${driverId}) kapıya geldiğini bildiriyor (Ride: ${id})...`);

    // Check if ride belongs to driver and is in correct state
    const check = await db.query("SELECT * FROM rides WHERE id=$1 AND surucu_id=$2", [id, driverId]);
    if (check.rows.length === 0) return res.status(404).json({ message: "Yolculuk bulunamadı." });

    const ride = check.rows[0];

    // Socket ile bildir
    const io = req.app.get("socketio");
    if (io) {
      io.to(`user_${ride.kullanici_id}`).emit("driver_arrived", {
        rideId: ride.id,
        message: "Sürücünüz kapıda!"
      });
    }

    res.json({ message: "Bildirim gönderildi." });

  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};

// [YENİ] Yolculuğu Başlat (Start Ride)
exports.startRide = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`▶️ Yolculuk Başlatılıyor (ID: ${id})...`);

    const result = await db.query(
      "UPDATE rides SET durum='basladi' WHERE id=$1 RETURNING *",
      [id]
    );

    const ride = result.rows[0];

    const io = req.app.get("socketio");
    if (io) {
      io.to(`user_${ride.kullanici_id}`).emit("ride_started", {
        rideId: ride.id,
        message: "Yolculuk başladı."
      });
    }
    res.json(ride);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};

// [YENİ] Yolculuğu Bitir (Complete Ride)
exports.completeRide = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🏁 Yolculuk Tamamlanıyor (ID: ${id})...`);

    const result = await db.query(
      "UPDATE rides SET durum='tamamlandi' WHERE id=$1 RETURNING *",
      [id]
    );
    const ride = result.rows[0];

    const io = req.app.get("socketio");
    if (io) {
      io.to(`user_${ride.kullanici_id}`).emit("ride_completed", {
        rideId: ride.id,
        ucret: ride.gerceklesen_ucret || ride.tahmini_ucret,
        message: "Yolculuk tamamlandı."
      });
    }
    res.json(ride);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};

// [YENİ] Sürücüyü Oyla (Rate Ride)
exports.rateRide = async (req, res) => {
  try {
    const { id } = req.params;
    // Frontend sends: driving_quality, politeness, cleanliness, comment
    const { driving_quality, politeness, cleanliness, comment } = req.body;

    console.log(`⭐ Sürücü Oylanıyor (Ride: ${id})... DQ:${driving_quality} P:${politeness} C:${cleanliness}`);

    // Calculate Average Rating
    const dq = Number(driving_quality) || 0;
    const p = Number(politeness) || 0;
    const c = Number(cleanliness) || 0;

    let avgRating = 0;
    if (dq > 0 && p > 0 && c > 0) {
      avgRating = (dq + p + c) / 3;
    } else {
      avgRating = Number(req.body.rating) || 5;
    }

    // Format comment to include details
    const detailedComment = `[DQ:${dq} P:${p} C:${c}] ${comment || ''}`;

    // 1. Yolculuğa puanı ekle
    const rideRes = await db.query(
      "UPDATE rides SET rating=$1, rating_comment=$2 WHERE id=$3 AND kullanici_id=$4 RETURNING surucu_id",
      [avgRating.toFixed(1), detailedComment, id, req.user.id]
    );

    if (rideRes.rows.length === 0) {
      return res.status(404).json({ message: "Yolculuk bulunamadı veya size ait değil." });
    }

    const driverId = rideRes.rows[0].surucu_id;

    // 2. Sürücünün ortalamasını güncelle
    if (driverId) {
      const avgRes = await db.query(
        "SELECT AVG(rating) as ortalama FROM rides WHERE surucu_id=$1 AND rating IS NOT NULL",
        [driverId]
      );
      const newAvg = parseFloat(avgRes.rows[0].ortalama).toFixed(1);

      await db.query("UPDATE drivers SET puan_ortalamasi=$1 WHERE id=$2", [newAvg, driverId]);
      console.log(`⭐ Sürücü (${driverId}) yeni ortalaması: ${newAvg}`);
    }

    res.json({ message: "Puan verildi.", new_average: avgRating });

  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};

// [YENİ] Yolcuyu Oyla (Rate User)
exports.rateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body;

    // rating: 1-5 expected
    const score = Number(rating) || 5;

    console.log(`⭐ Yolcu Oylanıyor (Ride: ${id})... Puan: ${score}`);

    // Driver ID comes from req.driver.id (set by authDriver)
    // NOT req.user.id
    const driverId = req.driver.id;

    // 1. Yolculuğa yolcu puanını ekle
    const rideRes = await db.query(
      "UPDATE rides SET passenger_rating=$1, passenger_rating_comment=$2 WHERE id=$3 AND surucu_id=$4 RETURNING kullanici_id",
      [score, comment, id, driverId]
    );

    if (rideRes.rows.length === 0) {
      return res.status(404).json({ message: "Yolculuk bulunamadı veya size ait değil." });
    }

    const userId = rideRes.rows[0].kullanici_id;

    // 2. Kullanıcının ortalamasını güncelle
    if (userId) {
      const avgRes = await db.query(
        "SELECT AVG(passenger_rating) as ortalama FROM rides WHERE kullanici_id=$1 AND passenger_rating IS NOT NULL",
        [userId]
      );
      const newAvg = parseFloat(avgRes.rows[0].ortalama).toFixed(1);

      await db.query("UPDATE users SET puan_ortalamasi=$1 WHERE id=$2", [newAvg, userId]);
      console.log(`⭐ Yolcu (${userId}) yeni ortalaması: ${newAvg}`);
    }

    res.json({ message: "Yolcu puanlandı.", new_average: score });

  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.toString() });
  }
};
// [YENİ] Yolcu İptal (Cancel By User)
exports.cancelRideByUser = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    console.log(`🛑 Yolcu (${userId}) yolculuğu (${id}) iptal ediyor...`);

    // 1. Yolculuğu bul ve durumunu kontrol et
    const check = await db.query("SELECT * FROM rides WHERE id=$1 AND kullanici_id=$2", [id, userId]);
    if (check.rows.length === 0) return res.status(404).json({ message: "Yolculuk bulunamadı." });

    const ride = check.rows[0];
    if (['tamamlandi', 'iptal_edildi'].includes(ride.durum)) {
      return res.status(400).json({ message: "Bu yolculuk zaten bitmiş veya iptal edilmiş." });
    }

    // 2. Durumu güncelle
    await db.query("UPDATE rides SET durum='iptal_edildi' WHERE id=$1", [id]);

    // 3. Varsa sürücüye bildir
    if (ride.surucu_id) {
      const io = req.app.get("socketio");
      if (io) {
        // Driver oda isimlendirmesi: driver_{id} (server.js'de tanımlamıştık)
        io.to(`driver_${ride.surucu_id}`).emit('ride_cancelled', {
          rideId: id,
          message: "Yolcu yolculuğu iptal etti."
        });
      }
    }

    res.json({ message: "Yolculuk iptal edildi." });

  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};

// [YENİ] Sürücü İptal (Cancel By Driver)
exports.cancelRideByDriver = async (req, res) => {
  try {
    const { id } = req.params;
    const driverId = req.driver.id;
    console.log(`🛑 Sürücü (${driverId}) yolculuğu (${id}) iptal ediyor...`);

    const check = await db.query("SELECT * FROM rides WHERE id=$1 AND surucu_id=$2", [id, driverId]);
    if (check.rows.length === 0) return res.status(404).json({ message: "Yolculuk bulunamadı." });

    const ride = check.rows[0];
    if (['tamamlandi', 'iptal_edildi'].includes(ride.durum)) {
      return res.status(400).json({ message: "Bu yolculuk zaten bitmiş veya iptal edilmiş." });
    }

    await db.query("UPDATE rides SET durum='iptal_edildi' WHERE id=$1", [id]);

    // Yolcuya bildir
    const io = req.app.get("socketio");
    if (io) {
      io.to(`user_${ride.kullanici_id}`).emit('ride_cancelled', {
        rideId: id,
        message: "Sürücü yolculuğu iptal etti."
      });
    }

    res.json({ message: "Yolculuk iptal edildi." });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Hata" });
  }
};
