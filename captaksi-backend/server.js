require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const cors = require('cors');
const jwt = require('jsonwebtoken');
const db = require('./db');
const helmet = require('helmet');

const authMiddleware = require('./middleware/auth');
const authDriverMiddleware = require('./middleware/authDriver');

// =======================
// ROUTES
// =======================
const userRoutes = require('./routes/userRoutes');
const driverRoutes = require('./routes/driverRoutes');
const rideRoutes = require('./routes/rideRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PATCH", "DELETE"]
  }
});

const PORT = process.env.PORT || 3000;

// =======================
// GLOBAL MIDDLEWARE
// =======================
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' ? ['https://admin.captaksi.com'] : '*', // Prodüksiyon için düzenleyiniz
  credentials: true
}));
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
      console.log(`Socket ${socket.id} (Sürücü) token hatası: ${err.message}`);
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
      console.log(`Socket ${socket.id} (Yolcu) token hatası: ${err.message}`);
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
// MODÜLER ROTALAR
// =======================
app.use('/api/users', userRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/admin', adminRoutes);

// =======================
// SERVER BAŞLAT
// =======================
server.listen(PORT, () => {
  console.log(`🚖 captaksi sunucusu ${PORT} portunda çalışıyor...`);
});
app.use("/api/vehicles", require("./routes/vehicleRoutes"));
