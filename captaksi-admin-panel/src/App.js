import React, { useState, useEffect, useCallback } from 'react';
import './App.css';

// API sunucusunun adresi
const API_URL = 'http://localhost:3000/api/admin';

// Ana App Bileşeni
function App() {
  const [token, setToken] = useState(localStorage.getItem('admin_token'));

  if (!token) {
    return <Login onLoginSuccess={setToken} />;
  }

  return <Dashboard token={token} onLogout={() => setToken(null)} />;
}

// Login Ekranı Bileşeni
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
        localStorage.setItem('admin_token', data.token);
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
        <h2>Captaksi Admin Paneli</h2>
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


// Ana Panel (Dashboard) Bileşeni
function Dashboard({ token, onLogout }) {
  const [activePage, setActivePage] = useState('pendingDrivers');
  const [isMobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    onLogout();
  };

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
            <li className={activePage === 'pendingDrivers' ? 'active' : ''} onClick={() => navigateTo('pendingDrivers')}>Onay Bekleyenler</li>
            <li className={activePage === 'drivers' ? 'active' : ''} onClick={() => navigateTo('drivers')}>Sürücüler</li>
            <li className={activePage === 'users' ? 'active' : ''} onClick={() => navigateTo('users')}>Kullanıcılar</li>
            <li className={activePage === 'settings' ? 'active' : ''} onClick={() => navigateTo('settings')}>Ayarlar</li>
          </ul>
        </nav>
        <button onClick={handleLogout} className="logout-button">Çıkış Yap</button>
      </aside>

      <div className={`sidebar-overlay ${isMobileMenuOpen ? 'open' : ''}`} onClick={() => setMobileMenuOpen(false)}></div>
      
      <main className="main-content">
        <div className="content-header">
           <div className="hamburger-menu" onClick={() => setMobileMenuOpen(!isMobileMenuOpen)}>
              &#9776;
            </div>
          <h2>
            {activePage === 'pendingDrivers' && `Onay Bekleyen Sürücüler`}
            {activePage === 'drivers' && `Tüm Sürücüler`}
            {activePage === 'users' && `Tüm Kullanıcılar`}
            {activePage === 'settings' && `Ayarlar`}
          </h2>
        </div>

        {activePage === 'pendingDrivers' && <PendingDriversPage token={token} />}
        {activePage === 'drivers' && <DriversPage token={token} />}
        {activePage === 'users' && <UsersPage token={token} />}
        {activePage === 'settings' && <p>Genel ayarlar sayfası burada olacak.</p>}
      </main>
    </div>
  );
}


