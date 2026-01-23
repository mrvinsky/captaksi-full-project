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

## ⚠️ Önemli Not: Test Ortamı ve Konfigürasyon

**Sürücü Uygulaması (Driver App)** şu anda **fiziksel bir cihazda** test edilmek üzere yapılandırılmıştır. 
API ve Socket bağlantıları için bilgisayarınızın yerel IP adresini kullanır (örn: `10.71.98.18`).

### 📱 Simülatörde Test Etmek İsteyenler İçin:
Eğer uygulamayı Android Emulator veya iOS Simulator üzerinde denemek istiyorsanız, bağlantı ayarlarını değiştirmeniz gerekir:

1.  **Android Emulator için:**
    *   `lib/services/api_service.dart` ve `lib/services/socket_service.dart` dosyalarını açın.
    *   IP adresini `10.0.2.2` olarak değiştirin (Bu, emülatörün "localhost" adresidir).
    *   Örnek: `baseUrl = 'http://10.0.2.2:3000/api';`

2.  **iOS Simulator için:**
    *   Aynı dosyalarda IP adresini `localhost` veya `127.0.0.1` olarak değiştirin.

3.  **Fiziksel Cihaz (Mevcut Ayar):**
    *   Bilgisayarınızın ve telefonunuzun aynı Wi-Fi ağında olduğundan emin olun.
    *   Bilgisayarınızın yerel IP adresini (Terminalde `ipconfig` veya `ifconfig` ile) öğrenin.
    *   Kodlardaki IP adresini bu adresle güncelleyin.

---

## 🔄 Son Değişiklikler (Changelog)

*   **User App V2.1 (YENİ - Midnight Taxi Update):**
    *   **UI Overhaul:** Tüm tasarım "Midnight Taxi" konseptiyle yenilendi. Koyu gri (**Deep Charcoal**) zemin üzerine Premium Sarı (**Cheddar Yellow**) vurgular.
    *   **Typography:** Google Fonts (**Poppins**) entegrasyonu ile modern yazı tipleri.
    *   **UX İyileştirmeleri:** 
        *   Login/Register ekranları modernize edildi (Hero Header, Şeffaf AppBar).
        *   Taksi çağırma listesindeki görünmez yazı hatası giderildi (Dark Theme Fix).
*   **Backend & Veritabanı:**
    *   **PostGIS Kaldırıldı:** Kurulumu kolaylaştırmak için `GEOMETRY` tipleri yerine standart `DOUBLE PRECISION` (lat/lng) sütunlarına geçildi.
    *   **Create Ride Fix:** Yolculuk oluşturma (`/api/rides`) endpoint'i ve veritabanı mantığı sıfırdan yazıldı.
    *   **Socket.IO:** `rideController.js` içerisine manuel bildirim tetikleyicisi eklendi.
*   **Driver App V2.0:**
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
