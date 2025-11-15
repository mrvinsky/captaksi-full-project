require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const db = require('./db');

const authMiddleware = require('./middleware/auth');
const authDriverMiddleware = require('./middleware/authDriver');

// --- Admin Middleware ---
const authAdminMiddleware = (req, res, next) => {
  const token = req.header('x-auth-token');
  if (!token) return res.status(401).json({ message: 'Yetki reddedildi, token bulunamadı' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (!decoded.admin) {
      return res.status(401).json({ message: 'Yetki reddedildi, admin yetkisi gerekli.' });
    }
    req.admin = decoded.admin;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token geçerli değil' });
  }
};

// --- Multer (memory storage) ---
const upload = multer({ storage: multer.memoryStorage() });

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PATCH", "DELETE"]
  }
});

const PORT = process.env.PORT || 3000;

// --- Global Middleware ---
app.use(cors());
app.use(express.json());

// =======================
// SOCKET.IO
// =======================
io.on('connection', (socket) => {
  console.log('Bir kullanıcı bağlandı:', socket.id);

  // Sürücü odasına katıl
  socket.on('join_driver_room', async (token) => {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      if (!decoded.driver) return;

      const driverId = decoded.driver.id;

      const vehicle = await db.query(
        "SELECT tip_id FROM vehicles WHERE surucu_id = $1",
        [driverId]
      );
      if (vehicle.rows.length === 0) return;

      const vehicleTypeId = vehicle.rows[0].tip_id;
      const roomName = `vehicle_type_${vehicleTypeId}`;
      socket.join(roomName);

      console.log(`Sürücü ${driverId}, "${roomName}" odasına katıldı.`);
    } catch (err) {
      console.log(`Socket ${socket.id} (Sürücü) için token hatası: ${err.message}`);
    }
  });

  // Yolcu odasına katıl
  socket.on('join_user_room', (token) => {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      if (!decoded.user) return;

      const userId = decoded.user.id;
      const roomName = `user_${userId}`;
      socket.join(roomName);

      console.log(`Yolcu ${userId}, "${roomName}" odasına katıldı.`);
    } catch (err) {
      console.log(`Socket ${socket.id} (Yolcu) için token hatası: ${err.message}`);
    }
  });

  socket.on('disconnect', () => {
    console.log('Kullanıcı ayrıldı:', socket.id);
  });
});

// =======================
// TEMEL ROTALAR
// =======================
app.get('/', (req, res) => {
  res.send('captaksi API sunucusu çalışıyor!');
});

app.get('/db-test', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW()');
    res.json({
      message: 'Veritabanı bağlantısı başarılı!',
      zaman: result.rows[0].now
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Veritabanı bağlantı hatası!' });
  }
});