// Onay Bekleyen Sürücüler Sayfası Bileşeni
function PendingDriversPage({ token }) {
    const [drivers, setDrivers] = useState([]);
    const [stats, setStats] = useState(null);
    const [selectedDriverId, setSelectedDriverId] = useState(null);

    const fetchData = useCallback(() => {
        const fetchPending = async () => {
            try {
                const response = await fetch(`${API_URL}/drivers/pending`, {
                    headers: { 'x-auth-token': token },
                });
                const data = await response.json();
                if (response.ok) {
                    setDrivers(data);
                }
            } catch (err) {
                console.error('Onay bekleyen sürücüler alınamadı:', err);
            }
        };

        const fetchAllStats = async () => {
            try {
                const response = await fetch(`${API_URL}/stats`, {
                    headers: { 'x-auth-token': token },
                });
                const data = await response.json();
                if (response.ok) {
                    setStats(data);
                }
            } catch (err) {
                console.error('İstatistikler alınamadı:', err);
            }
        };

        fetchPending();
        fetchAllStats();
    }, [token]);

    useEffect(() => {
        fetchData();
    }, [fetchData]);

    const handleUpdateDriverStatus = async (driverId, status) => {
        if (!window.confirm(`Sürücü #${driverId} hesabını "${status}" olarak işaretlemek istediğinizden emin misiniz?`)) {
            return;
        }
        try {
            const response = await fetch(`${API_URL}/drivers/${driverId}/status`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'x-auth-token': token,
                },
                body: JSON.stringify({ status }),
            });
            const data = await response.json();
            if (response.ok) {
                alert(data.message);
                fetchData();
            } else {
                alert('Hata: ' + data.message);
            }
        } catch (err) {
            alert('Sunucuya bağlanılamadı.');
        }
    };

    return (
        <>
            {selectedDriverId && <DriverDetailModal driverId={selectedDriverId} token={token} onClose={() => setSelectedDriverId(null)} />}
            <div className="table-container">
                {drivers.length > 0 ? (
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
                            {drivers.map((driver) => (
                                <tr key={driver.id}>
                                    <td>{driver.id}</td>
                                    <td>{`${driver.ad || ''} ${driver.soyad || ''}`}</td>
                                    <td>{driver.email}</td>
                                    <td>{driver.telefon_numarasi}</td>
                                    <td className="actions">
                                        <button onClick={() => setSelectedDriverId(driver.id)} className="details">Detaylar</button>
                                        <button onClick={() => handleUpdateDriverStatus(driver.id, 'onaylandi')} className="approve">Onayla</button>
                                        <button onClick={() => handleUpdateDriverStatus(driver.id, 'reddedildi')} className="reject">Reddet</button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : (
                    <p>Onay bekleyen sürücü bulunmuyor.</p>
                )}
            </div>

            <div className="stats-grid">
                <StatCard title="Toplam Kullanıcı" value={stats?.totalUsers || '...'} />
                <StatCard title="Toplam Sürücü" value={stats?.totalDrivers || '...'} />
                <StatCard title="Tamamlanan Yolculuk" value={stats?.totalRides || '...'} />
                <StatCard title="Toplam Gelir" value={`₺${stats?.totalRevenue || '...'}`} />
            </div>
        </>
    );
}

// Tüm Sürücüler Sayfası Bileşeni
function DriversPage({ token }) {
    const [drivers, setDrivers] = useState([]);
    const [selectedDriverId, setSelectedDriverId] = useState(null);
    
    const fetchAllDrivers = useCallback(async () => {
        try {
            const response = await fetch(`${API_URL}/drivers`, {
                headers: { 'x-auth-token': token },
            });
            const data = await response.json();
            if (response.ok) {
                setDrivers(data);
            }
        } catch (err) {
            console.error('Tüm sürücüler alınamadı:', err);
        }
    }, [token]);

    useEffect(() => {
        fetchAllDrivers();
    }, [fetchAllDrivers]);
    
    const handleDeleteDriver = async (driverId) => {
        if (!window.confirm(`Sürücü #${driverId} hesabını kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.`)) {
            return;
        }
        try {
            const response = await fetch(`${API_URL}/drivers/${driverId}`, {
                method: 'DELETE',
                headers: { 'x-auth-token': token },
            });
            const data = await response.json();
            alert(data.message);
            if (response.ok) {
                fetchAllDrivers(); // Listeyi yenile
            }
        } catch (err) {
            alert('Sürücü silinirken bir hata oluştu.');
        }
    };
    
    return (
        <>
            {selectedDriverId && <DriverDetailModal driverId={selectedDriverId} token={token} onClose={() => setSelectedDriverId(null)} />}
            <div className="table-container">
                {drivers.length > 0 ? (
                    <table className="drivers-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Ad Soyad</th>
                                <th>Email</th>
                                <th>Telefon</th>
                                <th>Durum</th>
                                <th>İşlemler</th>
                            </tr>
                        </thead>
                        <tbody>
                            {drivers.map((driver) => (
                                <tr key={driver.id}>
                                    <td>{driver.id}</td>
                                    <td>{`${driver.ad || ''} ${driver.soyad || ''}`}</td>
                                    <td>{driver.email}</td>
                                    <td>{driver.telefon_numarasi}</td>
                                    <td><span className={`status-badge status-${driver.hesap_onay_durumu}`}>{driver.hesap_onay_durumu}</span></td>
                                    <td className="actions">
                                        <button onClick={() => setSelectedDriverId(driver.id)} className="details">Detaylar</button>
                                        <button onClick={() => handleDeleteDriver(driver.id)} className="delete">Sil</button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : (
                    <p>Sisteme kayıtlı sürücü bulunmuyor.</p>
                )}
            </div>
        </>
    );
}

// Tüm Kullanıcılar Sayfası Bileşeni
function UsersPage({ token }) {
    const [users, setUsers] = useState([]);
    const [selectedUserId, setSelectedUserId] = useState(null);

    const fetchAllUsers = useCallback(async () => {
        try {
            const response = await fetch(`${API_URL}/users`, {
                headers: { 'x-auth-token': token },
            });
            const data = await response.json();
            if (response.ok) {
                setUsers(data);
            }
        } catch (err) {
            console.error('Tüm kullanıcılar alınamadı:', err);
        }
    }, [token]);
    
    useEffect(() => {
        fetchAllUsers();
    }, [fetchAllUsers]);

    const handleDeleteUser = async (userId) => {
        if (!window.confirm(`Kullanıcı #${userId} hesabını kalıcı olarak silmek istediğinizden emin misiniz?`)) {
            return;
        }
        try {
            const response = await fetch(`${API_URL}/users/${userId}`, {
                method: 'DELETE',
                headers: { 'x-auth-token': token },
            });
            const data = await response.json();
            alert(data.message);
            if (response.ok) {
                fetchAllUsers(); // Listeyi yenile
            }
        } catch (err) {
            alert('Kullanıcı silinirken bir hata oluştu.');
        }
    };
    
    return (
        <>
            {selectedUserId && <UserDetailModal userId={selectedUserId} token={token} onClose={() => setSelectedUserId(null)} />}
            <div className="table-container">
                {users.length > 0 ? (
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
                            {users.map((user) => (
                                <tr key={user.id}>
                                    <td>{user.id}</td>
                                    <td>{`${user.ad || ''} ${user.soyad || ''}`}</td>
                                    <td>{user.email}</td>
                                    <td>{user.telefon_numarasi}</td>
                                    <td className="actions">
                                        <button onClick={() => setSelectedUserId(user.id)} className="details">Detaylar</button>
                                        <button onClick={() => handleDeleteUser(user.id)} className="delete">Sil</button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : (
                    <p>Sisteme kayıtlı kullanıcı bulunmuyor.</p>
                )}
            </div>
        </>
    );
}

// Sürücü Detaylarını Gösteren Modal Bileşeni
function DriverDetailModal({ driverId, token, onClose }) {
    const [driver, setDriver] = useState(null);
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        const fetchDriverDetails = async () => {
            try {
                const response = await fetch(`${API_URL}/drivers/${driverId}`, {
                    headers: { 'x-auth-token': token },
                });
                const data = await response.json();
                if (response.ok) {
                    setDriver(data);
                }
            } catch (err) {
                console.error('Sürücü detayı alınamadı:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchDriverDetails();
    }, [driverId, token]);
    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                {loading ? <p>Yükleniyor...</p> : driver ? (
                    <>
                        <div className="modal-header">
                            <h3>{`${driver.ad} ${driver.soyad}`} Detayları</h3>
                            <button onClick={onClose} className="close-button">&times;</button>
                        </div>
                        <h4>Bilgiler</h4>
                        <p><strong>Email:</strong> {driver.email}</p>
                        <p><strong>Telefon:</strong> {driver.telefon_numarasi}</p>
                        <p><strong>Onay Durumu:</strong> <span className={`status-badge status-${driver.hesap_onay_durumu}`}>{driver.hesap_onay_durumu}</span></p>
                        
                        <h4>Yüklenen Belgeler</h4>
                        {driver.documents && driver.documents.length > 0 ? (
                            <ul className="document-list">
                                {driver.documents.map(doc => (
                                    <li key={doc.id}>
                                        {doc.belge_tipi}: <a href={`http://localhost:3000${doc.dosya_url}`} target="_blank" rel="noopener noreferrer">Görüntüle</a>
                                    </li>
                                ))}
                            </ul>
                        ) : <p>Yüklenmiş belge bulunmuyor.</p>}
                    </>
                ) : <p>Sürücü bilgileri yüklenemedi.</p>}
            </div>
        </div>
    );
}

// Kullanıcı Detaylarını Gösteren Modal Bileşeni
function UserDetailModal({ userId, token, onClose }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchUserDetails = async () => {
            try {
                const response = await fetch(`${API_URL}/users/${userId}/details`, { headers: { 'x-auth-token': token } });
                if (response.ok) setUser(await response.json());
            } catch (err) {
                console.error('Kullanıcı detayı alınamadı:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchUserDetails();
    }, [userId, token]);

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                {loading ? <p>Yükleniyor...</p> : user ? (
                    <>
                        <div className="modal-header">
                            <h3>{`${user.ad} ${user.soyad}`} Detayları</h3>
                            <button onClick={onClose} className="close-button">&times;</button>
                        </div>
                        <h4>Genel Bilgiler</h4>
                        <p><strong>Email:</strong> {user.email}</p>
                        <p><strong>Telefon:</strong> {user.telefon_numarasi}</p>
                        
                        <h4>Yolculuk İstatistikleri</h4>
                        {user.stats ? (
                           <ul className="stats-list">
                               <li><strong>Toplam Tamamlanan Yolculuk:</strong> {user.stats.totalRides}</li>
                               <li><strong>Toplam Kat Edilen Mesafe:</strong> {user.stats.totalDistanceKm} km</li>
                           </ul>
                        ) : <p>İstatistik bulunmuyor.</p>}
                    </>
                ) : <p>Kullanıcı bilgileri yüklenemedi.</p>}
            </div>
        </div>
    );
}

// İstatistik Kartı Bileşeni
function StatCard({ title, value }) {
    return (
        <div className="stat-card">
            <h3>{title}</h3>
            <p>{value}</p>
        </div>
    );
}

export default App;

