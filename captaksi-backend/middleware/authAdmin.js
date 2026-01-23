const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
    // Token'ı header'dan al
    const token = req.header('x-auth-token');

    // Token yoksa reddet
    if (!token) {
        return res.status(401).json({ message: 'Token yok, yetkilendirme reddedildi.' });
    }

    try {
        // Token'ı doğrula
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Admin payload kontrolü
        if (!decoded.admin) {
            return res.status(403).json({ message: 'Bu işlem için admin yetkisi gerekiyor.' });
        }

        req.admin = decoded.admin;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Token geçersiz.' });
    }
};
