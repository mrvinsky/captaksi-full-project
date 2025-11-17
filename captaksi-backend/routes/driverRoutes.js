const express = require('express');
const router = express.Router();

const {
  registerDriver,
  loginDriver,
  updateDriverStatus,
  getDriverProfile,
  getDriverStats,
  updateDriverProfile,
  getDriverVehicle,        // ← Araç endpoints
  updateDriverVehicle      // ← Araç endpoints
} = require('../controllers/driverController');

const authDriver = require('../middleware/authDriver');
const upload = require('../middleware/upload'); // multer

// ---------- AUTH ----------
router.post('/register', upload, registerDriver);
router.post('/login', loginDriver);

// ---------- DRIVER STATUS ----------
router.patch('/me/status', authDriver, updateDriverStatus);

// ---------- PROFILE ----------
router.get('/me', authDriver, getDriverProfile);
router.get('/me/stats', authDriver, getDriverStats);
router.put('/me', authDriver, updateDriverProfile);

// ---------- VEHICLE ----------
router.get('/me/vehicles', authDriver, getDriverVehicle);
router.put('/me/vehicles', authDriver, updateDriverVehicle);

module.exports = router;
