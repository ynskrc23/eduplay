# 📱 AdMob Entegrasyon Kılavuzu - MatematiKöy

## ✅ Tamamlanan Adımlar

### 1. Package Kurulumu
- ✅ `google_mobile_ads: ^5.2.0` pubspec.yaml'a eklendi
- ✅ `flutter pub get` çalıştırıldı

### 2. AdMob Hesap Bilgileri

#### Android
```
App ID: ca-app-pub-9933328519370940~7383967585
Interstitial Ad Unit ID: ca-app-pub-9933328519370940/2107590173
```

#### iOS
```
App ID: ca-app-pub-9933328519370940~9948318108
Interstitial Ad Unit ID: ca-app-pub-9933328519370940/5796495691
```

### 3. Platform Konfigürasyonu

#### Android (AndroidManifest.xml)
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-9933328519370940~7383967585"/>
```
✅ Dosya: `android/app/src/main/AndroidManifest.xml`

#### iOS (Info.plist)
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-9933328519370940~7383967585</string>
```
✅ Dosya: `ios/Runner/Info.plist`

### 4. AdMob Service Oluşturuldu
✅ Dosya: `lib/core/services/admob_service.dart`

**Özellikler:**
- Singleton pattern ile tek instance
- Otomatik reklam yükleme
- Her 3 oyunda bir reklam gösterme mantığı
- Test modu desteği (geliştirme için)

### 5. Uygulama Entegrasyonu

#### main.dart
```dart
import 'core/services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdMobService().initialize(); // AdMob başlatma
  runApp(const MatematiKoyApp());
}
```

#### Oyun Ekranları
Aşağıdaki dosyalara reklam gösterme eklendi:
- ✅ `game_page_modern.dart` (Matematik Yarışı)
- ✅ `game_page_enhanced.dart` (Matematik Savaşı)
- ✅ `balloon_pop_game.dart` (Balon Patlatma)
- ✅ `number_ordering_game.dart` (Sayı Sıralama)

**Tüm oyunlar reklam entegrasyonuna sahip! 🎉**

**Kullanım:**
```dart
// Oyun bittiğinde
AdMobService().onGameCompleted();
```

---

## 🎯 Reklam Gösterme Mantığı

