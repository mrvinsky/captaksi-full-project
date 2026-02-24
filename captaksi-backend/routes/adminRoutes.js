const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

const authAdmin = require('../middleware/authAdmin');

// Giriş (Public)
router.post('/login', adminController.loginAdmin);

// Dashboard (Protected)
router.get('/stats', authAdmin, adminController.getStats);
router.get('/stats/charts', authAdmin, adminController.getChartStats);

// Sürücüler (Protected)
router.get('/drivers', authAdmin, adminController.getAllDrivers);
router.get('/drivers/pending', authAdmin, adminController.getPendingDrivers);
router.get('/drivers/:id', authAdmin, adminController.getDriverDetails); // Detay
router.patch('/drivers/:id/status', authAdmin, adminController.updateDriverStatus); // Onay/Ret
router.delete('/drivers/:id', authAdmin, adminController.deleteDriver);

// Kullanıcılar (Protected)
router.get('/users', authAdmin, adminController.getAllUsers);
router.get('/users/:id/details', authAdmin, adminController.getUserDetails);
router.delete('/users/:id', authAdmin, adminController.deleteUser);

// Yolculuklar (Protected)
router.get('/rides', authAdmin, adminController.getAllRides);

// Ayarlar (Protected)
router.get('/settings', authAdmin, adminController.getSettings);
router.put('/settings/vehicle-types/:id', authAdmin, adminController.updateVehicleType);

// Raporlar ve Finans (Protected)
router.get('/reports', authAdmin, adminController.getReports);

module.exports = router;
