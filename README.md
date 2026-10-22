# BandungHub 🌿 — Smart Travel Companion & Tourism Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-114%2F114%20Passing%20(100%25)-success)](https://flutter.dev)
[![Linter](https://img.shields.io/badge/flutter_analyze-0%20Issues-brightgreen)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-blue.svg)]()

> **Projek Akhir Mata Kuliah Pemrograman Aplikasi Mobile (PAM)**  
> **Aplikasi Wisata Pintar Kota Bandung & Sekitarnya (Offline-First, OpenStreetMap, AI Assistant, & Smart Itinerary Planner)**

---

## 📌 Ringkasan Eksekutif (Executive Summary)

**BandungHub** adalah aplikasi *smart travel companion* komprehensif yang dirancang untuk wisatawan yang berkunjung ke kawasan metropolitan Bandung Raya (Kota Bandung, Lembang / Bandung Barat, Ciwidey / Kab. Bandung). BandungHub menjawab permasalahan nyata wisatawan seperti hilangnya sinyal internet di dataran tinggi, ketidaktahuan rute terdekat, perencanaan anggaran tiket masuk, serta kebutuhan panduan wisata berbasis AI lokal.

Aplikasi dibangun menggunakan **Flutter** dengan pendekatan arsitektur bersih (*Clean Architecture*), mematuhi prinsip **Offline-First**, mengintegrasikan peta interaktif **OpenStreetMap (100% tanpa API key berbayar)**, keamanan biometrik & PIN, serta telah menyelesaikan **14 dari 14 fase implementasi** dengan **114 unit & widget test passing (100%)** dan **0 static analysis issues** (`flutter analyze`).

---

## 🏛️ Arsitektur & Teknologi (Tech Stack)

| Komponen | Teknologi / Library | Catatan Implementasi |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x (Dart 3.x) | Cross-platform Material 3 responsive design |
| **State Management** | `ChangeNotifier` & `ValueNotifier` | Reaktif, efisien memori, tanpa overhead boilerplate berat |
| **Local Storage** | `sqflite` + `shared_preferences` | Dual-engine storage: SQLite relational + key-value caching |
| **Peta & Navigasi** | `flutter_map` + OpenStreetMap | 100% FOSS, zero Google Cloud API billing dependency |
| **Keamanan & Auth** | `local_auth` + SHA-256 Hashing | Biometrik (Fingerprint/Face), PIN 6-digit, verifikasi integritas data |
| **Notifikasi** | `flutter_local_notifications` | Pengingat jadwal kunjungan, countdown destinasi, demo triggers |
| **Ekspor & Berbagi** | `share_plus` | Multi-format: Teks WhatsApp, Dokumen Cetak/PDF (HTML), JSON Backup |
| **Offline Sync** | `OfflineSyncRepository` | Antrean perubahan offline (*sync queue*) dengan simulasi demo mode |

---

## 📋 Matriks Pemenuhan 14 Fase Projek (Rubric Compliance Matrix)

| Fase | Nama Modul / Fitur | Deskripsi & Bukti Implementasi | File Utama & Test Suite |
| :---: | :--- | :--- | :--- |
| **01** | **Design System & Base Theme** | Palet warna khas Parahyangan (Teal & Amber), tipografi adaptif, radius modern, Material 3. | `core/theme/app_colors.dart`<br>`test/phase1_test.dart` |
| **02** | **Autentikasi & Keamanan** | Login/Register, sesi Tamu (*Guest*), otentikasi biometrik, PIN 6-digit keamanan, enkripsi sesi. | `data/repositories/auth_repository.dart`<br>`test/phase2_test.dart` |
| **03** | **Katalog Destinasi & Pencarian** | 13 destinasi Bandung terlengkap, pencarian real-time, filter kategori (Alam, Kuliner, Sejarah, Keluarga, Hiburan), slider rentang harga tiket. | `data/repositories/destination_repository.dart`<br>`test/phase3_test.dart` |
| **04** | **Sistem Rekomendasi Pintar** | Filter preferensi wisata berdasarkan budget, kategori favorit, kuis rekomendasi persona, dan personalisasi beranda. | `features/recommendations/`<br>`test/phase4_test.dart` |
| **05** | **Smart Itinerary & SQLite Storage** | Perencana jadwal perjalanan interaktif, estimasi total budget tiket, drag-and-drop reorder, verifikasi hash SHA-256 anti-tamper. | `data/repositories/itinerary_repository.dart`<br>`test/phase5_test.dart` |
| **06** | **Peta Interaktif OpenStreetMap** | Visualisasi lokasi wisata di peta Bandung, marker interaktif, rute multi-stop, tombol navigasi eksternal (Google Maps/Waze). | `features/map/screens/destination_map_screen.dart`<br>`test/phase6_test.dart` |
| **07** | **AI Travel Assistant (Kang Bandung)** | Asisten virtual pariwisata Bandung dengan *rule-based heuristic engine*, rekomendasi kuliner, tips cuaca, & bahasa Sunda ramah. | `features/recommendations/screens/ai_chat_screen.dart`<br>`test/phase7_test.dart` |
| **08** | **Gamifikasi & Kuis Wisata Bandung** | Kuis trivia seputar sejarah, budaya, dan kuliner Bandung, sistem skor, lencana prestasi (*badges*), dan leaderboard lokal. | `features/quiz/`<br>`test/phase8_test.dart` |
| **09** | **Aksesibilitas & Mode Gelap (Dark Mode)** | Mode Gelap (*Dark Theme*) otomatis & manual, kontras tinggi, semantic accessibility (*A11y*), target sentuh minimal 48x48 dp. | `data/repositories/theme_repository.dart`<br>`test/phase9_test.dart` |
| **10** | **Notifikasi & Pengingat Perjalanan** | Pengingat jadwal kunjungan otomatis, hitung mundur hari liburan, notification center dengan filter chip, dan pengujian demo. | `data/repositories/notification_repository.dart`<br>`test/phase10_test.dart` |
| **11** | **Ekspor & Berbagi Itinerary** | Ekspor rencana perjalanan ke format pesan WhatsApp/Telegram, dokumen cetak/PDF (HTML view), dan backup JSON dengan kode hash. | `services/itinerary_export_service.dart`<br>`test/phase11_test.dart` |
| **12** | **Review, Rating & Galeri Pengguna** | Ulasan wisatawan, rating bintang interaktif (1-5★), breakdown statistik ulasan, galeri foto komunitas, dan tombol like ulasan. | `data/repositories/review_repository.dart`<br>`test/phase12_test.dart` |
| **13** | **Offline Sync & Deteksi Jaringan** | Arsitektur *offline-first*, antrean aksi offline (*sync queue*), banner peringatan offline otomatis, sakelar simulasi offline, dan manajemen cache. | `data/repositories/offline_sync_repository.dart`<br>`test/phase13_test.dart` |
| **14** | **Kesan & Pesan Kuliah & Dokumentasi** | Form evaluasi & refleksi akademik perkuliahan PAM, pemilihan topik paling berkesan, salin ringkasan evaluasi, dan dokumentasi lengkap. | `features/academic/screens/course_feedback_screen.dart`<br>`test/phase14_test.dart` |

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── core/
│   ├── constants/            # Konstanta aplikasi (nama, versi, tagar)
│   └── theme/                # Desain sistem, AppColors (Teal/Amber), AppTheme (Light & Dark)
├── data/
│   ├── sources/              # Dataset 38 destinasi resmi Bandung Google Maps 2026
│   └── repositories/         # State managers & repositories
│       ├── auth_repository.dart
│       ├── destination_repository.dart
│       ├── itinerary_repository.dart
│       ├── notification_repository.dart
│       ├── offline_sync_repository.dart
│       ├── review_repository.dart
│       └── theme_repository.dart
├── features/
│   ├── academic/             # Phase 14: Form Evaluasi & Kesan Pesan Kuliah
│   ├── auth/                 # Phase 2: Login, Register, PIN Lock, Biometrik
│   ├── destinations/         # Phase 3 & 12: Katalog, Detail, Reviews, Rating, Galeri
│   ├── home/                 # Beranda, Header, Banner Offline, Rekomendasi
│   ├── itinerary/            # Phase 5 & 11: Itinerary Planner, SQLite, Ekspor WhatsApp/PDF
│   ├── map/                  # Phase 6: OpenStreetMap, Markers, Routing
│   ├── notifications/        # Phase 10: Notification Center & Pengingat
│   ├── offline/              # Phase 13: Banner Offline & Pusat Sinkronisasi
│   ├── profile/              # Profil, Pengaturan PIN, Switcher Tema, Shortcut Fitur
│   ├── quiz/                 # Phase 8: Gamifikasi Trivia Bandung
│   └── recommendations/      # Phase 4 & 7: Form Preferensi & AI Assistant Kang Bandung
├── models/                   # Data classes: Destination, Itinerary, Review, Notification, SyncQueue
├── services/                 # Helper services: Notification, Export, Connectivity
├── shared/widgets/           # Widget reusable: DestinationCard, EmptyView, ErrorView, LoadingView
└── main.dart                 # Entry point aplikasi & inisialisasi repositories
```

---

## 🧪 Pengujian & Verifikasi Kualitas (Quality Assurance)

Proyek ini telah divalidasi dengan pengujian otomatis (*Automated Testing*) yang ketat:

### 1. Menjalankan Semua Unit & Widget Test (114/114 Passed)
```bash
flutter test
```
*Hasil:*
```text
00:10 +114: All tests passed!
```

### 2. Menjalankan Uji Analisis Statis (0 Issues)
```bash
flutter analyze
```
*Hasil:*
```text
Analyzing projek_akhir...
No issues found! (ran in 2.0s)
```

---

## 🚀 Panduan Menjalankan Aplikasi

### Prasyarat:
- Flutter SDK (>= 3.0.0)
- Android SDK (API level 21+)
- Perangkat Android fisik atau Emulator

### Langkah-langkah:
1. **Clone repositori dan masuk ke direktori:**
   ```bash
   cd projek_akhir
   ```
2. **Unduh dependensi pub:**
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi di perangkat/emulator:**
   ```bash
   flutter run
   ```
4. **Kompilasi APK Rilis (Release Build):**
   ```bash
   flutter build apk --release
   ```
   *File APK rilis akan berada di:* `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎓 Refleksi & Kesan Pesan Perkuliahan (Phase 14)

Form evaluasi ini juga dapat diakses dan diisi langsung secara interaktif di dalam aplikasi melalui menu **Profil & Pengaturan ➔ Kesan & Pesan Kuliah**.

- **Mata Kuliah:** Pemrograman Aplikasi Mobile (PAM)
- **Topik Paling Berkesan:**
  1. *Clean Architecture & Reactive State Management* di Flutter.
  2. *Offline-First Architecture* dengan SQLite & Antrean Sinkronisasi.
  3. Integrasi *OpenStreetMap* tanpa API key berbayar.
  4. Pengamanan otentikasi menggunakan Sensor Biometrik & PIN 6-digit.
  5. Pembuatan *Automated Unit & Widget Tests* hingga mencapai 100% pass rate.
- **Kesan Perkuliahan:**
  > "Mata kuliah Pemrograman Aplikasi Mobile ini memberikan pemahaman mendalam mengenai pengembangan aplikasi mobile modern berstandar industri. Penyelesaian Projek Akhir BandungHub dari Phase 1 hingga Phase 14 membuktikan bahwa aplikasi yang tangguh, responsif, dan ramah pengguna dapat dibangun dengan arsitektur yang terstruktur rapi."
- **Pesan & Saran:**
  > "Materi yang diajarkan sudah sangat aplikatif dan relevan dengan industri. Saran untuk pengembangan kurikulum ke depan adalah penambahan materi CI/CD pipeline otomatis dengan GitHub Actions untuk kompilasi APK/AAB serta eksplorasi Flutter Multiplatform (Web & Desktop)."

---

© 2026 **BandungHub Team** — Final Project Pemrograman Aplikasi Mobile.