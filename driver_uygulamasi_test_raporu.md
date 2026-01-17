# Captaksi Sürücü Uygulaması (Driver App) Test Raporu

**Tarih:** 17 Ocak 2026
**Durum:** ✅ Başarılı (Uygulama Çalışıyor)

## 1. Gerçekleştirilen Test Adımları

### A. Backend Sunucu Kontrolü
- **İşlem:** API sunucusunun (`localhost:3000`) çalışır durumda olduğu doğrulandı.
- **Sonuç:** ✅ Sunucu aktif ve isteklere yanıt veriyor.

### B. Sürücü Kaydı (Registration Simülasyonu)
- **İşlem:** Otomasyon scripti kullanılarak API üzerinden sıfırdan yeni bir sürücü kaydı oluşturuldu.
- **Sonuç:** ✅ Kayıt işlemi hatasız tamamlandı.
- **Doğrulama:** Oluşturulan kullanıcı ile "Login" işlemi yapıldı ve geçerli bir **JWT Token** alındı. Bu, kullanıcının veritabanına sorunsuz işlendiğini kanıtlar.

### C. Mobil Uygulama Testi (Android)
- **İşlem:** `captaksi_driver_app` Android emülatörde (`emulator-5554`) derlendi ve başlatıldı.
- **Sonuç:** ✅ Uygulama çökme olmadan (Build Success) açıldı.

## 2. Test İçin Oluşturulan Sürücü Bilgileri

Aşağıdaki bilgilerle sürücü uygulamasında giriş yapabilirsiniz. Bu bilgiler ayrıca proje klasöründeki `new driver and rider tokens.txt` dosyasına da eklenmiştir.

| Alan | Değer |
|------|-------|
| **E-posta** | `driver_1768631916903@example.com` |
| **Şifre** | `driver123` |
| **Telefon** | `5551916903` |

## 3. Teknik Notlar ve Öneriler
- **Emülatör Bağlantısı:** Uygulama içinde API adresi `10.0.2.2:3000` olarak yapılandırılmıştır (Android emülatörün localhost'u görmesi için standart adres). Eğer gerçek cihazda test edilecekse, bu adresin bilgisayarınızın yerel IP adresi (örn: `192.168.1.x`) ile değiştirilmesi gerekir.
- **İzinler:** Uygulama açılışta Konum (Location) izni isteyecektir, bu izni vermeniz gerekmektedir.
