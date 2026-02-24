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
        // is_approved = false olanları getir
        const result = await db.query(`
            SELECT id, ad, soyad, email, telefon_numarasi, hesap_onay_durumu, kayit_tarihi
            FROM drivers 
            WHERE is_approved = false OR hesap_onay_durumu = 'bekliyor'
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
        // Sürücü belgelerini çek
        const documents = await db.query('SELECT id, belge_tipi, dosya_url, yuklenme_tarihi, onay_durumu FROM documents WHERE surucu_id = $1', [id]);

        const driverData = driver.rows[0];
        driverData.documents = documents.rows;

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

        const isApproved = (status === 'onaylandi');

        // Hem string durumu hem de boolean durumu güncelleyelim.
        // Eğer hesap_onay_durumu kolonu yoksa hata verebilir, o yüzden önce is_approved güncelleyelim.
        // Ama önceki kod hesap_onay_durumu kullanıyordu, demek ki var. İkisini de güncelliyorum.

        const result = await db.query(
            `UPDATE drivers 
             SET hesap_onay_durumu = $1, is_approved = $2 
             WHERE id = $3 
             RETURNING *`,
            [status, isApproved, id]
        );

        if (result.rowCount === 0) {
            console.log('Sürücü bulunamadı veya güncellenemedi.');
            return res.status(404).json({ message: 'Sürücü bulunamadı.' });
        }

        console.log('Güncelleme başarılı:', result.rows[0]);
        res.json({ message: `Sürücü durumu '${status}' olarak güncellendi.` });
    } catch (err) {
        console.error("Sürücü güncelleme hatası:", err.message);
        // Eğer hesap_onay_durumu yok diye patlarsa fallback yapalım
        try {
            const isApproved = (req.body.status === 'onaylandi');
            await db.query('UPDATE drivers SET is_approved = $1 WHERE id = $2', [isApproved, req.params.id]);
            return res.json({ message: "Sürücü durumu güncellendi (Fallback)." });
        } catch (e) {
            console.error("Fallback update error:", e);
        }
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

        // İstatistikler (Sadece tamamlanmış yolculuklar)
        const stats = await db.query(`
            SELECT COUNT(*) as totalRides, COALESCE(SUM(gerceklesen_ucret),0) as totalSpent 
            FROM rides WHERE kullanici_id = $1 AND durum = 'tamamlandi'
        `, [id]);

        const userData = user.rows[0];
        userData.stats = {
            totalRides: stats.rows[0].totalrides,
            totalSpent: stats.rows[0].totalspent,
            totalDistanceKm: 0 // Optional for future
        };

        // Kullanıcıların belgesi (şoförler gibi) olmadığı için boş liste döndür
        userData.documents = [];

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

// =========================
// YOLCULUK YONETIMI
// =========================
exports.getAllRides = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT 
                r.id, r.durum, r.gerceklesen_ucret, r.talep_tarihi,
                r.baslangic_adres_metni, r.bitis_adres_metni,
                u.ad AS user_ad, u.soyad AS user_soyad,
                d.ad AS driver_ad, d.soyad AS driver_soyad
            FROM rides r
            LEFT JOIN users u ON r.kullanici_id = u.id
            LEFT JOIN drivers d ON r.surucu_id = d.id
            ORDER BY r.id DESC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error("Yolculuk listesi hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// SISTEM AYARLARI YONETIMI
// =========================
exports.getSettings = async (req, res) => {
    try {
        const vehicleTypes = await db.query(
            "SELECT id, tip_adi, aciklama, taban_ucret, km_ucreti FROM vehicle_types ORDER BY id ASC"
        );
        res.json({ vehicleTypes: vehicleTypes.rows });
    } catch (err) {
        console.error("Ayarlar getirme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

exports.updateVehicleType = async (req, res) => {
    try {
        const { id } = req.params;
        const { taban_ucret, km_ucreti } = req.body;

        const result = await db.query(
            "UPDATE vehicle_types SET taban_ucret = $1, km_ucreti = $2 WHERE id = $3 RETURNING *",
            [taban_ucret, km_ucreti, id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Araç tipi bulunamadı' });
        }

        res.json({ message: 'Ayarlar güncellendi', vehicleType: result.rows[0] });
    } catch (err) {
        console.error("Ayar güncelleme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};

// =========================
// RAPORLAR VE FILANS
// =========================
exports.getReports = async (req, res) => {
    try {
        // Genel Ciro
        const totalRevenueResult = await db.query("SELECT COALESCE(SUM(gerceklesen_ucret), 0) as total_revenue FROM rides WHERE durum = 'tamamlandi'");

        // Sürücü Bazlı Kazançlar (Son 30 Gün vs yapılabilirdi ama tüm zamanları alıyoruz)
        const driverEarningsResult = await db.query(`
            SELECT 
                d.id, d.ad, d.soyad, 
                COUNT(r.id) as total_rides,
                COALESCE(SUM(r.gerceklesen_ucret), 0) as total_earned
            FROM drivers d
            LEFT JOIN rides r ON d.id = r.surucu_id AND r.durum = 'tamamlandi'
            GROUP BY d.id, d.ad, d.soyad
            ORDER BY total_earned DESC
        `);

        res.json({
            totalRevenue: parseFloat(totalRevenueResult.rows[0].total_revenue).toFixed(2),
            driverEarnings: driverEarningsResult.rows
        });

    } catch (err) {
        console.error("Rapor çekme hatası:", err.message);
        res.status(500).send("Sunucu hatası");
    }
};
