const jwt = require('jsonwebtoken');
require('dotenv').config();

module.exports = function (req, res, next) {
  if (process.env.NODE_ENV === 'development') {
    console.log('--- YENİ BİR İSTEK GELDİ ---');
  }

  const token = req.header('x-auth-token');

  if (!token) {
    return res.status(401).json({ message: 'Yetki reddedildi, token bulunamadı' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.driver) {
      return res.status(401).json({ message: 'Token bir sürücüye ait değil' });
    }

    req.driver = decoded.driver;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token geçerli değil' });
  }
};