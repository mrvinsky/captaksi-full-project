const express = require('express');
const router = express.Router();

const authDriver = require('../middleware/authDriver');
const { getDriverVehicle, updateDriverVehicle } = require('../controllers/vehicleController');

router.get('/me', authDriver, getDriverVehicle);
router.patch('/me', authDriver, updateDriverVehicle);

module.exports = router;
