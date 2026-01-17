const db = require('../db');
const jwt = require('jsonwebtoken');

// =========================
// ADMIN LOGIN
// =========================
exports.loginAdmin = async (req, res) => {
    try {
        const { email, sifre } = req.body;

        // Basit hardcoded admin kontrolü (Prodüksiyonda veritabanından çekilmelidir)
        if (email === 'admin@captaksi.com' && sifre === '123456') {
            const payload = { admin: { id: 'admin-1' } };

            jwt.sign(
                payload,
                process.env.JWT_SECRET,
                { expiresIn: '12h' }, // Admin oturumu daha uzun kalsın
                (err, token) => {
                    if (err) throw err;
                    res.json({ token });
                }
            );
        } else {
            return res.status(400).json({ message: 'Hatalı admin bilgileri' });
        }
    } catch (err) {
        console.error("Admin girişi hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// DASHBOARD ISTATISTIKLERI
// =========================
exports.getStats = async (req, res) => {
    try {
        const totalUsers = await db.query('SELECT COUNT(*) FROM users');
        const totalDrivers = await db.query('SELECT COUNT(*) FROM drivers');
        // Hesaplanmış gelir ve yolculuk sayıları
        const rideStats = await db.query(`
            SELECT 
                COUNT(*) as total_rides,
                COALESCE(SUM(gerceklesen_ucret), 0) as total_revenue 
            FROM rides 
            WHERE durum = 'tamamlandi'
        `);

        res.json({
            totalUsers: totalUsers.rows[0].count,
            totalDrivers: totalDrivers.rows[0].count,
            totalRides: rideStats.rows[0].total_rides,
            totalRevenue: parseFloat(rideStats.rows[0].total_revenue).toFixed(2)
        });
    } catch (err) {
        console.error("İstatistik hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// GRAFIK VERILERI
// =========================
exports.getChartStats = async (req, res) => {
    try {
        // 1. Kullanıcı Dağılımı
        const userCount = await db.query('SELECT COUNT(*) FROM users');
        const driverCount = await db.query('SELECT COUNT(*) FROM drivers');

        // 2. Aylık Gelir (Son 6 ay - Mock/Basit sorgu)
        // Gerçek dünyada tarih fonksiyonları (to_char vs) farklılık gösterebilir.
        // Şimdilik demo için gerçek veriden ziyade statik yapı ile hibrit bir çözüm sunalım
        // veya son eklenen yolculuklara göre dinamik üretelim.

        // Postgres için basit bir aylık gruplama örneği:
        const revenueResult = await db.query(`
            SELECT 
                TO_CHAR(talep_tarihi, 'Mon') as name,
                SUM(gerceklesen_ucret) as uv
            FROM rides 
            WHERE durum = 'tamamlandi' AND talep_tarihi > NOW() - INTERVAL '6 months'
            GROUP BY TO_CHAR(talep_tarihi, 'Mon'), DATE_TRUNC('month', talep_tarihi)
            ORDER BY DATE_TRUNC('month', talep_tarihi)
        `);

        // Eğer hiç veri yoksa boş grafik görünmesin diye mock veri ekleyelim
        let monthlyRevenue = revenueResult.rows;
        if (monthlyRevenue.length === 0) {
            monthlyRevenue = [
                { name: 'Oca', uv: 0 },
                { name: 'Şub', uv: 0 },
                { name: 'Mar', uv: 0 },
                { name: 'Nis', uv: 0 },
                { name: 'May', uv: 0 },
                { name: 'Haz', uv: 0 }
            ];
        }

        res.json({
            userDistribution: [
                { name: 'Yolcular', value: parseInt(userCount.rows[0].count) },
                { name: 'Sürücüler', value: parseInt(driverCount.rows[0].count) }
            ],
            monthlyRevenue: monthlyRevenue
        });

    } catch (err) {
        console.error("Grafik veri hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// SURUCU YONETIMI
// =========================

// Onay bekleyen sürücüler
exports.getPendingDrivers = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT id, ad, soyad, email, telefon_numarasi, hesap_onay_durumu, kayit_tarihi
            FROM drivers 
            WHERE hesap_onay_durumu = 'bekliyor'
            ORDER BY kayit_tarihi ASC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error("Bekleyen sürücüler hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// Tüm sürücüler
exports.getAllDrivers = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT id, ad, soyad, email, telefon_numarasi, hesap_onay_durumu
            FROM drivers 
            ORDER BY id DESC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error("Sürücü listesi hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// Tekil sürücü detayı (Belgeler dahil)
exports.getDriverDetails = async (req, res) => {
    try {
        const { id } = req.params;

        const driver = await db.query('SELECT * FROM drivers WHERE id = $1', [id]);
        if (driver.rows.length === 0) return res.status(404).json({ message: 'Sürücü bulunamadı' });

        // Sürücü belgelerini ve varsa araç bilgisini de çekebiliriz
        // Şimdilik sadece sürücü bilgisi dönüyoruz, ileride JOIN eklenebilir.
        // Mock belge verisi ekleyelim, gerçek tabloda varsa oradan çekilmeli.

        const driverData = driver.rows[0];

        // Mock belgeler (Gerçek tablolarınız varsa burayı güncelleyin)
        driverData.documents = [
            { id: 1, belge_tipi: 'EHLİYET', dosya_url: '/uploads/mock_ehliyet.jpg' },
            { id: 2, belge_tipi: 'RUHSAT', dosya_url: '/uploads/mock_ruhsat.jpg' }
        ];

        res.json(driverData);
    } catch (err) {
        console.error("Sürücü detay hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// Sürücü Durum Güncelleme
exports.updateDriverStatus = async (req, res) => {
    console.log('--- Sürücü Durum Güncelleme İsteği ---');
    console.log('Params:', req.params);
    console.log('Body:', req.body);
    try {
        const { id } = req.params;
        const { status } = req.body; // 'onaylandi' veya 'reddedildi'

        const result = await db.query(
            'UPDATE drivers SET hesap_onay_durumu = $1 WHERE id = $2 RETURNING *',
            [status, id]
        );

        if (result.rowCount === 0) {
            console.log('Sürücü bulunamadı veya güncellenemedi.');
            return res.status(404).json({ message: 'Sürücü bulunamadı.' });
        }

        console.log('Güncelleme başarılı:', result.rows[0]);
        res.json({ message: `Sürücü durumu '${status}' olarak güncellendi.` });
    } catch (err) {
        console.error("Sürücü güncelleme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// Sürücü Silme
exports.deleteDriver = async (req, res) => {
    try {
        const { id } = req.params;
        await db.query('DELETE FROM drivers WHERE id = $1', [id]);
        res.json({ message: 'Sürücü başarıyla silindi.' });
    } catch (err) {
        console.error("Sürücü silme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// KULLANICI YONETIMI
// =========================

exports.getAllUsers = async (req, res) => {
    try {
        const result = await db.query('SELECT id, ad, soyad, email, telefon_numarasi FROM users ORDER BY id DESC');
        res.json(result.rows);
    } catch (err) {
        console.error("Kullanıcı listesi hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

exports.getUserDetails = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);

        if (user.rows.length === 0) return res.status(404).json({ message: 'Kullanıcı bulunamadı' });

        // İstatistikler
        const stats = await db.query(`
            SELECT COUNT(*) as totalRides, COALESCE(SUM(gerceklesen_ucret),0) as totalSpent 
            FROM rides WHERE kullanici_id = $1 AND durum = 'tamamlandi'
        `, [id]);

        const userData = user.rows[0];
        userData.stats = {
            totalRides: stats.rows[0].totalrides,
            totalDistanceKm: 0 // Veritabanında mesafe takibi varsa buraya eklenmeli
        };

        res.json(userData);
    } catch (err) {
        console.error("Kullanıcı detay hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

exports.deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        await db.query('DELETE FROM users WHERE id = $1', [id]);
        res.json({ message: 'Kullanıcı başarıyla silindi.' });
    } catch (err) {
        console.error("Kullanıcı silme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};
