const db = require('./db');

async function checkData() {
    try {
        console.log('--- DB KONTROLU ---');

        const drivers = await db.query('SELECT * FROM drivers');
        console.log(`Toplam Sürücü Sayısı: ${drivers.rows.length}`);
        if (drivers.rows.length > 0) {
            console.log('Örnek Sürücüler:', drivers.rows.slice(0, 3).map(d => ({ id: d.id, ad: d.ad, durum: d.hesap_onay_durumu })));
        }

        const users = await db.query('SELECT * FROM users');
        console.log(`Toplam Kullanıcı Sayısı: ${users.rows.length}`);
        if (users.rows.length > 0) {
            console.log('Örnek Kullanıcılar:', users.rows.slice(0, 3).map(u => ({ id: u.id, email: u.email })));
        }

        process.exit(0);
    } catch (err) {
        console.error('Hata:', err);
        process.exit(1);
    }
}

checkData();
