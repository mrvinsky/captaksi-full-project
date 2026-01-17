const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// Basit bir middleware ile admin yetkisi kontrolü eklenebilir
// Şimdilik direkt geçiş veriyoruz veya controller içinde basit kontrol yapıyoruz.

// Giriş
router.post('/login', adminController.loginAdmin);

// Dashboard
router.get('/stats', adminController.getStats);
router.get('/stats/charts', adminController.getChartStats);

// Sürücüler
router.get('/drivers', adminController.getAllDrivers);
router.get('/drivers/pending', adminController.getPendingDrivers);
router.get('/drivers/:id', adminController.getDriverDetails); // Detay
router.patch('/drivers/:id/status', adminController.updateDriverStatus); // Onay/Ret
router.delete('/drivers/:id', adminController.deleteDriver);

// Kullanıcılar
router.get('/users', adminController.getAllUsers);
router.get('/users/:id/details', adminController.getUserDetails);
router.delete('/users/:id', adminController.deleteUser);

module.exports = router;
