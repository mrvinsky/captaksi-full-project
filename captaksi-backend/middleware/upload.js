// middleware/upload.js
const multer = require('multer');

// Bellekte tutuyoruz, dosya diske yazılmıyor.
// Zaten sen DB'ye sadece URL kaydediyorsun.
const storage = multer.memoryStorage();

const upload = multer({
  storage,
}).fields([
  { name: 'profileImage', maxCount: 1 },
  { name: 'criminalRecord', maxCount: 1 },
]);

module.exports = upload;
