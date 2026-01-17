# 🚖 CAPTAKSI - Full Stack Taksi Çağırma Projesi

Bu proje, modern bir taksi çağırma platformunun uçtan uca (Yolcu App, Sürücü App, Backend, Admin Panel) implementasyonudur.

## 📁 Proje Yapısı

1.  **`captaksi_app`**: Yolcu (Müşteri) için geliştirilen mobil uygulama (Flutter).
2.  **`captaksi_driver_app`**: Sürücüler için geliştirilen mobil uygulama (Flutter).
3.  **`captaksi-backend`**: Node.js/Express ve PostgreSQL tabanlı REST API sunucusu. Socket.IO ile gerçek zamanlı takip sağlar.
4.  **`captaksi-admin-panel`**: **[YENİ]** Yönetim için geliştirilen Dashboard (React).

---

## 🚀 4. Captaksi Yönetim (Admin) Paneli

Projenin yönetim merkezi olan Admin Paneli, modern "Dark Mode" tasarımı ve gelişmiş özellikleriyle yenilendi.

*   **Teknolojiler:** React, Recharts, CSS Modules.
*   **Adres:** `http://localhost:3001`
*   **Giriş Bilgileri:** `admin@captaksi.com` / `123456`

### Özellikler (V3.1 Güncellemesi)
1.  **📊 Gelişmiş Dashboard:**
    *   Son 6 ayın gelir grafiği (Bar Chart).
    *   Yolcu/Sürücü dağılım pastası (Pie Chart).
    *   Toplam kullanıcı, sürücü, yolculuk ve ciro istatistikleri.
2.  **🚕 Sürücü Yönetimi:**
    *   **Onay Sistemi:** Yeni kayıt olan sürücüleri "Bekleyenler" listesinde görüntüleyip **Onayla** veya **Reddet** butonlarıyla yönetebilirsiniz.
    *   **Listeleme:** Kayıtlı tüm sürücülerin detaylarını, puanlarını ve aktiflik durumlarını görebilirsiniz.
3.  **👥 Kullanıcı Takibi:** Kayıtlı yolcuların listesi ve işlem geçmişi.

### Kurulum ve Çalıştırma
```bash
cd captaksi-admin-panel
npm install
npm start
```
*Not: Backend 3000 portunda çalıştığı için Admin Paneli varsayılan olarak **3001** portunda açılır.*

---

## 🛠 Backend Kurulumu ve API

Sunucunun ve veritabanının sağlıklı çalışması için:

1.  PostgreSQL veritabanının kurulu ve aktif olduğundan emin olun (`.env` dosyasındaki ayarları kontrol edin).
2.  Gerekli tablolar (`users`, `drivers`, `rides`) otomatik oluşturulur.
    *   *Sürücü tablosu güncellendi: `hesap_onay_durumu`, `kayit_tarihi` sütunları eklendi.*

```bash
cd captaksi-backend
node server.js
```

---

## 📱 Mobil Uygulamalar

*   **Yolcu Uygulaması:** `captaksi_app` dizininde `flutter run` ile çalıştırın.
*   **Sürücü Uygulaması:** `captaksi_driver_app` dizininde `flutter run` ile çalıştırın.

---

## 🔄 Son Değişiklikler (Changelog)

*   **Driver App V2.0 (YENİ):**
    *   **UI Redesign:** Modern "Deep Blue & Cyan" temasına geçildi. Altın/Siyah renkler kaldırıldı.
    *   **Gelişmiş Kart Yapısı:** Yolculuk talepleri artık doğrudan kart üzerinden "Kabul Et" ve "Reddet" butonlarına sahip.
    *   **Platform Desteği:** Android'in yanı sıra **macOS (Desktop Native)** ve **Web** desteği eklendi.
*   **Backend Fixes:**
    *   `/me/status` hatası (PostGIS uyumsuzluğu) standart enlem/boylam yapısına dönülerek giderildi.
    *   **Socket.IO:** Yolculuk talebi oluşturulduğunda sürücülere bildirim gitmeme sorunu çözüldü (`join_driver` event mismatch & Missing emission).
*   **Admin Panel V3.1:**
    *   "Onayla" butonu işlevsel hale getirildi (Backend entegrasyonu tamamlandı).
    *   Sürücü listeleme hataları giderildi.
    *   Grafiksel dashboard eklendi.
*   **Backend:** `/api/admin` rotaları eklendi. Admin yetkilendirmesi (JWT) entegre edildi.

---
*Geliştirici: Antigravity Agent*
