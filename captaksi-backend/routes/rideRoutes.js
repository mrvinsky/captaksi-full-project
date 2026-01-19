// routes/rideRoutes.js
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth'); // Yolcu auth
const authDriver = require('../middleware/authDriver'); // Sürücü auth
const { createRide, acceptRide, notifyAtPickup, startRide, completeRide, rateUser } = require('../controllers/rideController');

// RIDE CREATE (stub - sonra birlikte tamamlayacağız)
// RIDE CREATE
router.post('/', authMiddleware, createRide);

// RIDE ACCEPT (Sürücü)
router.patch('/:id/accept', authDriver, acceptRide);

// [YENİ] STATUS UPDATES
router.post('/:id/notify-arrival', authDriver, notifyAtPickup);
router.post('/:id/start', authDriver, startRide);
router.post('/:id/complete', authDriver, completeRide);

// [YENİ] RATING (Passenger rates Driver)
const { rateRide, cancelRideByUser, cancelRideByDriver } = require('../controllers/rideController');
router.post('/:id/rate', authMiddleware, rateRide);
router.post('/:id/cancel-by-user', authMiddleware, cancelRideByUser); // Yolcu iptal
router.post('/:id/cancel-by-driver', authDriver, cancelRideByDriver); // Sürücü iptal

// [YENİ] RATING (Driver rates Passenger)
router.post('/:id/rate-passenger', authDriver, rateUser);


module.exports = router;
