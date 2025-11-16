<h1 align="center">🚕 CAPTAKSI – Ride Hailing Platform</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Backend-Node.js-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/Frontend-Flutter-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Database-PostgreSQL-informational?style=for-the-badge">
  <img src="https://img.shields.io/badge/Realtime-Socket.IO-yellow?style=for-the-badge">
</p>

<p align="center"><b>Uber benzeri iki taraflı sürücü–yolcu eşleme sistemi</b></p>

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
DATABASE_URL=postgres://user:pass@localhost:5432/captaksi
JWT_SECRET=super-secret-key
GOOGLE_MAPS_KEY=xxxxx
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

- `.env` asla repo içinde olmaz  
- Google Maps key → restrict et  
- CORS → production domain ver  
- Rate limit ekle  

---

## 🧩 Yol Haritası

Aşağıdaki yapılacaklar aşağıda ayrıca listelenmiştir.

---

<h3 align="center">Developed with ❤️ by Captaksi Team</h3>

