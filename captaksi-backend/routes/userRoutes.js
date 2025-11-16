// routes/userRoutes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

const authMiddleware = require('../middleware/auth');
const {
  registerUser,
  loginUser,
  getMyProfile,
  getMyRides
} = require('../controllers/userController');

// REGISTER
router.post(
  '/register',
  upload.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'criminalRecord', maxCount: 1 }
  ]),
  registerUser
);

// LOGIN
router.post('/login', loginUser);

// ME (profile + stats)
router.get('/me', authMiddleware, getMyProfile);

// MY RIDES
router.get('/me/rides', authMiddleware, getMyRides);

module.exports = router;
