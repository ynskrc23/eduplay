# 🧠 MatematiKöy — Soru Oluşturma Yapısı

Bu döküman, projedeki soruların nasıl oluşturulduğunu, yaş gruplarına göre zorluk seviyelerinin nasıl belirlendiğini ve hangi bileşenlerin bu süreçte rol oynadığını detaylandırmaktadır.

---

## 🛠 Temel Bileşenler

| Bileşen | Dosya | Görevi |
| :--- | :--- | :--- |
| **QuestionRule** | `lib/data/models/question_rule.dart` | Sorunun sınırlarını tanımlar: min/max değerler, işlem türü, sonuç sınırı, basamak kontrolleri, çarpım tablosu listesi |
| **DifficultyService** | `lib/features/game/services/difficulty_service.dart` | Çocuğun **yaşına**, **işlem türüne** ve **zorluk seviyesine** göre uygun `QuestionRule` listesini döndürür (48 konfigürasyon) |
| **QuestionGenerator** | `lib/features/game/services/question_generator.dart` | Belirlenen kurallara göre rastgele sayı üretir, sonucu hesaplar ve akıllı şıklar oluşturur |

---

## ⚙️ Soru Üretim Akışı

1. **Yaş Tespiti** → `ChildProfile.age` üzerinden çocuğun yaşı hesaplanır
2. **Kural Seçimi** → `DifficultyService.getRules(yaş, işlem, zorluk)` çağrılır
3. **Rastgele Kural** → Dönen listeden rastgele bir `QuestionRule` seçilir
4. **Sayı Üretimi** → `QuestionGenerator.generate(rule)` ile soru oluşturulur
5. **Şık Üretimi** → `QuestionGenerator.generateOptions(question, 4)` ile 4 şık oluşturulur

---

## 📊 Yaş Grupları & Kural Tabloları

### 🎒 3-5 Yaş · Okul Öncesi

#### Toplama (+)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 tek basamaklı sayı (1-9) | 3 + 5 = 8 |
| **Orta** | 1 tek + 1 iki basamaklı, toplam ≤ 25 | 7 + 14 = 21 |
| **Zor** | 1 tek + 1 iki basamaklı VEYA 2 iki basamaklı, toplam ≤ 40 | 15 + 22 = 37 |

#### Çıkarma (−)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 tek basamaklı sayı (1-9) | 8 - 3 = 5 |
| **Orta** | 1 tek + 1 iki basamaklı, büyük sayı ≤ 25 | 22 - 7 = 15 |
| **Zor** | 1 tek + 1 iki basamaklı VEYA 2 iki basamaklı, büyük sayı ≤ 40 | 35 - 18 = 17 |

---

### 📚 6-8 Yaş · İlkokul 1-2

#### Toplama (+)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 tek / 2 iki basamaklı / 1 tek + 1 iki basamaklı, toplam ≤ 25 | 12 + 11 = 23 |
| **Orta** | 100'e kadar eldeli ve eldesiz toplama | 47 + 38 = 85 |
| **Zor** | 200'e kadar eldeli ve eldesiz toplama | 125 + 68 = 193 |

#### Çıkarma (−)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 tek / 2 iki basamaklı / 1 tek + 1 iki basamaklı, büyük ≤ 25 | 23 - 8 = 15 |
| **Orta** | Onluk bozarak/bozmayarak, büyük ≤ 100 | 73 - 28 = 45 |
| **Zor** | Onluk bozarak/bozmayarak, büyük ≤ 200 | 164 - 89 = 75 |

