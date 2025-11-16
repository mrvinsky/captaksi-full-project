// routes/driverRoutes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

const authDriverMiddleware = require('../middleware/authDriver');

const {
  registerDriver,
  loginDriver,
  updateDriverStatus,
  getNearbyDrivers
} = require('../controllers/driverController');

// NEARBY DRIVERS
router.get('/nearby', authDriverMiddleware, getNearbyDrivers);

// REGISTER
router.post(
  '/register',
  upload.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'criminalRecord', maxCount: 1 }
  ]),
  registerDriver
);

// LOGIN
router.post('/login', loginDriver);

// STATUS UPDATE (aktif + konum)
router.patch('/me/status', authDriverMiddleware, updateDriverStatus);

module.exports = router;