app.get('/api/vehicle-types', async (req, res) => {
  try {
    const vehicleTypes = await db.query(
      "SELECT id, tip_adi, aciklama, taban_ucret, km_ucreti FROM vehicle_types ORDER BY id ASC"
    );
    res.json(vehicleTypes.rows);
  } catch (err) {
    console.error("Araç tipleri alınırken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// =======================
// USER (YOLCU) ROTALARI
// =======================

// Kayıt
app.post(
  '/api/users/register',
  upload.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'criminalRecord', maxCount: 1 }
  ]),
  async (req, res) => {
    try {
      const { ad, soyad, telefon_numarasi, email, sifre } = req.body;

      const salt = await bcrypt.genSalt(10);
      const sifre_hash = await bcrypt.hash(sifre, salt);

      const newUser = await db.query(
        "INSERT INTO users (ad, soyad, telefon_numarasi, email, sifre_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id",
        [ad, soyad, telefon_numarasi, email, sifre_hash]
      );

      const newUserId = newUser.rows[0].id;

      const payload = { user: { id: newUserId } };
      jwt.sign(
        payload,
        process.env.JWT_SECRET,
        { expiresIn: '5h' },
        (err, token) => {
          if (err) throw err;
          res.status(201).json({
            message: "Kullanıcı başarıyla oluşturuldu!",
            token
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
  }
);

// Giriş
app.post('/api/users/login', async (req, res) => {
  try {
    const { email, sifre } = req.body;

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

    const payload = { user: { id: user.rows[0].id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (err) {
    console.error("Yolcu girişi sırasında hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// Profil + istatistik
app.get('/api/users/me', authMiddleware, async (req, res) => {
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
        COALESCE(SUM(ST_Distance(baslangic_konumu::geography, bitis_konumu::geography)) / 1000, 0) AS total_distance_km
      FROM rides
      WHERE kullanici_id = $1 AND durum = 'tamamlandi'
      `,
      [req.user.id]
    );

    const result = {
      ...user.rows[0],
      stats: {
        total_rides: Number(stats.rows[0].total_rides),
        total_spent: parseFloat(stats.rows[0].total_spent).toFixed(2),
        total_distance_km: parseFloat(stats.rows[0].total_distance_km).toFixed(2),
      },
    };

    res.json(result);
  } catch (err) {
    console.error('Kullanıcı bilgisi alınırken hata:', err.message);
    res.status(500).send('Sunucu hatası');
  }
});

// Kullanıcının tüm geçmiş yolculukları
app.get('/api/users/me/rides', authMiddleware, async (req, res) => {
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
});

// =======================
// DRIVER (SÜRÜCÜ) ROTALARI
// =======================

// Yakındaki sürücüler
app.get('/api/drivers/nearby', authMiddleware, async (req, res) => {
  try {
    const { lat, lon } = req.query;
    if (!lat || !lon) {
      return res.status(400).json({ message: 'Konum bilgisi (lat, lon) eksik.' });
    }

    const nearbyDrivers = await db.query(
      `
      SELECT 
        d.id, 
        d.ad, 
        d.puan_ortalamasi, 
        ST_AsGeoJSON(d.anlik_konum) as konum, 
        v.tip_id as vehicle_type_id, 
        vt.tip_adi as vehicle_type_name
      FROM drivers d
      JOIN vehicles v ON d.id = v.surucu_id
      JOIN vehicle_types vt ON v.tip_id = vt.id
      WHERE 
        d.aktif_mi = true AND 
        ST_DWithin(d.anlik_konum::geography, ST_MakePoint($1, $2)::geography, 5000)
      `,
      [lon, lat] // dikkat: lon, lat sırası korunuyor
    );

    res.json(nearbyDrivers.rows);
  } catch (err) {
    console.error("Yakındaki sürücüler alınırken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// Sürücü kayıt
app.post(
  '/api/drivers/register',
  upload.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'criminalRecord', maxCount: 1 }
  ]),
  async (req, res) => {
    try {
      const { ad, soyad, telefon_numarasi, email, sifre } = req.body;

      if (!ad || !soyad || !telefon_numarasi || !email || !sifre) {
        return res.status(400).json({ message: "Lütfen tüm alanları doldurun." });
      }

      const salt = await bcrypt.genSalt(10);
      const sifre_hash = await bcrypt.hash(sifre, salt);

      const newDriverResult = await db.query(
        "INSERT INTO drivers (ad, soyad, telefon_numarasi, email, sifre_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id",
        [ad, soyad, telefon_numarasi, email, sifre_hash]
      );

      const newDriverId = newDriverResult.rows[0].id;

      // Dosya kayıtlarını DB'ye yazıyoruz, fiziksel kaydetme kısmı başka yerde ele alınabilir.
      if (req.files && req.files.profileImage) {
        await db.query(
          "INSERT INTO documents (surucu_id, belge_tipi, dosya_url) VALUES ($1, $2, $3)",
          [newDriverId, 'profil_fotografi', `/uploads/drivers/${newDriverId}/profile.jpg`]
        );
      }

      if (req.files && req.files.criminalRecord) {
        await db.query(
          "INSERT INTO documents (surucu_id, belge_tipi, dosya_url) VALUES ($1, $2, $3)",
          [newDriverId, 'sabika_kaydi', `/uploads/drivers/${newDriverId}/criminal_record.pdf`]
        );
      }

      const payload = { driver: { id: newDriverId } };
      jwt.sign(
        payload,
        process.env.JWT_SECRET,
        { expiresIn: '5h' },
        (err, token) => {
          if (err) throw err;
          res.status(201).json({
            message: "Sürücü başarıyla oluşturuldu! Onay bekleniyor.",
            driver: { id: newDriverId },
            token
          });
        }
      );
    } catch (err) {
      console.error("Sürücü kaydı sırasında hata:", err.message);
      res.status(500).send("Sunucu hatası");
    }
  }
);

// Sürücü giriş
app.post('/api/drivers/login', async (req, res) => {
  try {
    const { email, sifre } = req.body;

    const driver = await db.query(
      "SELECT * FROM drivers WHERE email = $1",
      [email]
    );
    if (driver.rows.length === 0) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    const isMatch = await bcrypt.compare(sifre, driver.rows[0].sifre_hash);
    if (!isMatch) {
      return res.status(400).json({ message: "Hatalı kullanıcı bilgileri" });
    }

    const payload = { driver: { id: driver.rows[0].id } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (err) {
    console.error("Sürücü girişi sırasında hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// Sürücü durum/konum güncelleme
app.patch('/api/drivers/me/status', authDriverMiddleware, async (req, res) => {
  try {
    const { aktif, konum } = req.body;
    const driverId = req.driver.id;

    const updateQuery = `
      UPDATE drivers 
      SET aktif_mi = $1, 
          anlik_konum = ST_SetSRID(ST_MakePoint($2, $3), 4326) 
      WHERE id = $4
    `;
    const values = [
      aktif,
      konum.longitude,
      konum.latitude,
      driverId
    ];

    await db.query(updateQuery, values);

    res.json({ message: "Durum ve konum başarıyla güncellendi." });
  } catch (err) {
    console.error("Sürücü durumu güncellenirken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// =======================
// RIDES (YOLCULUK) ROTALARI
// =======================

// Şimdilik basit stub - sonra birlikte detaylandırırız
app.post('/api/rides', authMiddleware, async (req, res) => {
  try {
    // TODO: Buraya yolculuk oluşturma (driver match, fiyat hesaplama vs) mantığı eklenecek.
    return res.status(501).json({ message: "Ride oluşturma endpoint'i henüz implement edilmedi." });
  } catch (err) {
    console.error("Yolculuk oluşturulurken hata:", err.message);
    res.status(500).send("Sunucu hatası");
  }
});

// =======================
// SERVER BAŞLAT
// =======================
server.listen(PORT, () => {
  console.log(`🚖 captaksi sunucusu ${PORT} portunda çalışıyor...`);
});
