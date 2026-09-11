# 🛡️ DeepCheck-Chain Mobil

> **"Sıfır Güven (Zero-Trust) Dünyasında, Gerçeğin Sarsılmaz Zinciri."**  
> *TEKNOFEST Blokzincir Yarışması Finalist Projesi*

---

## 📌 Proje Genel Bakış

**DeepCheck-Chain Mobil**, yapay zeka tabanlı derin sahtecilik (deepfake) tespit algoritmaları ile kurumsal blokzincir (Hyperledger Fabric) altyapısını birleştiren uçtan uca bir **Dijital Noter ve Güvenlik Kalkanı** mobil uygulamasıdır.

Kullanıcıların yüklediği veya anlık çektiği medya dosyaları:
1. İstemci tarafında anında kriptografik **SHA-256** özetine dönüştürülür.
2. Arka plandaki **FastAPI** servisleri üzerinden **CNN/ViT Derin Öğrenme Modelleri** ile analiz edilir.
3. Analiz sonucu, dosya özeti ve zaman damgası **Hyperledger Fabric** dağıtık defterine işlem ID'si (TxID) ile sarsılmaz biçimde mühürlenir.

---

## 📱 Ekranlar ve Temel Özellikler

- **🌌 3D Voxel Siber Splash Ekranı**: Üç boyutlu parçacıkların ve siber küplerin birleşmesiyle oluşan estetik açılış animasyonu.
- **📜 Dijital Noter (Notary)**: Galeriden fotoğraf seçme veya kamerayla çekme, radar tarama animasyonu, anlık SHA-256 hesaplama, AI analiz skoru ve blokzincir mühür kartı. Yerel geçmiş kaydı (SharedPreferences) ile önceki kayıtları listeleme.
- **🛡️ Güvenlik Kalkanı (Shield)**: Medya veya hash ile sarsılmaz blokzincir doğrulama, sahtecilik önleme paneli.
- **⚡ Sistem Durumu (System Status)**: FastAPI sunucusu, CNN/ViT AI modelleri, Hyperledger Fabric eşleri (peers), konsensüs mekanizması ve IPFS durum monitörü.

---

## 🎨 Tasarım ve UI/UX Mimarisi

- **Tema:** Derin siber uzay siyahı (`#070B19`, `#0B132B`).
- **Renk Paleti:** Prestijli "Black & Gold" (Altın sarısı `#F5A623`, `#FFD700`, neon mavi ve siber vurgular).
- **Efektler:** Glassmorphism (buzlu cam kartlar), kesik köşeli siber butonlar, tarama ızgarası (Cyber Grid & Scan Line).

---

## 📂 Proje Dizin Yapısı

```text
lib/
├── core/
│   ├── constants.dart          # API adresleri, renk paletleri ve sabitler
│   └── theme.dart              # Siber koyu tema ve tipografi
├── models/
│   └── analysis_result.dart    # AI analiz, TxID, SHA-256 ve blokzincir veri modelleri
├── services/
│   └── api_service.dart        # FastAPI backend entegrasyonu ve demo/offline modu
├── widgets/
│   ├── cyber_button.dart       # Neon ve altın efektli siber butonlar
│   ├── cyber_grid_painter.dart # Hareketli siber ızgara arka planı
│   └── glass_card.dart         # Glassmorphism kart bileşeni
├── screens/
│   ├── splash_screen.dart      # 3D Voxel küp açılış animasyonu
│   ├── main_shell.dart         # Modern alt gezinme çubuğu (Navigation Shell)
│   ├── notary_screen.dart      # Dijital noter ve analiz ekranı
│   ├── shield_screen.dart      # Blokzincir doğrulama ve kalkan ekranı
│   └── system_status_screen.dart # Canlı sunucu ve blokzincir düğüm monitörü
└── main.dart                   # Temiz uygulama giriş noktası
```

---

## 🚀 Kurulum ve Çalıştırma

### Adımlar

1. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

2. Kod analizini çalıştırın:
```bash
flutter analyze
```

3. Uygulamayı başlatın:
```bash
flutter run
```

---

## 🔗 Backend Entegrasyonu

Backend repository: [https://github.com/erenguler16/DeepCheck-Chain](https://github.com/erenguler16/DeepCheck-Chain)

Uygulama, backend erişilebilir olmadığında otomatik olarak **Zero-Trust Demo/Simülasyon Modu**na geçer ve jüri sunumlarında kesintisiz çalışır. Gerçek backend bağlandığında `lib/core/constants.dart` içerisindeki `apiBaseUrl` üzerinden canlı haberleşir.

