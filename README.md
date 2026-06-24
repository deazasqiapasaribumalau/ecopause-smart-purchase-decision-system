# 🌿 EcoPause
### Think Before You Buy, Think Before You Waste

**Kelompok 4** — Dea Zasqia Pasaribu Malau & Tasya Zahrani

---

## 📋 Tentang Project

EcoPause adalah aplikasi mobile Flutter yang membantu pengguna **berhenti sejenak sebelum membeli** dengan mengevaluasi kebutuhan nyata vs dorongan FOMO (Fear of Missing Out).

**Mendukung SDG 12 — Responsible Consumption and Production**

---

## 🗂️ Struktur Project

```
ecopause/
├── lib/
│   ├── main.dart                          # Entry point + DevicePreview
│   ├── models/
│   │   └── models.dart                   # FomoEvaluation, WishlistItem, ShoppingLog
│   ├── screens/
│   │   ├── splash_screen.dart            # Animated splash + routing logic
│   │   ├── onboarding_screen.dart        # 3-slide onboarding + landing page
│   │   ├── login_screen.dart             # Login dengan validasi
│   │   ├── register_screen.dart          # Registrasi akun baru
│   │   ├── home_screen.dart              # Dashboard + Bottom Navigation
│   │   ├── fomo_detector_screen.dart     # 10-pertanyaan evaluasi pembelian
│   │   ├── fomo_result_screen.dart       # Hasil: Need Score + FOMO Score
│   │   ├── wishlist_screen.dart          # Smart Wishlist + Cooling Period timer
│   │   ├── jejak_belanja_screen.dart     # Shopping Impact Tracker
│   │   ├── report_screen.dart            # Monthly Consumption Report + Chart
│   │   ├── profile_screen.dart           # Profil pengguna
│   │   ├── shopping_detail_screen.dart   # Detail item belanja
│   │   └── evaluation_detail_screen.dart # Detail hasil evaluasi
│   ├── widgets/
│   │   └── common_widgets.dart           # ScoreRing, EcoCard, EcoButton, dll
│   └── utils/
│       ├── app_theme.dart                # Tema & warna
│       ├── auth_provider.dart            # Auth state management
│       └── storage_service.dart          # SharedPreferences persistence
└── pubspec.yaml
```

---

## 🎯 Fitur yang Diimplementasi

| Fitur | Status | Keterangan |
|-------|--------|------------|
| Animated Splash Screen | ✅ | Animasi logo scale + fade, tagline, dots loading |
| Onboarding 3 Slide | ✅ | Swipe gesture, skip, hanya tampil sekali |
| Landing Page | ✅ | Entry point Daftar / Masuk |
| Auth (Login & Register) | ✅ | Validasi email & password, session persist |
| FOMO Purchase Detector | ✅ | 10 pertanyaan reflektif → Need Score + FOMO Score |
| Smart Wishlist + Cooling Period | ✅ | Timer 1/3/7 hari, unlock untuk putuskan |
| Shopping Impact Tracker (JejakBelanja) | ✅ | Estimasi sampah kemasan, Sustainability Score |
| Eco Alternative Recommendation | ✅ | Per kategori produk, Buy or Borrow |
| Monthly Consumption Report | ✅ | KPI cards + Pie chart kategori + Analitik |
| Data Persistence | ✅ | SharedPreferences — data tersimpan lokal |
| Device Preview | ✅ | Multi-device UI testing di browser |

---

## 🚀 Cara Menjalankan

### Prerequisite
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code dengan Flutter extension
- Developer Mode aktif (Windows)

### Langkah

```bash
# 1. Clone repository
git clone https://github.com/deazasqiapasaribumalau/ecopause-smart-purchase-decision-system.git

# 2. Masuk ke folder project
cd ecopause-smart-purchase-decision-system

# 3. Install dependencies
flutter pub get

# 4. Jalankan di Chrome (dengan Device Preview)
flutter run -d chrome

# 5. Jalankan di Windows desktop
flutter run -d windows

# Build APK Android
flutter build apk --release
```

### Catatan Path (Windows)
Jika Flutter terinstall di folder dengan spasi (misal `C:\Users\Nama Lengkap\flutter`), jalankan ini dulu di setiap sesi PowerShell:
```powershell
$env:Path = "C:\flutter\bin;" + $env:Path
$env:PUB_CACHE = "C:\pub-cache"
```

---

## 🧭 Alur Navigasi App

```
SplashScreen (animasi ~2.4 detik)
    │
    ├── sudah login? ──────────────── HomeScreen
    │
    ├── belum onboarding? ─────────── OnboardingScreen (3 slide)
    │                                      └── LandingScreen
    │                                           ├── [Daftar] → RegisterScreen
    │                                           └── [Masuk]  → LoginScreen
    │
    └── sudah onboarding? ─────────── LoginScreen
```

---

## 🧠 Logika FOMO Score

Pengguna menjawab 10 pertanyaan dengan Ya/Tidak:

| Pertanyaan | "Ya" berarti... |
|------------|-----------------|
| Apakah benar-benar butuh? | Butuh (Need ↑) |
| Sudah punya barang serupa? | FOMO (FOMO ↑) |
| Karena tren / viral? | FOMO (FOMO ↑) |
| Terpengaruh influencer? | FOMO (FOMO ↑) |
| Karena diskon / flash sale? | FOMO (FOMO ↑) |
| Sudah direncanakan > 1 minggu? | Butuh (Need ↑) |
| Sesuai anggaran? | Butuh (Need ↑) |
| Pernah menyesal beli sejenis? | FOMO (FOMO ↑) |
| Yakin dipakai 30 kali? | Butuh (Need ↑) |
| Mempertimbangkan dampak lingkungan? | Butuh (Need ↑) |

**Rekomendasi Akhir:**
- Need Score ≥ 60 → ✅ Layak Dibeli
- FOMO Score ≥ 60 → 🚫 Lebih Baik Dilewati
- Keduanya sedang → ⏳ Masuk Wishlist dulu

---

## 📦 Dependencies

```yaml
google_fonts: ^6.1.0        # Tipografi Nunito
shared_preferences: ^2.2.2  # Penyimpanan data lokal
fl_chart: ^0.68.0           # Pie chart di laporan
intl: ^0.20.2               # Format tanggal
uuid: ^4.3.3                # ID unik untuk setiap item
crypto: ^3.0.3              # Hash password
image_picker: ^1.2.2        # Upload foto profil
path_provider: ^2.1.0       # Akses path lokal
device_preview: ^1.1.0      # Multi-device UI preview
```

---

## 👥 Tim

| Nama | NIM |
|------|-----|
| Dea Zasqia Pasaribu Malau | 2308107010004 |
| Tasya Zahrani | 2308107010006 |

**Mata Kuliah:** Pemrograman Berbasis Mobile (PBM)  
**SDG Focus:** SDG 12 — Responsible Consumption and Production
