// routes/rideRoutes.js
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { createRide } = require('../controllers/rideController');

// RIDE CREATE (stub - sonra birlikte tamamlayacağız)
router.post('/', authMiddleware, createRide);

module.exports = router;