### Geçiş (Interstitial) Reklamları
- **Ne zaman gösterilir?** Her 3 oyun tamamlandığında
- **Nerede gösterilir?** Oyun bitip ana menüye dönüldüğünde
- **Nasıl çalışır?** 
  1. Kullanıcı oyunu bitirir
  2. `AdMobService().onGameCompleted()` çağrılır
  3. Sayaç kontrol edilir (3'e ulaştı mı?)
  4. Eğer 3'e ulaştıysa reklam gösterilir
  5. Sayaç sıfırlanır

### Örnek Senaryo
```
Oyun 1: Matematik Yarışı → Çıkış → Reklam YOK (Sayaç: 1)
Oyun 2: Balon Patlatma → Çıkış → Reklam YOK (Sayaç: 2)
Oyun 3: Sayı Sıralama → Çıkış → REKLAM GÖSTERİLİR (Sayaç: 3 → 0)
Oyun 4: Matematik Savaşı → Çıkış → Reklam YOK (Sayaç: 1)
...
```

---

## 🧪 Test Etme

### Test Modu
Geliştirme sırasında test reklamları kullanmak için:

```dart
// admob_service.dart içinde
static bool get _isTestMode => true; // Test modunu aç
```

**Test Ad Unit ID'leri:**
- Android: `ca-app-pub-3940256099942544/1033173712`
- iOS: `ca-app-pub-3940256099942544/4411468910`

### Production Modu
Uygulamayı yayınlamadan önce:

```dart
// admob_service.dart içinde
static bool get _isTestMode => false; // Production modu
```

---

## 📋 Yapılacaklar Listesi

### Diğer Oyunlara Ekleme
Aşağıdaki oyunlara da reklam entegrasyonu eklenebilir:

- [ ] `game_page_enhanced.dart` (Matematik Savaşı)
- [ ] `number_ordering_game.dart` (Sayı Sıralama)

**Nasıl eklenir?**
1. Import ekle:
```dart
import '../../../core/services/admob_service.dart';
```

2. Çıkış fonksiyonunda çağır:
```dart
void _exitGame() {
  AdMobService().onGameCompleted();
  Navigator.pop(context);
}
```

---

## ⚙️ Özelleştirme Seçenekleri

### Reklam Sıklığını Değiştirme
```dart
// admob_service.dart içinde
static const int _showAdAfterGames = 3; // Değiştir (örn: 5)
```

### Reklam Türü Ekleme
Şu anda sadece Interstitial (Geçiş) reklamları aktif.

**Eklenebilecek reklam türleri:**
- **Banner Ads**: Ekranın alt/üstünde sürekli görünen reklamlar
- **Rewarded Ads**: İzleme karşılığında ödül veren reklamlar
- **Native Ads**: Uygulamanın tasarımına uyumlu reklamlar

---

## 🚨 Önemli Notlar

### 1. AdMob Politikaları
- ✅ Çocuklara yönelik uygulamalar için özel kurallar var
- ✅ COPPA (Children's Online Privacy Protection Act) uyumlu olmalı
- ✅ Reklamlar çocuk dostu içerik olmalı

### 2. AdMob Ayarları (AdMob Console'da)
AdMob hesabınızda şunları yapın:
- [ ] Uygulama türünü "Çocuklara yönelik" olarak işaretleyin
- [ ] Hassas kategorileri engelleyin
- [ ] Aile için uygun reklam filtrelerini aktifleştirin

### 3. App Store / Play Store Gereksinimleri
- [ ] Gizlilik politikasında reklam kullanımını belirtin
- [ ] Uygulama açıklamasında reklam olduğunu belirtin
- [ ] Yaş derecelendirmesini doğru yapın

---

## 🐛 Sorun Giderme

### Reklam Yüklenmiyor
**Çözüm:**
1. İnternet bağlantısını kontrol edin
2. AdMob hesabının aktif olduğundan emin olun
3. App ID ve Ad Unit ID'lerin doğru olduğunu kontrol edin
4. Test modunda test ID'leri kullanın

### Reklam Gösterilmiyor
**Çözüm:**
1. `_isInterstitialAdReady` değerini kontrol edin
2. Console'da hata mesajlarını inceleyin
3. Reklam yüklenme süresini bekleyin (ilk açılışta 30-60 saniye)

### Test Reklamları Görünmüyor
**Çözüm:**
1. `_isTestMode = true` olduğundan emin olun
2. Uygulamayı tamamen kapatıp tekrar açın
3. `flutter clean` ve `flutter pub get` çalıştırın

---

## 📊 Gelir Takibi

AdMob Console'da şunları takip edebilirsiniz:
- Reklam gösterim sayısı
- Tıklama oranı (CTR)
- Kazanç (eCPM)
- Doldurma oranı

**Önerilen Metrikler:**
- **Günlük aktif kullanıcı başına reklam:** 2-3 reklam
- **Hedef CTR:** %1-3
- **Hedef doldurma oranı:** %90+

---

## 🎓 Ek Kaynaklar

- [Google Mobile Ads Flutter Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Başlangıç Kılavuzu](https://developers.google.com/admob/flutter/quick-start)
- [AdMob Politikaları](https://support.google.com/admob/answer/6128543)
- [COPPA Uyumluluğu](https://support.google.com/admob/answer/6223431)

---

## ✅ Kontrol Listesi (Yayınlamadan Önce)

- [ ] Test modunu kapat (`_isTestMode = false`)
- [ ] Gerçek Ad Unit ID'leri kullanıldığından emin ol
- [ ] AdMob hesabında "Çocuklara yönelik" ayarları yap
- [ ] Gizlilik politikasını güncelle
- [ ] Tüm oyunlarda reklam entegrasyonunu test et
- [ ] Reklam sıklığının kullanıcı deneyimini bozmadığını kontrol et
- [ ] iOS ve Android'de ayrı ayrı test et

---

## 📞 Destek

Sorun yaşarsanız:
1. Console loglarını kontrol edin
2. AdMob hesap durumunu kontrol edin
3. Google AdMob desteğine başvurun

---

**Son Güncelleme:** 14 Şubat 2026
**Versiyon:** 1.0.0
