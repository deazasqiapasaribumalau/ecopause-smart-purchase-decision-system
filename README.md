<div align="center">

# 🌿 EcoPause
### Smart Purchase Decision System

**Think Before You Buy, Think Before You Waste**

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)](https://dart.dev)
[![SDG 12](https://img.shields.io/badge/SDG_12-Responsible_Consumption-BF8B2E)](https://sdgs.un.org/goals/goal12)
[![License](https://img.shields.io/badge/License-Academic-green)](LICENSE)

*Aplikasi mobile Flutter untuk mengevaluasi keputusan pembelian sebelum checkout*

[Fitur](#-fitur) · [Teknologi](#-teknologi) · [Instalasi](#-instalasi) · [Screenshot](#-screenshot) · [Tim](#-tim)

</div>

---

## 📖 Deskripsi Singkat

**EcoPause** adalah aplikasi mobile berbasis Flutter yang membantu pengguna **berhenti sejenak sebelum membeli**. Di era e-commerce dan media sosial, banyak keputusan belanja didorong oleh FOMO (*Fear of Missing Out*) — bukan kebutuhan nyata. Akibatnya, pengeluaran membengkak, barang menumpuk tidak terpakai, dan limbah kemasan terus meningkat.

EcoPause menjawab masalah ini dengan pendekatan reflektif berbasis data: mengevaluasi tingkat kebutuhan vs dorongan impulsif, melacak dampak lingkungan dari setiap pembelian, dan merekomendasikan alternatif yang lebih berkelanjutan.

> 💡 **Mendukung SDG 12 — Responsible Consumption and Production**

---

## 🎯 Tujuan Pengembangan

| # | Tujuan |
|---|--------|
| 1 | Membantu pengguna membedakan **kebutuhan nyata** dari **dorongan FOMO** sebelum checkout |
| 2 | Mengurangi pembelian impulsif melalui mekanisme evaluasi reflektif dan *cooling period* |
| 3 | Meningkatkan kesadaran tentang **dampak lingkungan** dari aktivitas belanja online (sampah kemasan, emisi CO2) |
| 4 | Mendorong pola konsumsi yang lebih bertanggung jawab sesuai target SDG 12 |
| 5 | Memberikan data konsumsi personal yang membantu pengguna menghemat pengeluaran |

---

## ✨ Fitur

### 1. 🔍 FOMO Purchase Detector
Evaluasi keputusan pembelian melalui **10 pertanyaan reflektif** yang menghasilkan dua skor:

- **Need Score (0–100)** — seberapa besar kebutuhan nyata terhadap barang tersebut
- **FOMO Score (0–100)** — seberapa besar dorongan impulsif yang memengaruhi keputusan

| Pertanyaan | Jawaban "Ya" → |
|---|---|
| Apakah benar-benar butuh barang ini? | Need ↑ |
| Sudah punya barang serupa yang masih berfungsi? | FOMO ↑ |
| Membeli karena sedang tren / viral? | FOMO ↑ |
| Terpengaruh iklan atau konten influencer? | FOMO ↑ |
| Alasan utama adalah diskon / flash sale? | FOMO ↑ |
| Sudah direncanakan lebih dari 1 minggu? | Need ↑ |
| Pembelian masih dalam anggaran bulan ini? | Need ↑ |
| Pernah menyesal membeli barang serupa sebelumnya? | FOMO ↑ |
| Yakin akan dipakai minimal 30 kali? | Need ↑ |
| Mempertimbangkan dampak lingkungan? | Need ↑ |

**Rekomendasi akhir:**
- ✅ **Layak Dibeli** — Need Score ≥ 60
- 🚫 **Lebih Baik Dilewati** — FOMO Score ≥ 60
- ⏳ **Masuk Wishlist Dulu** — keduanya di bawah threshold

---

### 2. 📋 Smart Wishlist + Cooling Period
Cegah pembelian impulsif dengan sistem antrian reflektif:

- Tambah item ke wishlist dan pilih durasi *cooling period*: **1 hari / 3 hari / 7 hari**
- Sistem mengunci keputusan selama masa tunggu — item belum bisa dibeli
- Setelah timer habis, item pindah ke tab **Unlocked** dan pengguna bisa memutuskan dengan kepala dingin
- Tersedia tiga tab: **Cooling Period** · **Unlocked** · **Riwayat**

---

### 3. 📦 JejakBelanja — Shopping Impact Tracker
Catat setiap pembelian dan ukur dampak lingkungannya secara otomatis:

- **Estimasi sampah kemasan** (kg) — dihitung dari jumlah paket: `packageCount × 0.3 kg`
- **Estimasi emisi CO2** — `0.6 kg` (regular) / `1.2 kg` (same-day) per pengiriman online; `0.1 kg` untuk offline
- **Sustainability Score (0–100)** — skor keberlanjutan berdasarkan rasio belanja dan pola kemasan

---

### 4. 🌱 Eco Alternative Recommendation
Rekomendasi otomatis alternatif yang lebih ramah lingkungan berdasarkan kategori produk:

| Kategori | Contoh Alternatif |
|---|---|
| Fashion & Pakaian | Thrift shop, brand lokal organik, swap clothing |
| Elektronik & Gadget | Refurbished, sewa gadget, kemasan daur ulang |
| Peralatan Rumah | Pinjam dari tetangga, pasar loak, produk lokal |
| Kecantikan & Skincare | Cruelty-free, kemasan refill, bahan alami lokal |
| Buku & Stationery | E-book, pinjam perpustakaan, stationery daur ulang |

Termasuk saran **Buy or Borrow** untuk kategori tertentu (alat bor, kamera, tenda, buku).

---

### 5. 📊 Monthly Consumption Report
Laporan bulanan lengkap dengan analitik visual:

- **KPI Cards** — total pembelian, total pengeluaran, pembelian yang dibatalkan, sampah dicegah, estimasi penghematan
- **Pie Chart** — distribusi kategori belanja (menggunakan `fl_chart`)
- **Riwayat Evaluasi** — seluruh hasil evaluasi FOMO yang pernah dilakukan

---

### 6. 🔐 Autentikasi Pengguna
Sistem login/register lokal yang aman:

- Registrasi dengan nama, email, dan password
- Password di-*hash* menggunakan **SHA-256** via package `crypto`
- Sesi disimpan di `SharedPreferences` untuk *auto-login*
- Mendukung **multi-user** — data tiap pengguna dipartisi berdasarkan `userId`

---

### 7. 👤 Profil Pengguna
- Edit nama, nomor telepon, dan bio
- Upload **foto profil** dari galeri atau kamera
- Kelola pengaturan notifikasi
- Logout dan manajemen akun

---

### 8. 🎬 Splash Screen & Onboarding
- Animated splash screen dengan animasi scale + fade (~2.4 detik)
- Onboarding 3 slide (tampil hanya sekali saat pertama install) dengan swipe gesture dan tombol skip
- Landing page sebagai titik masuk ke Register atau Login

---

## 🛠 Teknologi

### Framework & Language
| Teknologi | Versi | Keterangan |
|---|---|---|
| Flutter | ≥ 3.0.0 | Cross-platform mobile framework (Android, iOS, Web, Windows) |
| Dart | ≥ 3.0.0 | Bahasa pemrograman utama |

### Library & Package

| Package | Versi | Fungsi |
|---|---|---|
| `google_fonts` | ^6.1.0 | Tipografi Nunito untuk konsistensi UI |
| `shared_preferences` | ^2.2.2 | Penyimpanan data lokal key-value (JSON) |
| `fl_chart` | ^0.68.0 | Pie chart di Monthly Consumption Report |
| `intl` | 0.20.2 | Format tanggal dan mata uang (IDR) |
| `uuid` | ^4.3.3 | Generate ID unik (UUID v4) untuk setiap record |
| `crypto` | ^3.0.3 | Hashing password SHA-256 |
| `image_picker` | ^1.2.2 | Ambil foto profil/produk dari galeri atau kamera |
| `path_provider` | ^2.1.0 | Akses direktori lokal untuk simpan gambar |
| `device_preview` | ^1.3.1 | Multi-device UI preview saat development |

### Komponen Utama

| Komponen | Deskripsi |
|---|---|
| `AuthProvider` | State management sesi pengguna berbasis `ChangeNotifier` |
| `StorageService` | Layer abstraksi CRUD ke `SharedPreferences` |
| `ScoreRing` | Widget custom circular progress untuk visualisasi skor |
| `EcoCard` / `EcoButton` | Widget reusable untuk konsistensi desain |

---

## 🗄 Struktur Data

EcoPause tidak menggunakan database relasional atau backend. Semua data tersimpan **lokal di perangkat** menggunakan `SharedPreferences` dalam format JSON, dipartisi per `userId`.

### Model Data

#### `AppUser`
```
id            String    UUID unik pengguna
name          String    Nama lengkap
email         String    Email (unik, digunakan sebagai login)
passwordHash  String    SHA-256 hash dari password
createdAt     DateTime  Waktu registrasi
notifEnabled  bool      Preferensi notifikasi
phone         String?   Nomor telepon (opsional)
bio           String?   Bio singkat (opsional)
imagePath     String?   Path foto profil lokal
```

#### `FomoEvaluation`
```
id          String              UUID evaluasi
userId      String              Relasi ke AppUser
itemName    String              Nama produk yang dievaluasi
category    String              Kategori produk
price       double              Harga estimasi
needScore   int (0–100)         Skor kebutuhan
fomoScore   int (0–100)         Skor FOMO / impulsif
decision    String              "buy" | "skip" | "wishlist"
answers     Map<String, bool>   10 jawaban Ya/Tidak
date        DateTime            Tanggal evaluasi
imagePath   String?             Foto produk (opsional)
```

#### `WishlistItem`
```
id           String    UUID item
userId       String    Relasi ke AppUser
itemName     String    Nama produk
category     String    Kategori produk
price        double    Harga estimasi
addedAt      DateTime  Waktu ditambahkan ke wishlist
coolingDays  int       Durasi cooling period (1 / 3 / 7)
isBought     bool      Sudah dibeli
isSkipped    bool      Dilewati setelah unlock
notified     bool      Sudah mendapat notifikasi unlock
imagePath    String?   Foto produk (opsional)
```

#### `ShoppingLog`
```
id            String    UUID log
userId        String    Relasi ke AppUser
itemName      String    Nama produk yang dibeli
category      String    Kategori produk
price         double    Harga aktual
packageCount  int       Jumlah paket/kemasan
isOnline      bool      Belanja online atau offline
deliveryType  String    "regular" | "sameday" | "instant"
date          DateTime  Tanggal pembelian
imagePath     String?   Foto produk (opsional)
```

> **Computed fields:** `wasteKg = packageCount × 0.3`, `co2Emission = 0.6 kg` (regular online) / `1.2 kg` (same-day) / `0.1 kg` (offline)

### Skema Penyimpanan SharedPreferences

```
users                    → List<AppUser> (JSON)
ecopause_session         → userId sesi aktif
evaluations_{userId}     → List<FomoEvaluation> (JSON)
wishlist_{userId}        → List<WishlistItem> (JSON)
shopping_logs_{userId}   → List<ShoppingLog> (JSON)
onboarding_done          → bool
```

---

## 🚀 Instalasi dan Menjalankan

### Prasyarat

- Flutter SDK ≥ 3.0.0 → [Panduan instalasi Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK ≥ 3.0.0 (sudah termasuk dalam Flutter)
- Android Studio atau VS Code dengan ekstensi Flutter & Dart
- Git
- Untuk Android: Android Emulator atau perangkat fisik dengan USB Debugging aktif
- Untuk Windows: Developer Mode aktif

### Langkah Instalasi

```bash
# 1. Clone repository
git clone https://github.com/deazasqiapasaribumalau/ecopause-smart-purchase-decision-system.git

# 2. Masuk ke direktori project
cd ecopause-smart-purchase-decision-system

# 3. Install semua dependencies
flutter pub get

# 4. Verifikasi setup Flutter
flutter doctor
```

### Menjalankan Aplikasi

```bash
# Jalankan di Chrome (dengan Device Preview aktif)
flutter run -d chrome

# Jalankan di Windows Desktop
flutter run -d windows

# Jalankan di Android Emulator
flutter run -d emulator-5554

# Jalankan di perangkat Android fisik (pastikan USB Debugging aktif)
flutter run -d <device-id>
```

> Gunakan `flutter devices` untuk melihat daftar perangkat yang tersedia.

### Build Rilis

```bash
# Build APK Android (rilis)
flutter build apk --release

# Build APK Android per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi --release

# Build App Bundle (untuk Google Play Store)
flutter build appbundle --release

# Build Windows Desktop
flutter build windows --release
```

### Catatan Khusus Windows

Jika Flutter terinstal di folder yang mengandung spasi (contoh: `C:\Users\Nama Lengkap\flutter`), jalankan perintah berikut di setiap sesi PowerShell baru sebelum menggunakan Flutter:

```powershell
$env:Path = "C:\flutter\bin;" + $env:Path
$env:PUB_CACHE = "C:\pub-cache"
```

### Alur Navigasi Aplikasi

```
SplashScreen (~2.4 detik animasi)
    │
    ├── [Sudah login] ──────────────────── HomeScreen (Dashboard)
    │                                           ├── FOMO Detector
    │                                           ├── Wishlist
    │                                           ├── JejakBelanja
    │                                           ├── Report
    │                                           └── Profil
    │
    ├── [Belum onboarding] ─────────────── OnboardingScreen (3 slide)
    │                                           └── LandingScreen
    │                                                ├── [Daftar] → RegisterScreen
    │                                                └── [Masuk]  → LoginScreen
    │
    └── [Sudah onboarding, belum login] ── LoginScreen
```

---

## 📱 Screenshot

> *Screenshot diambil menggunakan Device Preview pada Chrome. Tampilan dapat bervariasi antar perangkat.*

### Onboarding & Autentikasi

| Onboarding 1 | Onboarding 2 | Onboarding 3 | Landing Page |
|:---:|:---:|:---:|:---:|
| ![Onboarding 1](https://i.ibb.co.com/ZzDPcJk1/Screenshot-2026-06-26-151152.png) | ![Onboarding 2](https://i.ibb.co.com/zTF5mZz4/Screenshot-2026-06-26-151209.png) | ![Onboarding 3](https://i.ibb.co.com/R4pPF22b/Screenshot-2026-06-26-151220.png) | ![Landing Page](https://i.ibb.co.com/MyVJhbmh/Screenshot-2026-06-26-151229.png) |

| Login | Register | Home Dashboard | Detail Belanja |
|:---:|:---:|:---:|:---:|
| ![Login](https://i.ibb.co.com/HTjP9THn/Screenshot-2026-06-26-151243.png) | ![Register](https://i.ibb.co.com/ZRCpGLP2/Screenshot-2026-06-26-151251.png) | ![Home Dashboard](https://i.ibb.co.com/mrRJzhTX/Screenshot-2026-06-26-151324.png) | ![Detail Belanja](https://i.ibb.co.com/d0k91Hjf/Screenshot-2026-06-26-151335.png) |

### Fitur Utama

| FOMO Detector | Hasil Evaluasi | Smart Wishlist | Wishlist Unlocked |
|:---:|:---:|:---:|:---:|
| ![FOMO Detector](https://i.ibb.co.com/bMF4ZgQ4/Screenshot-2026-06-26-151408.png) | ![Hasil Evaluasi](https://i.ibb.co.com/kgQWpMmq/Screenshot-2026-06-26-151436.png) | ![Smart Wishlist](https://i.ibb.co.com/gbMgm6Dp/Screenshot-2026-06-26-151448.png) | ![Wishlist Unlocked](https://i.ibb.co.com/fYVdWmgF/Screenshot-2026-06-26-151455.png) |

| JejakBelanja | Detail JejakBelanja | Monthly Report | Monthly Report 2 |
|:---:|:---:|:---:|:---:|
| ![JejakBelanja](https://i.ibb.co.com/Q3N7pvFm/Screenshot-2026-06-26-151504.png) | ![Detail JejakBelanja](https://i.ibb.co.com/VYvDLq7F/Screenshot-2026-06-26-151513.png) | ![Monthly Report](https://i.ibb.co.com/MxKN7dJc/Screenshot-2026-06-26-151520.png) | ![Monthly Report 2](https://i.ibb.co.com/S4tZ1f5r/Screenshot-2026-06-26-151529.png) |

| Profil | Splash Screen |
|:---:|:---:|
| ![Profil](https://i.ibb.co.com/HDMPmVJh/Screenshot-2026-06-26-151537.png) | ![Splash Screen](https://i.ibb.co.com/wFr5HZ7Y/Screenshot-2026-06-26-151620.png) |

---

## 📁 Struktur Project

```
ecopause/
├── lib/
│   ├── main.dart                          # Entry point + DevicePreview
│   ├── models/
│   │   └── models.dart                   # AppUser, FomoEvaluation, WishlistItem, ShoppingLog, AppNotification
│   ├── screens/
│   │   ├── splash_screen.dart            # Animated splash + routing logic
│   │   ├── onboarding_screen.dart        # 3-slide onboarding + landing page
│   │   ├── login_screen.dart             # Login dengan validasi
│   │   ├── register_screen.dart          # Registrasi akun baru
│   │   ├── home_screen.dart              # Dashboard + Bottom Navigation (5 tab)
│   │   ├── fomo_detector_screen.dart     # Form produk + 10 pertanyaan evaluasi
│   │   ├── fomo_result_screen.dart       # Hasil Need Score + FOMO Score + rekomendasi
│   │   ├── wishlist_screen.dart          # Smart Wishlist + Cooling Period timer
│   │   ├── jejak_belanja_screen.dart     # Shopping Impact Tracker + log pembelian
│   │   ├── report_screen.dart            # Monthly Consumption Report + Pie Chart
│   │   ├── profile_screen.dart           # Profil pengguna + pengaturan
│   │   ├── shopping_detail_screen.dart   # Detail item belanja
│   │   └── evaluation_detail_screen.dart # Detail hasil evaluasi FOMO
│   ├── widgets/
│   │   └── common_widgets.dart           # ScoreRing, EcoCard, EcoButton, dan widget reusable lainnya
│   └── utils/
│       ├── app_theme.dart                # Tema, palet warna, dan typography
│       ├── auth_provider.dart            # Session management (ChangeNotifier)
│       └── storage_service.dart          # Abstraksi CRUD ke SharedPreferences
├── android/                              # Konfigurasi platform Android
├── web/                                  # Konfigurasi platform Web
├── windows/                              # Konfigurasi platform Windows
├── pubspec.yaml                          # Konfigurasi project & dependencies
└── README.md
```

---

## 👥 Tim

| Nama | NIM | Peran |
|---|---|---|
| Dea Zasqia Pasaribu Malau | 2308107010004 | Flutter Developer |
| Tasya Zahrani | 2308107010006 | Flutter Developer |

**Mata Kuliah:** Pemrograman Berbasis Mobile (PBM)  
**Institusi:** Universitas Syiah Kuala  
**Tahun:** 2025  
**SDG Focus:** SDG 12 — Responsible Consumption and Production

---

<div align="center">

*🌿 EcoPause — karena setiap keputusan belanja yang dipikirkan dua kali adalah langkah kecil menuju planet yang lebih sehat.*

</div>