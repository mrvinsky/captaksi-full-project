const jwt = require('jsonwebtoken');
require('dotenv').config();

module.exports = function (req, res, next) {
  if (process.env.NODE_ENV === 'development') {
    console.log("\n--- KORUMALI ROTA İSTEĞİ GELDİ (auth.js) ---");
  }

  const token = req.header('x-auth-token');
  // console.log("Gelen Token:", token ? "VAR" : "YOK");

  if (!token) {
    // console.log("HATA: Token bulunamadı.");
    return res.status(401).json({ message: 'Yetki reddedildi, token bulunamadı' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log("Token başarıyla çözüldü. Payload:", decoded);

    req.user = decoded.user;
    next();
  } catch (err) {
    console.log("HATA: Token geçerli değil veya süresi dolmuş.");
    res.status(401).json({ message: 'Token geçerli değil' });
  }
};