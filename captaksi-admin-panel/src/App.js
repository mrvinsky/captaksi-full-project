import React, { useState, useEffect, useCallback } from 'react';
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
    PieChart, Pie, Cell
} from 'recharts';
import './App.css';

const API_URL = `http://${window.location.hostname}:3000/api/admin`;
const COLORS = ['#F7C948', '#333'];

function App() {
    const [token, setToken] = useState(localStorage.getItem('admin_token'));

    useEffect(() => {
        if (token) {
            localStorage.setItem('admin_token', token);
        } else {
            localStorage.removeItem('admin_token');
        }
    }, [token]);

    if (!token) {
        return <Login onLoginSuccess={setToken} />;
    }

    return <Dashboard token={token} onLogout={() => setToken(null)} />;
}

function Login({ onLoginSuccess }) {
    const [email, setEmail] = useState('admin@captaksi.com');
    const [password, setPassword] = useState('123456');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const response = await fetch(`${API_URL}/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, sifre: password }),
            });
            const data = await response.json();
            if (response.ok) {
                onLoginSuccess(data.token);
            } else {
                setError(data.message || 'Giriş başarısız.');
            }
        } catch (err) {
            setError('Sunucuya bağlanılamadı.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-container">
            <div className="login-box">
                <div className="icon">🚖</div>
                <h2>Captaksi Takip Merkezi</h2>
                <form onSubmit={handleLogin}>
                    <div className="form-group">
                        <input
                            type="email"
                            placeholder="Email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>
                    <div className="form-group">
                        <input
                            type="password"
                            placeholder="Şifre"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>
                    {error && <p className="error-message">{error}</p>}
                    <button type="submit" disabled={loading}>
                        {loading ? 'Giriş yapılıyor...' : 'Giriş Yap'}
                    </button>
                </form>
            </div>
        </div>
    );
}

function Dashboard({ token, onLogout }) {
    const [activePage, setActivePage] = useState('dashboard');
    const [isMobileMenuOpen, setMobileMenuOpen] = useState(false);

    const navigateTo = (page) => {
        setActivePage(page);
        setMobileMenuOpen(false);
    };

    return (
        <div className="dashboard-layout">
            <aside className={`sidebar ${isMobileMenuOpen ? 'open' : ''}`}>
                <h1>Captaksi</h1>
                <nav>
                    <ul>
                        <li className={activePage === 'dashboard' ? 'active' : ''} onClick={() => navigateTo('dashboard')}>
                            📊 Dashboard
                        </li>
                        <li className={activePage === 'pendingDrivers' ? 'active' : ''} onClick={() => navigateTo('pendingDrivers')}>
                            ⏳ Bekleyenler
                        </li>
                        <li className={activePage === 'drivers' ? 'active' : ''} onClick={() => navigateTo('drivers')}>
                            🚕 Sürücüler
                        </li>
                        <li className={activePage === 'users' ? 'active' : ''} onClick={() => navigateTo('users')}>
                            👥 Kullanıcılar
                        </li>
                        <li className={activePage === 'rides' ? 'active' : ''} onClick={() => navigateTo('rides')}>
                            🛣️ Yolculuklar
                        </li>
                        <li className={activePage === 'settings' ? 'active' : ''} onClick={() => navigateTo('settings')}>
                            ⚙️ Sistem Ayarları
                        </li>
                        <li className={activePage === 'reports' ? 'active' : ''} onClick={() => navigateTo('reports')}>
                            💵 Finans & Raporlar
                        </li>
                    </ul>
                </nav>
                <button onClick={onLogout} className="logout-button">🚪 Çıkış Yap</button>
            </aside>

            <div className={`sidebar-overlay ${isMobileMenuOpen ? 'open' : ''}`} onClick={() => setMobileMenuOpen(false)}></div>

            <main className="main-content">
                <div className="content-header">
                    <div className="hamburger-menu" onClick={() => setMobileMenuOpen(!isMobileMenuOpen)}>
                        &#9776;
                    </div>
                    <h2>
                        {activePage === 'dashboard' && `Genel Bakış`}
                        {activePage === 'pendingDrivers' && `Onay Bekleyen Başvurular`}
                        {activePage === 'drivers' && `Tüm Sürücüler`}
                        {activePage === 'users' && `Tüm Kullanıcılar`}
                        {activePage === 'rides' && `Tüm Yolculuklar`}
                        {activePage === 'settings' && `Sistem Ayarları`}
                        {activePage === 'reports' && `Finans & Raporlar`}
                    </h2>
                </div>

                {activePage === 'dashboard' && <DashboardHome token={token} />}
                {activePage === 'pendingDrivers' && <PendingDriversPage token={token} />}
                {activePage === 'drivers' && <DriversPage token={token} />}
                {activePage === 'users' && <UsersPage token={token} />}
                {activePage === 'rides' && <RidesPage token={token} />}
                {activePage === 'settings' && <SettingsPage token={token} />}
                {activePage === 'reports' && <ReportsPage token={token} />}
            </main>
        </div>
    );
}

function DashboardHome({ token }) {
    const [stats, setStats] = useState(null);
    const [chartData, setChartData] = useState(null);

    useEffect(() => {
        const fetchData = async () => {
            try {
                // Temel istatistikler
                const statsRes = await fetch(`${API_URL}/stats`, { headers: { 'x-auth-token': token } });
                if (statsRes.ok) setStats(await statsRes.json());

                // Grafik verileri
                const chartRes = await fetch(`${API_URL}/stats/charts`, { headers: { 'x-auth-token': token } });
                if (chartRes.ok) setChartData(await chartRes.json());

            } catch (err) { console.error(err); }
        };
        fetchData();
    }, [token]);

    return (
        <div>
            <div className="stats-grid">
                <StatCard title="Toplam Kullanıcı" value={stats?.totalUsers || '...'} />
                <StatCard title="Toplam Sürücü" value={stats?.totalDrivers || '...'} />
                <StatCard title="Toplam Yolculuk" value={stats?.totalRides || '...'} />
                <StatCard title="Toplam Ciro" value={`₺${stats?.totalRevenue || '...'}`} />
            </div>

            {chartData && (
                <div className="charts-container" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem' }}>
                    <div className="chart-box" style={{ background: '#1e1e1e', padding: '20px', borderRadius: '12px' }}>
                        <h3 style={{ color: '#aaa', marginBottom: '20px' }}>Aylık Gelir (Son 6 Ay)</h3>
                        <ResponsiveContainer width="100%" height={300}>
                            <BarChart data={chartData.monthlyRevenue}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                                <XAxis dataKey="name" stroke="#888" />
                                <YAxis stroke="#888" />
                                <Tooltip contentStyle={{ backgroundColor: '#333', borderColor: '#444' }} />
                                <Bar dataKey="uv" fill="#F7C948" name="Gelir (TL)" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>

                    <div className="chart-box" style={{ background: '#1e1e1e', padding: '20px', borderRadius: '12px' }}>
                        <h3 style={{ color: '#aaa', marginBottom: '20px' }}>Kullanıcı Dağılımı</h3>
                        <ResponsiveContainer width="100%" height={300}>
                            <PieChart>
                                <Pie
                                    data={chartData.userDistribution}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={80}
                                    fill="#8884d8"
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {chartData.userDistribution.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip contentStyle={{ backgroundColor: '#333', borderColor: '#444' }} />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            )}
        </div>
    );
}

function PendingDriversPage({ token }) {
    const [drivers, setDrivers] = useState([]);
    const [selectedDriverId, setSelectedDriverId] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchPending = useCallback(async () => {
        try {
            const response = await fetch(`${API_URL}/drivers/pending`, { headers: { 'x-auth-token': token } });
            if (response.ok) setDrivers(await response.json());
        } catch (err) { console.error(err); }
    }, [token]);

    useEffect(() => { fetchPending(); }, [fetchPending]);

    const updateStatus = async (id, status) => {
        if (!window.confirm(`İşlemi onaylıyor musunuz?`)) return;
        try {
            const response = await fetch(`${API_URL}/drivers/${id}/status`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json', 'x-auth-token': token },
                body: JSON.stringify({ status })
            });
            if (response.ok) {
                alert('İşlem başarılı');
                fetchPending();
            }
        } catch (err) {
            alert('Hata oluştu');
        }
    };

    const filteredDrivers = drivers.filter(d =>
        (d.ad + ' ' + d.soyad).toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <>
            {selectedDriverId && <DriverDetailModal driverId={selectedDriverId} token={token} onClose={() => setSelectedDriverId(null)} />}
            <div className="table-container">
                <div className="table-header-actiupns" style={{ marginBottom: '1rem' }}>
                    <input
                        type="text"
                        placeholder="İsim veya E-posta ara..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="search-input"
                    />
                </div>
                {filteredDrivers.length > 0 ? (
                    <table className="drivers-table">
                        <thead>
                            <tr>
                                <th>Ad Soyad</th>
                                <th>Email</th>
                                <th>Tarih</th>
                                <th>İşlemler</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredDrivers.map(driver => (
                                <tr key={driver.id}>
                                    <td>{driver.ad} {driver.soyad}</td>
                                    <td>{driver.email}</td>
                                    <td>{driver.kayit_tarihi ? new Date(driver.kayit_tarihi).toLocaleDateString() : '-'}</td>
                                    <td className="actions">
                                        <button className="details" onClick={() => setSelectedDriverId(driver.id)}>İncele</button>
                                        <button className="approve" onClick={() => updateStatus(driver.id, 'onaylandi')}>Onayla</button>
                                        <button className="reject" onClick={() => updateStatus(driver.id, 'reddedildi')}>Reddet</button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : <p style={{ color: '#999' }}>Onay bekleyen sürücü yok.</p>}
            </div>
        </>
    );
}

function DriversPage({ token }) {
    const [drivers, setDrivers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedDriverId, setSelectedDriverId] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchDrivers = useCallback(async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/drivers`, { headers: { 'x-auth-token': token } });
            if (!response.ok) throw new Error('Veri alınamadı');

            const data = await response.json();
            // Verinin array olduğundan emin olun
            if (Array.isArray(data)) {
                setDrivers(data);
                setError(null);
            } else {
                throw new Error('Veri formatı hatalı');
            }
        } catch (err) {
            console.error(err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    }, [token]);

    useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

    const deleteDriver = async (id) => {
        if (!window.confirm('Sürücüyü silmek istediğinize emin misiniz?')) return;
        try {
            const res = await fetch(`${API_URL}/drivers/${id}`, {
                method: 'DELETE',
                headers: { 'x-auth-token': token }
            });
            if (res.ok) fetchDrivers();
        } catch (err) { alert('Hata'); }
    }

    if (loading) return <p>Yükleniyor...</p>;
    if (error) return <p style={{ color: 'red' }}>Hata: {error}</p>;

    const filteredDrivers = drivers.filter(d =>
        (d.ad + ' ' + d.soyad).toLowerCase().includes(searchTerm.toLowerCase()) ||
        (d.telefon_numarasi && d.telefon_numarasi.includes(searchTerm))
    );

    return (
        <>
            {selectedDriverId && <DriverDetailModal driverId={selectedDriverId} token={token} onClose={() => setSelectedDriverId(null)} />}
            <div className="table-container">
                <div className="table-header-actiupns" style={{ marginBottom: '1rem' }}>
                    <input
                        type="text"
                        placeholder="İsim veya Telefon ara..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="search-input"
                    />
                </div>
                <table className="drivers-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Ad Soyad</th>
                            <th>Telefon</th>
                            <th>Durum</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredDrivers.map(d => (
                            <tr key={d.id}>
                                <td>{d.id}</td>
                                <td>{d.ad} {d.soyad}</td>
                                <td>{d.telefon_numarasi}</td>
                                <td>
                                    <span className={`status-badge status-${d.hesap_onay_durumu || 'bilinmiyor'}`}>
                                        {d.hesap_onay_durumu || 'Bilinmiyor'}
                                    </span>
                                </td>
                                <td className="actions">
                                    <button className="details-btn" onClick={() => setSelectedDriverId(d.id)}>
                                        <span className="icon">🚕</span> Detay
                                    </button>
                                    <button className="delete-btn" onClick={() => deleteDriver(d.id)}>
                                        <span className="icon">🗑️</span> Sil
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </>
    );
}

function UsersPage({ token }) {
    const [users, setUsers] = useState([]);
    const [selectedUserId, setSelectedUserId] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchUsers = useCallback(async () => {
        try {
            const response = await fetch(`${API_URL}/users`, { headers: { 'x-auth-token': token } });
            if (response.ok) setUsers(await response.json());
        } catch (err) { console.error(err); }
    }, [token]);

    useEffect(() => { fetchUsers(); }, [fetchUsers]);

    const deleteUser = async (id) => {
        if (!window.confirm('Kullanıcıyı silmek istediğinize emin misiniz?')) return;
        try {
            const res = await fetch(`${API_URL}/users/${id}`, {
                method: 'DELETE',
                headers: { 'x-auth-token': token }
            });
            if (res.ok) fetchUsers();
        } catch (err) { alert('Hata'); }
    }

    const filteredUsers = users.filter(u =>
        (u.ad + ' ' + u.soyad).toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (u.telefon_numarasi && u.telefon_numarasi.includes(searchTerm))
    );

    return (
        <>
            {selectedUserId && <UserDetailModal userId={selectedUserId} token={token} onClose={() => setSelectedUserId(null)} />}
            <div className="table-container">
                <div className="table-header-actiupns" style={{ marginBottom: '1rem' }}>
                    <input
                        type="text"
                        placeholder="İsim, E-posta veya Telefon ara..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="search-input"
                    />
                </div>
                <table className="drivers-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Ad Soyad</th>
                            <th>Email</th>
                            <th>Telefon</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map(u => (
                            <tr key={u.id}>
                                <td>{u.id}</td>
                                <td>{u.ad} {u.soyad}</td>
                                <td>{u.email}</td>
                                <td>{u.telefon_numarasi}</td>
                                <td className="actions">
                                    <button className="details-btn" onClick={() => setSelectedUserId(u.id)}>
                                        <span className="icon">👤</span> Detay
                                    </button>
                                    <button className="delete-btn" onClick={() => deleteUser(u.id)}>
                                        <span className="icon">🗑️</span> Sil
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </>
    );
}

function DriverDetailModal({ driverId, token, onClose }) {
    const [driver, setDriver] = useState(null);

    useEffect(() => {
        fetch(`${API_URL}/drivers/${driverId}`, { headers: { 'x-auth-token': token } })
            .then(res => res.json())
            .then(setDriver)
            .catch(console.error);
    }, [driverId, token]);

    if (!driver) return null;

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
                <div className="modal-header">
                    <h3>Sürücü Detayı: {driver.ad} {driver.soyad}</h3>
                    <button className="close-button" onClick={onClose}>&times;</button>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
                    <div>
                        <h4>Kimlik Bilgileri</h4>
                        <p><strong>Email:</strong> {driver.email}</p>
                        <p><strong>Telefon:</strong> {driver.telefon_numarasi}</p>
                        <p><strong>Durum:</strong> {driver.hesap_onay_durumu}</p>
                    </div>
                    <div>
                        <h4>Belgeler</h4>
                        {driver.documents && driver.documents.length > 0 ? (
                            driver.documents.map(doc => (
                                <div key={doc.id} style={{ marginBottom: '10px', background: '#333', padding: '10px', borderRadius: '5px' }}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <strong>{doc.belge_tipi}</strong>
                                        <a
                                            href={`http://localhost:3000${doc.dosya_url}`}
                                            target="_blank"
                                            rel="noreferrer"
                                            style={{
                                                background: '#F7C948',
                                                color: '#000',
                                                padding: '5px 10px',
                                                borderRadius: '5px',
                                                textDecoration: 'none',
                                                fontWeight: 'bold',
                                                fontSize: '0.9rem'
                                            }}
                                        >
                                            Görüntüle
                                        </a>
                                    </div>
                                    <div style={{ marginTop: '5px', fontSize: '0.8rem', color: '#ccc' }}>
                                        <span className={`status-badge status-${doc.onay_durumu || 'bekliyor'}`}>{doc.onay_durumu || 'Bekliyor'}</span>
                                    </div>
                                </div>
                            ))
                        ) : <p>Yüklenmiş belge yok.</p>}
                    </div>
                </div>
            </div>
        </div>
    );
}

function UserDetailModal({ userId, token, onClose }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setLoading(true);
        fetch(`${API_URL}/users/${userId}/details`, { headers: { 'x-auth-token': token } })
            .then(res => res.json())
            .then(data => {
                setUser(data);
                setLoading(false);
            })
            .catch(err => {
                console.error(err);
                setLoading(false);
            });
    }, [userId, token]);

    if (!user && !loading) return null;

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content user-modal" onClick={e => e.stopPropagation()}>
                {loading ? (
                    <div className="loading-spinner-container">
                        <div className="spinner"></div>
                        <p>Yükleniyor...</p>
                    </div>
                ) : (
                    <>
                        <div className="modal-header">
                            <div className="header-user-info">
                                <div className="user-avatar-large">
                                    {user.ad ? user.ad[0] : 'U'}
                                </div>
                                <div>
                                    <h3>{user.ad} {user.soyad}</h3>
                                    <span className="user-id-badge">Yolcu ID: #{user.id}</span>
                                </div>
                            </div>
                            <button className="close-button" onClick={onClose}>&times;</button>
                        </div>
                        <div className="user-details-body">
                            <div className="info-section">
                                <h4>Hesap Bilgileri</h4>
                                <div className="info-row">
                                    <span className="label">E-posta:</span>
                                    <span className="value">{user.email}</span>
                                </div>
                                <div className="info-row">
                                    <span className="label">Telefon:</span>
                                    <span className="value">{user.telefon_numarasi || 'Belirtilmemiş'}</span>
                                </div>
                                <div className="info-row">
                                    <span className="label">Kayıt Tarihi:</span>
                                    <span className="value">{new Date(user.kayit_tarihi).toLocaleDateString('tr-TR')}</span>
                                </div>
                            </div>

                            <div className="stats-section">
                                <h4>Kullanım İstatistikleri</h4>
                                <div className="mini-stats-grid">
                                    <div className="mini-stat">
                                        <span className="stat-icon">🚗</span>
                                        <span className="stat-label">Yolculuklar</span>
                                        <span className="stat-value">{user.stats?.total_rides || 0}</span>
                                    </div>
                                    <div className="mini-stat">
                                        <span className="stat-icon">💰</span>
                                        <span className="stat-label">Toplam Harcama</span>
                                        <span className="stat-value">₺{user.stats?.total_spent || '0.00'}</span>
                                    </div>
                                    <div className="mini-stat">
                                        <span className="stat-icon">📏</span>
                                        <span className="stat-label">Toplam KM</span>
                                        <span className="stat-value">{user.stats?.total_distance_km || 0} km</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
}

function StatCard({ title, value }) {
    return (
        <div className="stat-card">
            <h3>{title}</h3>
            <p>{value}</p>
        </div>
    );
}

function RidesPage({ token }) {
    const [rides, setRides] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchRides = useCallback(async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/rides`, { headers: { 'x-auth-token': token } });
            if (!response.ok) throw new Error('Veri alınamadı');

            const data = await response.json();
            if (Array.isArray(data)) {
                setRides(data);
                setError(null);
            } else {
                throw new Error('Veri formatı hatalı');
            }
        } catch (err) {
            console.error(err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    }, [token]);

    useEffect(() => { fetchRides(); }, [fetchRides]);

    if (loading) return <p>Yükleniyor...</p>;
    if (error) return <p style={{ color: 'red' }}>Hata: {error}</p>;

    const filteredRides = rides.filter(r =>
        (r.user_ad + ' ' + r.user_soyad).toLowerCase().includes(searchTerm.toLowerCase()) ||
        (r.driver_ad + ' ' + r.driver_soyad).toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.durum.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="table-container">
            <div className="table-header-actiupns" style={{ marginBottom: '1rem' }}>
                <input
                    type="text"
                    placeholder="Yolcu, Sürücü veya Durum ara..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="search-input"
                />
            </div>
            <div style={{ overflowX: 'auto' }}>
                <table className="drivers-table">
                    <thead>
                        <tr>
                            <th>Yolcu</th>
                            <th>Sürücü</th>
                            <th>Başlangıç</th>
                            <th>Bitiş</th>
                            <th>Tutar</th>
                            <th>Tarih</th>
                            <th>Durum</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredRides.map(r => (
                            <tr key={r.id}>
                                <td>{r.user_ad} {r.user_soyad}</td>
                                <td>{r.driver_ad ? `${r.driver_ad} ${r.driver_soyad}` : '-'}</td>
                                <td>{r.baslangic_adres_metni || 'Belirtilmedi'}</td>
                                <td>{r.bitis_adres_metni || 'Belirtilmedi'}</td>
                                <td>{r.gerceklesen_ucret ? `₺${r.gerceklesen_ucret}` : '-'}</td>
                                <td>{new Date(r.talep_tarihi).toLocaleString()}</td>
                                <td>
                                    <span className={`status-badge status-${r.durum || 'beklemede'}`}>
                                        {r.durum || 'beklemede'}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

function SettingsPage({ token }) {
    const [vehicleTypes, setVehicleTypes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchSettings = useCallback(async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/settings`, { headers: { 'x-auth-token': token } });
            if (!response.ok) throw new Error('Veri alınamadı');
            const data = await response.json();
            setVehicleTypes(data.vehicleTypes);
            setError(null);
        } catch (err) {
            console.error(err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    }, [token]);

    useEffect(() => { fetchSettings(); }, [fetchSettings]);

    const handleUpdate = async (id, currentCostBase, currentCostKm) => {
        const newCostBase = prompt('Yeni Taban Ücreti giriniz:', currentCostBase);
        const newCostKm = prompt('Yeni KM Ücreti giriniz:', currentCostKm);

        if (newCostBase && newCostKm) {
            try {
                const response = await fetch(`${API_URL}/settings/vehicle-types/${id}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json', 'x-auth-token': token },
                    body: JSON.stringify({ taban_ucret: parseFloat(newCostBase), km_ucreti: parseFloat(newCostKm) })
                });

                if (response.ok) {
                    alert('Araç ücreti başarıyla güncellendi.');
                    fetchSettings();
                } else {
                    alert('Güncelleme başarısız oldu.');
                }
            } catch (err) {
                alert('Hata oluştu.');
            }
        }
    };

    if (loading) return <p>Yükleniyor...</p>;
    if (error) return <p style={{ color: 'red' }}>Hata: {error}</p>;

    return (
        <div className="table-container">
            <h3>Araç Tipi Ücretlendirmesi</h3>
            <p style={{ color: '#aaa', marginBottom: '20px' }}>Taksi çağrılarında yolculara yansıtılan fiyatlar bu tabloya göre hesaplanır.</p>
            <div style={{ overflowX: 'auto' }}>
                <table className="drivers-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Tip Adı</th>
                            <th>Açıklama</th>
                            <th>Taban Ücret (TL)</th>
                            <th>KM Ücreti (TL)</th>
                            <th>İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        {vehicleTypes.map(vt => (
                            <tr key={vt.id}>
                                <td>{vt.id}</td>
                                <td>{vt.tip_adi}</td>
                                <td>{vt.aciklama || '-'}</td>
                                <td style={{ fontWeight: 'bold', color: '#F7C948' }}>₺{parseFloat(vt.taban_ucret).toFixed(2)}</td>
                                <td style={{ fontWeight: 'bold', color: '#4CAF50' }}>₺{parseFloat(vt.km_ucreti).toFixed(2)}</td>
                                <td className="actions">
                                    <button className="approve" onClick={() => handleUpdate(vt.id, vt.taban_ucret, vt.km_ucreti)}>
                                        Düzenle
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

function ReportsPage({ token }) {
    const [reports, setReports] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchReports = useCallback(async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/reports`, { headers: { 'x-auth-token': token } });
            if (!response.ok) throw new Error('Veri alınamadı');
            const data = await response.json();
            setReports(data);
            setError(null);
        } catch (err) {
            console.error(err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    }, [token]);

    useEffect(() => { fetchReports(); }, [fetchReports]);

    if (loading) return <p>Yükleniyor...</p>;
    if (error) return <p style={{ color: 'red' }}>Hata: {error}</p>;

    return (
        <div>
            <div className="stats-grid" style={{ marginBottom: '2rem' }}>
                <StatCard title="Sistem Toplam Ciro" value={`₺${reports?.totalRevenue || 0}`} />
            </div>

            <div className="table-container">
                <h3>Sürücü Hakediş Raporu</h3>
                <p style={{ color: '#aaa', marginBottom: '20px' }}>Sürücülerin tamamladıkları yolculuklardan elde ettikleri toplam gelir ve sürüş sayıları listelenmektedir.</p>
                <div style={{ overflowX: 'auto' }}>
                    <table className="drivers-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Sürücü Adı</th>
                                <th>Toplam Sürüş</th>
                                <th>Sürücü Kazancı (TL)</th>
                            </tr>
                        </thead>
                        <tbody>
                            {reports?.driverEarnings?.map(d => (
                                <tr key={d.id}>
                                    <td>{d.id}</td>
                                    <td>{d.ad} {d.soyad}</td>
                                    <td>{d.total_rides}</td>
                                    <td style={{ fontWeight: 'bold', color: '#4CAF50' }}>₺{parseFloat(d.total_earned).toFixed(2)}</td>
                                </tr>
                            ))}
                            {(!reports?.driverEarnings || reports.driverEarnings.length === 0) && (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', color: '#888' }}>Kayıtlı sürüş verisi bulunamadı.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

export default App;