#### Çarpma (×)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 1, 2, 3 çarpım tablosu (×10'a kadar) | 3 × 7 = 21 |
| **Orta** | 4, 5, 6 çarpım tablosu (×10'a kadar), sonuç ≤ 60 | 5 × 9 = 45 |
| **Zor** | 7, 8, 9, 10 çarpım tablosu (×10'a kadar), sonuç ≤ 100 | 8 × 9 = 72 |

#### Bölme (÷)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | Çarpmanın tersi: 1, 2, 3 tablosu | 21 ÷ 3 = 7 |
| **Orta** | Çarpmanın tersi: 4, 5, 6 tablosu, sonuç ≤ 60 | 45 ÷ 5 = 9 |
| **Zor** | Çarpmanın tersi: 7, 8, 9, 10 tablosu, sonuç ≤ 100 | 72 ÷ 8 = 9 |

---

### 🏫 9-11 Yaş · İlkokul 3-4

#### Toplama (+)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | Eldeli/eldesiz, toplam 100-1000 | 345 + 278 = 623 |
| **Orta** | Eldeli/eldesiz, toplam 1000-5000 | 1820 + 2150 = 3970 |
| **Zor** | Eldeli/eldesiz, toplam 5000-10000 | 4500 + 3200 = 7700 |

#### Çıkarma (−)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | Onluk/yüzlük bozarak, küçük ≥ 2 bas, büyük ≤ 999 | 745 - 68 = 677 |
| **Orta** | Onluk/yüzlük bozarak, küçük ≥ 3 bas, büyük ≤ 5000 | 3200 - 850 = 2350 |
| **Zor** | Onluk/yüzlük bozarak, küçük ≥ 3 bas, büyük ≤ 9999 | 8500 - 2750 = 5750 |

#### Çarpma (×)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 7, 8, 9, 10 çarpım tablosu (×10), sonuç ≤ 200 | 9 × 8 = 72 |
| **Orta** | 1 tek × 2 basamaklı VEYA 2 bas × 2 bas, sonuç ≤ 8000 | 7 × 45 = 315 |
| **Zor** | 2 bas × 3 bas VEYA 2 bas × 2 bas, sonuç ≤ 60000 | 35 × 420 = 14700 |

#### Bölme (÷)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 basamaklı ÷ 1 basamaklı, kalansız | 72 ÷ 8 = 9 |
| **Orta** | 3 basamaklı ÷ 1-2 basamaklı, kalansız | 432 ÷ 12 = 36 |
| **Zor** | 4 basamaklı ÷ 2-3 basamaklı, kalansız | 4800 ÷ 120 = 40 |

---

### 🎓 12+ Yaş · Ortaokul

#### Toplama (+)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 3-4 basamaklı sayılarla | 1250 + 3400 = 4650 |
| **Orta** | 4+ basamaklı sayılarla | 4500 + 7200 = 11700 |
| **Zor** | 4-5 basamaklı sayılarla | 23000 + 45000 = 68000 |

#### Çıkarma (−)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | Onluk/yüzlük/binlik bozarak, küçük ≥ 2 bas, büyük ≤ 4999 | 3800 - 950 = 2850 |
| **Orta** | Onluk/yüzlük/binlik bozarak, küçük ≥ 3 bas, büyük ≤ 50000 | 42000 - 15000 = 27000 |
| **Zor** | Onluk/yüzlük/binlik bozarak, küçük ≥ 3 bas, büyük ≤ 99999 | 85000 - 32000 = 53000 |

#### Çarpma (×)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 1 tek × 2 bas VEYA 2 bas × 2 bas, sonuç ≤ 10000 | 45 × 68 = 3060 |
| **Orta** | 2 bas × 3 bas VEYA 2 bas × 2 bas, sonuç ≤ 90000 | 35 × 520 = 18200 |
| **Zor** | 2 bas × 3 bas VEYA 2 bas × 2 bas, sonuç ≤ 99000 | 42 × 780 = 32760 |

#### Bölme (÷)

| Zorluk | Kural | Örnek |
| :--- | :--- | :--- |
| **Kolay** | 2 bas ÷ 1 bas VEYA 3 bas ÷ 1-2 bas, kalansız | 630 ÷ 15 = 42 |
| **Orta** | 4 bas ÷ 2-3 bas, kalansız | 7200 ÷ 120 = 60 |
| **Zor** | 5 bas ÷ 2-4 bas, kalansız | 48000 ÷ 1200 = 40 |

---

## 💾 Veritabanı Yapısı

Seviye bazlı kurallar `question_rule` tablosunda tutulur (Matematik Yarışı modu):

```sql
CREATE TABLE question_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  level_id INTEGER,
  operation TEXT,      -- '+', '-', '*', '/'
  min_operand INTEGER,
  max_operand INTEGER,
  allow_negative INTEGER -- 0 veya 1
);
```

> **Not:** Yaş bazlı zengin kurallar (maxResult, minNum1/maxNum1, multiplicationBases vb.) sadece runtime'da `DifficultyService` tarafından üretilir ve veritabanına kaydedilmez.

---

## 🔧 Yeni Bir Kural Ekleme

1. `DifficultyService` içindeki ilgili yaş grubunun metoduna yeni `QuestionRule` ekleyin
2. Zengin kısıtlamalar için opsiyonel alanları kullanın:
   - `maxResult` / `minResult` → Sonuç sınırı
   - `minNum1` / `maxNum1` → İlk sayının aralığı
   - `minNum2` / `maxNum2` → İkinci sayının aralığı
   - `multiplicationBases` → Çarpım tablosu sabitleri (Örn: `[4, 5, 6]`)
   - `maxMultiplier` → Çarpım tablosunda çarpanın üst sınırı
