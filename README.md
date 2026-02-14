# 🎮 MatematiKöy - Çocuklar İçin Eğlenceli Matematik Öğrenme Uygulaması

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.8-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.8-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Private-red)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

**Matematik öğrenmeyi oyuna dönüştüren, çocuklar için tasarlanmış eğitici mobil uygulama**

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Oyunlar](#-oyunlar) • [Teknolojiler](#-kullanılan-teknolojiler) • [Mimari](#-proje-mimarisi)

</div>

---

## 📖 Hakkında

**MatematiKöy**, 4-10 yaş arası çocukların matematik becerilerini eğlenceli oyunlar aracılığıyla geliştirmelerine yardımcı olan bir Flutter uygulamasıdır. Uygulama, çocukların kendi hızlarında öğrenmelerini sağlayan seviye tabanlı bir sistem ve ebeveynler için detaylı ilerleme takibi sunar.

### 🎯 Temel Hedefler

- ✅ Matematiği eğlenceli ve erişilebilir hale getirmek
- ✅ Çocukların öğrenme motivasyonunu artırmak
- ✅ Ebeveynlere çocuklarının gelişimini takip etme imkanı sunmak
- ✅ Güvenli, reklamsız ve çocuk dostu bir ortam sağlamak

---

## ✨ Özellikler

### 🎮 Çoklu Oyun Modları

| Oyun | Açıklama | Beceriler |
|------|----------|-----------|
| **Matematik Yarışı** | Seviye tabanlı dört işlem pratiği | Toplama, Çıkarma, Çarpma, Bölme |
| **Matematik Savaşı** | Canavarlara karşı hızlı hesaplama | Hız, Doğruluk, Odaklanma |
| **Balon Patlatma** | Doğru sonucu bul ve balonları patlat | Görsel Algı, Hızlı Düşünme |
| **Sayı Sıralama** | Sayıları küçükten büyüğe sırala | Sayı Kavramı, Sıralama |

### 👨‍👩‍👧‍👦 Ebeveyn Paneli

- 📊 **İlerleme Takibi**: Çocuğunuzun performansını grafiklerle görüntüleyin
- 📈 **Detaylı İstatistikler**: Oyun geçmişi, doğru/yanlış oranları, süre analizleri
- 🎯 **Seviye Bilgisi**: Hangi konularda güçlü, hangi konularda gelişmesi gerektiğini görün
- 🔒 **Ebeveyn Kilidi**: Çocukların ayarlara erişimini engelleyen güvenlik sistemi

### 🎨 Kullanıcı Deneyimi

- 🌈 **Modern ve Renkli Tasarım**: Çocukların ilgisini çeken canlı renkler ve animasyonlar
- 🎵 **Ses Efektleri**: Başarıları kutlayan ve motivasyon artıran sesler
- 🏆 **Ödül Sistemi**: Puan toplama ve seviye atlama mekanizmaları
- 📱 **Responsive Tasarım**: Tüm ekran boyutlarında mükemmel görünüm
- 🌐 **Türkçe Dil Desteği**: Tam Türkçe arayüz ve içerik

### 🧠 Akıllı Soru Üretimi

- Zorluk seviyesine göre dinamik soru oluşturma (Kolay, Orta, Zor)
- Ezberi önleyen akıllı yanıltıcı seçenekler
- Basamak değerlerini öğreten alt alta işlem formatı
- Her oyunda farklı sorular ile tekrar önleme

---

## 🎮 Oyunlar

### 1️⃣ Matematik Yarışı
Seviye tabanlı klasik matematik oyunu. Çocuklar dört işlem türünden birini seçer, zorluk seviyesini belirler ve soruları çözerek seviye atlar.

**Özellikler:**
- 3 zorluk seviyesi (Kolay, Orta, Zor)
- 4 işlem türü (Toplama, Çıkarma, Çarpma, Bölme)
- İlerleme çubuğu ve seviye sistemi
- Glassmorphism tasarımlı soru paneli

### 2️⃣ Matematik Savaşı
Canavarlarla savaşarak matematik soruları çözme oyunu. Her doğru cevap canavarı zayıflatır, yanlış cevap ise canavar güçlenir.

**Özellikler:**
- Animasyonlu canavar karakteri
- Sağlık barı sistemi
- Shimmer efektli sorular
- Heyecan verici ses efektleri

### 3️⃣ Balon Patlatma
Ekranda uçan balonlar arasından doğru sonucu içeren balonu bulup patlatma oyunu.

**Özellikler:**
- Fizik tabanlı balon animasyonları
- Renkli ve dinamik görsel efektler
- Zaman baskısı ile hızlı düşünme
- Çocuk dostu hız ayarları

### 4️⃣ Sayı Sıralama
Verilen sayıları küçükten büyüğe doğru sıralama oyunu. Drag & drop mekanizması ile etkileşimli öğrenme.

**Özellikler:**
- Sürükle-bırak arayüzü
- Görsel geri bildirim
- Sayı kavramını güçlendirme
- Kolay ve eğlenceli mekanik

---

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK: `>=3.10.8`
- Dart SDK: `>=3.10.8`
- Android Studio / Xcode (platform geliştirme için)
- Git

### Adımlar

1. **Projeyi Klonlayın**
```bash
git clone <repository-url>
cd eduplay
```

2. **Bağımlılıkları Yükleyin**
```bash
flutter pub get
```

3. **Uygulamayı Çalıştırın**
```bash
# Android için
flutter run

# iOS için (macOS gereklidir)
flutter run -d ios

# Web için
flutter run -d chrome
```

4. **Release Build Oluşturma**
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release

# Web
flutter build web --release
```

---

## 🛠 Kullanılan Teknolojiler

### Framework & Dil
- **Flutter** - Cross-platform UI framework
- **Dart** - Programlama dili

### Veritaşı & Veri Yönetimi
- **sqflite** - Yerel SQLite veritabanı
- **path** - Dosya yolu yönetimi

### UI/UX Kütüphaneleri
- **google_fonts** - Modern tipografi (Nunito, Outfit)
- **flutter_animate** - Gelişmiş animasyonlar
- **shimmer** - Parıltı efektleri
- **animated_text_kit** - Animasyonlu metinler
- **lottie** - Vektör animasyonları
- **confetti** - Kutlama efektleri

### Grafikler & Görselleştirme
- **fl_chart** - İstatistik grafikleri

### Ses & Medya
- **audioplayers** - Ses efektleri ve müzik

### Diğer
- **provider** - State management
- **intl** - Uluslararasılaştırma ve tarih formatları

---

## 📁 Proje Mimarisi

```
lib/
├── core/                          # Temel yapılar
│   ├── app_colors.dart           # Renk paleti
│   ├── services/
│   │   └── sound_service.dart    # Ses yönetimi
│   └── widgets/
│       └── neumorphic_game_button.dart  # Özel buton widget'ı
│
├── data/                          # Veri katmanı
│   ├── database/
│   │   └── database_helper.dart  # SQLite yönetimi
│   ├── models/
│   │   ├── child_profile.dart    # Çocuk profil modeli
│   │   ├── game_session.dart     # Oyun oturumu modeli
│   │   └── question_rule.dart    # Soru kuralları modeli
│   └── repositories/
│       ├── child_repository.dart # Profil CRUD işlemleri
│       └── game_repository.dart  # Oyun verisi işlemleri
│
├── features/                      # Özellik modülleri
│   ├── game/
│   │   ├── screens/
│   │   │   ├── game_hub_screen.dart       # Ana oyun menüsü
│   │   │   ├── level_map_screen.dart      # Seviye seçim ekranı
│   │   │   ├── game_page_modern.dart      # Matematik Yarışı
│   │   │   ├── game_page_enhanced.dart    # Matematik Savaşı
│   │   │   ├── balloon_pop_game.dart      # Balon Patlatma
│   │   │   └── number_ordering_game.dart  # Sayı Sıralama
│   │   └── services/
│   │       └── question_generator.dart    # Dinamik soru üretimi
│   │
│   ├── parent_panel/
│   │   └── screens/
│   │       └── parent_panel_screen.dart   # Ebeveyn paneli
│   │
│   └── onboarding/
│       └── screens/
│           └── child_profile_screen.dart  # Profil oluşturma
│
└── main.dart                      # Uygulama giriş noktası
```

### Mimari Prensipler

- **Katmanlı Mimari**: Data, Domain, Presentation katmanları
- **Repository Pattern**: Veri erişim soyutlaması
- **Service Pattern**: İş mantığı ayrımı
- **Widget Composition**: Yeniden kullanılabilir bileşenler

---

## 🎨 Tasarım Sistemi

### Renk Paleti

```dart
// Ana Renkler
cloudBlue: #B3D9FF
sunYellow: #FFD54F
leafGreen: #66BB6A
berryRed: #EF5350
oceanBlue: #42A5F5
violetMain: #AB47BC

// Gölge Renkleri
leafGreenShadow: #388E3C
sunYellowShadow: #F57F17
berryRedShadow: #C62828
oceanBlueShadow: #1976D2
purpleDark: #6A1B9A
```

### Tipografi

- **Ana Font**: Nunito (Google Fonts)
- **Başlıklar**: Outfit (Google Fonts)
- **Ağırlıklar**: 400 (Regular), 700 (Bold), 900 (Black)

### UI Bileşenleri

- **Neumorphic Buttons**: Yumuşak gölgeli, modern butonlar
- **Glassmorphism Cards**: Cam efektli kartlar
- **Gradient Backgrounds**: Renkli geçişli arka planlar
- **Animated Elements**: Canlı ve etkileşimli animasyonlar

---

## 📊 Veritabanı Şeması

### Tablolar

#### `child_profile`
| Sütun | Tip | Açıklama |
|-------|-----|----------|
| id | INTEGER | Primary Key |
| name | TEXT | Çocuğun adı |
| age | INTEGER | Yaş |
| avatar_id | TEXT | Avatar emoji |
| current_level | INTEGER | Mevcut seviye |
| total_score | INTEGER | Toplam puan |
| created_at | TEXT | Oluşturulma tarihi |

#### `game_session`
| Sütun | Tip | Açıklama |
|-------|-----|----------|
| id | INTEGER | Primary Key |
| child_id | INTEGER | Foreign Key |
| game_type | TEXT | Oyun türü |
| operation | TEXT | İşlem türü (+, -, *, /) |
| difficulty | TEXT | Zorluk (kolay, orta, zor) |
| score | INTEGER | Kazanılan puan |
| correct_count | INTEGER | Doğru sayısı |
| wrong_count | INTEGER | Yanlış sayısı |
| duration_seconds | INTEGER | Süre (saniye) |
| started_at | TEXT | Başlangıç zamanı |
| ended_at | TEXT | Bitiş zamanı |

---

## 🔐 Güvenlik

- ✅ **Ebeveyn Kilidi**: Ayarlara erişim için matematiksel doğrulama
- ✅ **Yerel Veri Depolama**: Tüm veriler cihazda saklanır
- ✅ **İnternet Gerektirmez**: Offline çalışma
- ✅ **Reklamsız**: Çocuklar için güvenli ortam
- ✅ **Kişisel Veri Toplama Yok**: Gizlilik öncelikli

---

## 🎯 Gelecek Özellikler

- [ ] Çoklu profil desteği (kardeşler için)
- [ ] Başarı rozetleri sistemi
- [ ] Haftalık/aylık ilerleme raporları
- [ ] Özel zorluk seviyesi oluşturma
- [ ] Sesli soru okuma (erişilebilirlik)
- [ ] Tema seçenekleri (karanlık mod)
- [ ] Daha fazla oyun modu
- [ ] Ebeveyn-çocuk yarışma modu

---

## 📝 Lisans

Bu proje özel bir projedir ve şu anda açık kaynak değildir.

---

## 👨‍💻 Geliştirici

**Karaca**

---

## 🙏 Teşekkürler

Bu projeyi geliştirirken kullanılan açık kaynak kütüphanelerin geliştiricilerine teşekkürler.

---

<div align="center">

**MatematiKöy ile matematik öğrenmek artık çok daha eğlenceli! 🎉**

Made with ❤️ and Flutter

</div>
