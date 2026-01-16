<h1 align="center">🚕 CAPTAKSI – Ride Hailing Platform</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Backend-Node.js-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/Frontend-Flutter-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Database-PostgreSQL-informational?style=for-the-badge">
  <img src="https://img.shields.io/badge/Realtime-Socket.IO-yellow?style=for-the-badge">
</p>


---

## 🚀 Son Güncellemeler (v1.1)
- **Mobil Uygulama:** Release modunda çökme yaratan bağımlılık sorunu giderildi.
- **Backend Güvenlik:** `helmet` eklendi, CORS kısıtlandı.
- **Kod Temizliği:** Gereksiz loglar ve tekrarlanan rotalar temizlendi.

---

## 📦 Proje Yapısı

```bash
captaksi-full-project/
├── captaksi-backend          # Express + PostgreSQL + Socket.IO API
├── captaksi_app              # Yolcu Flutter Uygulaması
└── captaksi_driver_app       # Sürücü Flutter Uygulaması
```

---

## ✨ Özellikler

### 🚗 Yolcu Uygulaması
- Adres arama (Google Maps)
- Araç tipi seçimi
- Yakındaki sürücüleri görme
- Yolculuk isteği gönderme
- Canlı eşleşme bildirimleri
- Geçmiş yolculuk & puanlama sistemi

### 🚕 Sürücü Uygulaması
- Online/Offline modu
- Gerçek zamanlı konum iletme
- Yolculuk kabul etme
- Yolculuğu başlatma & bitirme

### 🖥 Backend (Node.js)
- JWT tabanlı auth (yolcu & sürücü)
- PostGIS ile konum sorgusu
- Socket.IO ile real-time odalar
- Dosya upload (profil foto, sabıka kaydı PDF)
- Admin kontrolleri

---

## 🏗 Mimari Akış

<p align="center">
  <img src="https://skillicons.dev/icons?i=nodejs,express,postgres,flutter,dart,git,github" />
</p>

### Sürücü – Yolcu Eşleşmesi:

```
Yolcu → /api/rides → Socket → Sürücü odası → Sürücü kabul → Yolcu odası → Bildirim
```

### Sürücü Oda Mantığı:

```
vehicle_type_1
vehicle_type_2
vehicle_type_3
```

### Yolcu Oda Mantığı:

```
user_12
user_33
```

---

## 🛠 Kurulum

### Backend

```bash
cd captaksi-backend
npm install
```

.env oluştur:

```env
PORT=3000
DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=captaksi_db
DB_PASSWORD=your_password
DB_PORT=5432
JWT_SECRET=super-secret-key
NODE_ENV=development
```

Çalıştır:

```bash
node server.js
```

---

## 📱 Flutter App’ler

Ortak adımlar:

```bash
flutter pub get
flutter run
```

Backend IP’sini düzenlemeyi unutma:

```dart
static const baseUrl = "http://<your-ip>:3000/api";
```

---

## 🔐 Güvenlik Önemli Notlar

- [x] `.env` asla repo içinde olmaz  
- [ ] Google Maps key → restrict et  
- [x] CORS → production domain ver  
- [x] Helmet ile güvenlik başlıkları ekle
- [ ] Rate limit ekle  

---

## 🧩 Yol Haritası

Aşağıdaki yapılacaklar aşağıda ayrıca listelenmiştir.

---

<h3 align="center">Developed with ❤️ by<a href:"http://instagram.com/mr.vinsky"> mr.vinsky</h3></a>

