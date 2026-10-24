# BandungHub 🌿 : Smart Travel Companion & Tourism Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Blockchain](https://img.shields.io/badge/Blockchain-SHA--256%20Review%20Ledger-6f42c1?logo=blockchain&logoColor=white)](https://github.com/maulfx/BandungHub)
[![AI](https://img.shields.io/badge/AI-Google%20Gemini%203.5%2F3.8-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Forex](https://img.shields.io/badge/Forex-Live%20Exchange%20Rates-0D9488?logo=cashapp&logoColor=white)](https://open.er-api.com)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(16%2F16)-success)](https://flutter.dev)
[![Linter](https://img.shields.io/badge/flutter_analyze-0%20Issues-brightgreen)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-blue.svg)]()

> **Projek Akhir Mata Kuliah Pemrograman Aplikasi Mobile (PAM)**  
> **Aplikasi Wisata Pintar Bandung Raya (Offline-First, OpenStreetMap, Review Blockchain Ledger, AI Assistant Kang Bandung, Bank-Style App Lock, Live Currency Converter, & Smart Itinerary Planner)**

---

## 📌 Ringkasan Eksekutif (Executive Summary)

**BandungHub** adalah aplikasi panduan wisata komprehensif (*smart travel companion*) yang dirancang khusus untuk wisatawan yang menjelajahi kawasan metropolitan Bandung Raya (Kota Bandung, Lembang / Bandung Barat, Ciwidey / Kab. Bandung, dan Cimahi). BandungHub menjawab kendala nyata wisatawan seperti hilangnya sinyal seluler di perbukitan, ketidaktahuan rute terdekat, perencanaan estimasi budget tiket masuk, maraknya pemalsuan ulasan wisata, serta kebutuhan panduan lokal interaktif.

Aplikasi dibangun menggunakan **Flutter** dengan pendekatan arsitektur bersih (*Clean Architecture*), mematuhi prinsip **Offline-First**, mengintegrasikan peta interaktif **OpenStreetMap (100% bebas API key berbayar)** tanpa batasan rute navigasi dari luar kota, asisten AI **Kang Bandung** dengan model Google Gemini dan pelindung batasan domain (*Domain Guardrails*), inovasi **Review Blockchain Ledger** berbasis SHA-256 anti-manipulasi data, sistem keamanan **Kunci Aplikasi Ala Bank (*Bank-Style App Lock*)** dengan sensor biometrik dan PIN 6 digit keypad, **Konverter Kurs Valuta Asing Real-Time (*Live Exchange Rates*)**, pengelolaan avatar profil via Kamera/Galeri ke database SQLite, serta mini game arkade **Bocchi Jumpy** dengan kontrol layar sentuh.

---

## 🏛️ Arsitektur & Teknologi (Tech Stack)

| Komponen | Teknologi / Library | Catatan Implementasi |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x (Dart 3.x) | Desain Material 3 adaptif, responsif ponsel cerdas, bebas AI-slop |
| **State Management** | `ChangeNotifier` & `ValueNotifier` | Reaktif, efisien memori, tanpa overhead boilerplate berlebih |
| **Local Storage** | `sqflite` + `shared_preferences` | Dual-engine storage: SQLite relasional + key-value caching offline |
| **Review Blockchain** | `crypto` (SHA-256 Hash Chaining) | Buku besar ulasan terenkripsi berantai, Genesis Block #0, audit integritas live & simulasi manipulasi |
| **Peta & Navigasi** | `flutter_map` + OpenStreetMap | 100% FOSS, tanpa ketergantungan tagihan Google Cloud Maps API, rute fleksibel dari dalam maupun luar kota |
| **AI Travel Assistant** | Google Gemini REST API + Heuristik | Model `gemini-3.5-flash` / `gemini-3.8-flash` + Smart Heuristic Engine, dilengkapi Guardrails anti-out-of-scope |
| **Keamanan & Auth** | `local_auth` + SHA-256 Checksum | Keamanan Ala Bank (*Bank-Style App Lock*): Sensor Biometrik (Fingerprint/Face ID), PIN 6-digit keypad, dan kunci otomatis saat aplikasi di latar belakang |
| **Kurs & Konverter** | Open Exchange API (`open.er-api.com`) | Kurs valuta asing real-time (USD, EUR, SGD, MYR, JPY, AUD, CNY, SAR, GBP ke IDR) + offline cache & konversi zona waktu |
| **Kamera & Media** | `image_picker` + SQLite Base64 | Pengambilan foto profil langsung dari Galeri atau Kamera perangkat dan tersimpan di database lokal |
| **Notifikasi & Alarm** | `flutter_local_notifications` | Android Exact Alarm (`exactAllowWhileIdle`), ringtone khusus, dan Notification Center |
| **Ekspor & Berbagi** | `share_plus` | Multi-format: Teks WhatsApp, Dokumen Cetak/PDF (HTML view), dan Backup JSON |
| **Offline Sync** | `OfflineSyncRepository` | Antrean aksi offline (*sync queue*) dengan deteksi jaringan otomatis |
| **Gamifikasi** | Custom Canvas Physics | Mini Game Arkade *Bocchi Jumpy* (kontrol touchscreen & drag) + Kuis Trivia Budaya Sunda |
| **Ikon Aplikasi** | Kustom Mipmap Launcher Icon | Ikon aplikasi khas daun teh hijau Parahyangan dan siluet pegunungan Tangkuban Perahu |

---

## 🏦 Keamanan Sesi Ala Bank (Bank-Style App Lock)

Untuk memberikan perlindungan privasi rencana liburan dan data pribadi pengguna, BandungHub mengadopsi mekanisme gerbang keamanan aplikasi perbankan modern (seperti BCA, Livin' Mandiri, dan Jenius):

1. **Sesi Tersimpan Otomatis**:
   - Setelah pengguna masuk dengan email & sandi atau mendaftar, sesi akun tersimpan secara aman di database lokal SQLite dan secure storage.
2. **Gerbang Akses Cepat Biometrik & PIN (BankAppLockScreen)**:
   - Saat pengguna keluar dan membuka kembali aplikasi, BandungHub tidak meminta pengetikan ulang email dan kata sandi panjang.
   - Aplikasi otomatis menampilkan **BankAppLockScreen**:
     - Salam personal (*"Selamat Datang Kembali, [Nama]"*) dan avatar profil pengguna.
     - **Prompt Biometrik Otomatis**: Meminta pemindaian sidik jari (*fingerprint*) atau wajah (*face ID*) secara instan pada saat halaman terbuka.
     - **Keypad 6-Digit PIN**: Keypad numerik interaktif untuk membuka kunci dengan PIN keamanan.
     - Tombol **Ganti Akun**: Memungkinkan pengguna beralih ke akun email lain kapan saja.
3. **Penguncian Latar Belakang (Background Inactivity Lock)**:
   - Dilengkapi `WidgetsBindingObserver` dengan batas toleransi 2 menit di latar belakang (*background timeout*). Sesi terkunci kembali secara otomatis jika aplikasi ditinggalkan, tanpa mengganggu proses pemilihan foto dari galeri/kamera.
4. **Keluar Bersih (*Clean Logout*)**:
   - Tombol keluar akun di profil dan lock screen secara langsung menghapus tumpukan rute (*navigation stack*) dan mengembalikan pengguna ke layar login awal.
   - Mode Tamu (*Guest Mode*) telah dieliminasi secara total untuk menjamin integritas data dan keamanan sesi pengguna.

---

## 💱 Konverter Valuta Asing Real-Time & Zona Waktu

Fitur **Konverter Wisatawan** membantu wisatawan mancanegara dan domestik menghitung pengeluaran liburan di Bandung Raya:

1. **Kurs Pasar Real-Time (Live)**:
   - Terhubung langsung ke API valuta asing global (`open.er-api.com`) untuk menyajikan nilai tukar terkini dari 10 mata uang dunia terhadap Rupiah (IDR): USD, EUR, SGD, MYR, JPY, AUD, CNY, SAR, GBP.
   - Dilengkapi kartu status indikator hijau (*"Kurs Pasar Real-Time"*) dan tanggal/jam pembaruan data.
   - Tombol **Refresh** untuk menyegarkan kurs pasar seketika.
2. **Offline-First Resilience**:
   - Nilai tukar terakhir yang berhasil diambil disimpan otomatis di `SharedPreferences`. Jika perangkat tidak memiliki koneksi internet di lokasi wisata, aplikasi tetap dapat menghitung estimasi konversi dengan data kurs tersimpan.
3. **Kalkulator Zona Waktu**:
   - Konversi waktu operasional destinasi wisata di Bandung (WIB / UTC+7) ke 10 zona waktu wisatawan (WITA, WIT, SGT, JST, AEST, AST, CET, GMT, EST).

---

## ⛓️ Inovasi Utama: Review Blockchain Ledger

Untuk mengatasi maraknya ulasan palsu dan manipulasi rating tempat wisata, BandungHub memperkenalkan sistem **Review Blockchain Ledger** lokal:

```
[Blok #0: Genesis Block]  <--- Hash: e8c2...
         ▲
         │ (previousHash)
[Blok #1: Ulasan Kawah Putih] <--- Hash: 7b4a... (SHA-256 dari seluruh isi ulasan)
         ▲
         │ (previousHash)
[Blok #2: Ulasan Gedung Sate] <--- Hash: d91f...
```

### Karakteristik & Fitur Blockchain:
1. **Genesis Block (Blok #0)**: Diinisialisasi otomatis oleh `Sistem Konsensus BandungHub` sebagai fondasi rantai kepercayaan.
2. **Keterikatan Kriptografis (SHA-256)**: Setiap ulasan yang dikirim pengguna dihitung hash deterministiknya berdasarkan indeks, waktu, ID destinasi, pengulas, rating bintang, komentar, dan hash blok sebelumnya.
3. **Audit Integritas Real-Time (`auditChain()`)**: Memverifikasi dua lapis keamanan:
   - Keutuhan keterikatan rantai (`current.previousHash == previous.hash`).
   - Keaslian data ulasan (`current.hash == reCalculatedHash`).
4. **Ledger Inspector & Tamper Simulation**:
   - Wisatawan dan penguji dapat melihat seluruh buku besar rantai blok ulasan di modal dialog.
   - Disediakan tombol **Simulasi Manipulasi** untuk membuktikan bahwa perubahan 1 huruf saja pada database akan langsung terdeteksi sebagai rantai rusak (*Tampered Block*).
   - Disediakan tombol **Pulihkan Rantai** untuk merestorasi blok ke data asli terverifikasi.

---

## 🤖 Asisten Perjalanan AI: Kang Bandung & Domain Guardrails

Kang Bandung adalah pemandu virtual resmi BandungHub yang menggabungkan keramahan budaya Sunda (*Someah Hade ka Semah*) dengan kecerdasan generasi terkini Google Gemini:

- **Dwi-Mesin Cerdas**: Bekerja via REST API Google Gemini saat online, dan otomatis beralih ke *Rule-Based Heuristic NLP Engine* saat offline tanpa koneksi internet.
- **Domain Guardrails (Batasan Konteks Ketat)**:
  - Kang Bandung secara ketat dibatasi **hanya melayani topik pariwisata, kuliner, budaya, sejarah Bandung Raya, serta fitur aplikasi BandungHub**.
  - Permintaan di luar konteks pariwisata (seperti disuruh membuat kalkulator, menulis kode program/coding, menyelesaikan soal matematika umum, atau tugas sekolah non-Bandung) **akan ditolak secara santun dan ramah khas Sunda**, kemudian dialihkan kembali ke perencanaan liburan di Bandung.
  - Untuk kebutuhan kalkulasi biaya liburan, Kang Bandung mengarahkan pengguna ke fitur **Itinerary & Budget Planner** bawaan BandungHub.

---

## 🗺️ Peta Interaktif OpenStreetMap & Rute Tanpa Batas Wilayah

Fitur peta BandungHub memanfaatkan pustaka sumber terbuka `flutter_map` dengan ubin peta OpenStreetMap:

- **100% Bebas Biaya & Tanpa API Key**: Tidak bergantung pada kuota tagihan Google Maps SDK.
- **Navigasi Rute Fleksibel**:
  - Batasan kamera kaku (*hard coordinate lock*) yang sebelumnya mengunci tampilan hanya di dalam Bandung telah dihapus.
  - Wisatawan dari luar kota (seperti Jakarta, Bogor, Surabaya, atau wilayah lainnya) dapat melihat rute perjalanan secara utuh dari posisi mereka saat ini menuju destinasi tujuan di Bandung.
  - Kamera peta secara otomatis menyesuaikan zoom dan posisi (*fitCameraToBounds*) dengan padding dinamis agar seluruh rute terlihat jelas.
- **Kompas Arah & Navigasi Eksternal**:
  - Dilengkapi perhitungan kompas bantalan arah (*bearing math*) menuju destinasi terdekat.
  - Tombol pintasan langsung membuka rute di Google Maps atau Waze bawaan ponsel pengguna.

---

## 👤 Pengelolaan Foto Profil (Kamera & Galeri) ke SQLite

Untuk meningkatkan keamanan dan kemudahan pengguna:
- Fitur penempelan URL teks tautan foto telah diganti dengan pemilih gambar native perangkat (*Image Picker*).
- Pengguna dapat memilih sumber foto: **Buka Galeri** atau **Ambil dari Kamera**.
- Foto yang dipilih dikonversi menjadi data Base64 terkompresi dan disimpan secara persisten di kolom database SQLite lokal (`AuthStorage`), sehingga foto profil tetap tersimpan tanpa membutuhkan server eksternal.
- Disediakan tombol hapus foto untuk mengembalikan avatar ke inisial nama pengguna.

---

## 🎮 Gamifikasi: Arkade Bocchi Jumpy & Kuis Budaya Sunda

1. **Mini Game Arkade Bocchi Jumpy**:
   - Game platformer vertikal ringan bertema maskot yang melompat di atas awan Bandung.
   - **Kontrol Layar Sentuh Intuitif**: Karakter bergerak mengikuti posisi sentuhan jari (*drag & touch*) pemain di layar ponsel, tanpa tombol panah visual yang kaku.
2. **Kuis Trivia Budaya Sunda**:
   - Gamifikasi edukatif berisi pertanyaan seputar sejarah Gedung Sate, kuliner khas (Peuyeum, Batagor, Surabi), dan kosakata bahasa Sunda.
   - Perolehan lencana penghargaan (*Badges*) yang tersimpan di profil pengguna.

---

## 🎨 Ikon Aplikasi Kustom (Launcher Icon)

Ikon aplikasi telah diperbarui secara penuh pada seluruh level densitas Android (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`):
- Menampilkan logo resmi BandungHub: gradien hijau zamrud Parahyangan, siluet pegunungan Tangkuban Perahu, dan daun teh hijau segar.
- Menghapus total ikon default Flutter bawaan proyek.

---

## 📋 Matriks Pemenuhan 14 Fase Projek (Rubric Compliance Matrix)

| Fase | Nama Modul / Fitur | Deskripsi & Bukti Implementasi | File Utama & Test Suite |
| :---: | :--- | :--- | :--- |
| **01** | **Design System & Base Theme** | Palet warna khas Parahyangan (Teal & Amber), tipografi adaptif, radius modern, Material 3, bebas AI-slop. | `core/theme/app_colors.dart`<br>`test/widget_test.dart` |
| **02** | **Autentikasi & Keamanan** | Login/Register email & sandi, Kunci Aplikasi Ala Bank (*BankAppLockScreen*) dengan biometrik & PIN 6-digit keypad, keluar akun bersih langsung ke halaman login. | `data/repositories/auth_repository.dart`<br>`features/auth/screens/bank_app_lock_screen.dart`<br>`test/bank_auth_lock_test.dart` |
| **03** | **Katalog Destinasi & Pencarian** | 38+ destinasi Bandung terlengkap, pencarian real-time, filter kategori (Alam, Kuliner, Sejarah, Keluarga, Hiburan), slider rentang harga tiket. | `data/repositories/destination_repository.dart`<br>`test/widget_test.dart` |
| **04** | **Sistem Rekomendasi Pintar** | Filter preferensi wisata berdasarkan budget, kategori favorit, kuis rekomendasi persona, dan personalisasi beranda. | `features/recommendations/`<br>`features/quiz/` |
| **05** | **Smart Itinerary & SQLite Storage** | Perencana jadwal perjalanan interaktif, estimasi total budget tiket, drag-and-drop reorder, verifikasi hash SHA-256 anti-tamper. | `data/repositories/itinerary_repository.dart`<br>`data/local/itinerary_storage.dart` |
| **06** | **Peta Interaktif OpenStreetMap** | Visualisasi lokasi wisata di peta Bandung, marker interaktif, rute multi-stop tanpa batasan wilayah, kompas arah (*bearing*), navigasi eksternal (Google Maps/Waze). | `features/map/screens/destination_map_screen.dart`<br>`services/map_service.dart` |
| **07** | **AI Travel Assistant (Kang Bandung)** | Asisten AI Google Gemini & Heuristik offline dengan persona ramah Sunda dan Domain Guardrails anti-jailbreak. | `services/ai_assistant_service.dart`<br>`test/ai_guardrail_test.dart` |
| **08** | **Gamifikasi & Mini Game** | Game Arkade *Bocchi Jumpy* dengan kontrol layar sentuh interaktif tanpa tombol panah + Kuis trivia seputar sejarah, budaya, dan kuliner Bandung. | `features/mini_game/screens/bocchi_jumpy_game_screen.dart`<br>`features/quiz/` |
| **09** | **Aksesibilitas & Mode Gelap (Dark Mode)** | Mode Gelap (*Dark Theme*) otomatis & manual, kontras tinggi, semantic accessibility (*A11y*), target sentuh minimal 48x48 dp. | `data/repositories/theme_repository.dart`<br>`core/theme/` |
| **10** | **Notifikasi & Pengingat Perjalanan** | Pengingat jadwal kunjungan otomatis via Android Exact Alarm (`exactAllowWhileIdle`), ringtone khusus, dan notification center. | `data/repositories/notification_repository.dart`<br>`features/notifications/` |
| **11** | **Ekspor & Berbagi Itinerary** | Ekspor rencana perjalanan ke format pesan WhatsApp/Telegram, dokumen cetak/PDF (HTML view), dan backup JSON dengan kode hash. | `services/itinerary_export_service.dart` |
| **12** | **Review, Rating & Blockchain Ledger** | Ulasan wisatawan, rating bintang (1-5★), galeri foto komunitas, dan pencatatan buku besar **Review Blockchain Ledger** anti-manipulasi. | `services/review_blockchain_service.dart`<br>`test/blockchain_test.dart` |
| **13** | **Offline Sync, Valas & Deteksi Jaringan** | Arsitektur *offline-first*, antrean aksi offline (*sync queue*), banner peringatan offline otomatis, sakelar simulasi offline, dan konverter kurs live API (`open.er-api.com`). | `data/repositories/offline_sync_repository.dart`<br>`services/travel_converter_service.dart`<br>`test/travel_converter_test.dart` |
| **14** | **Kesan & Pesan Kuliah & Dokumentasi** | Form evaluasi & refleksi akademik perkuliahan PAM, pemilihan topik paling berkesan, salin ringkasan evaluasi, dan dokumentasi lengkap. | `features/academic/screens/course_feedback_screen.dart` |

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── core/
│   ├── constants/            # Konstanta aplikasi (nama, versi, tagar)
│   └── theme/                # Desain sistem, AppColors (Teal/Amber), AppTheme (Light & Dark)
├── data/
│   ├── local/                # Penyimpanan lokal: AuthStorage (SQLite + SecureStorage) & ItineraryStorage
│   ├── sources/              # Dataset destinasi resmi Bandung Google Maps
│   └── repositories/         # State managers & repositories
│       ├── auth_repository.dart
│       ├── destination_repository.dart
│       ├── itinerary_repository.dart
│       ├── notification_repository.dart
│       ├── offline_sync_repository.dart
│       ├── review_repository.dart
│       └── theme_repository.dart
├── features/
│   ├── academic/             # Form Evaluasi & Kesan Pesan Kuliah
│   ├── auth/                 # Login, Register, BankAppLockScreen, PIN Lock, Biometrik
│   ├── converter/            # Konverter Wisatawan: Kurs Live Real-Time & Zona Waktu
│   ├── destinations/         # Katalog, Detail, Reviews, Rating, Galeri Foto
│   │   └── widgets/          # DestinationReviewsSection dengan Blockchain Ledger Inspector
│   ├── home/                 # Beranda, Header Cuaca, Banner Offline, Rekomendasi
│   ├── itinerary/            # Itinerary Planner, SQLite, Ekspor WhatsApp/PDF
│   ├── map/                  # OpenStreetMap, Markers, Routing Tanpa Batas, Kompas Navigasi
│   ├── mini_game/            # Game Arkade Bocchi Jumpy (Kontrol layar sentuh)
│   ├── notifications/        # Notification Center & Pengingat Alarm
│   ├── offline/              # Banner Offline & Pusat Sinkronisasi
│   ├── profile/              # Profil Pengguna, Ganti Avatar Galeri/Kamera, Keamanan PIN
│   ├── quiz/                 # Gamifikasi Trivia Sejarah & Budaya Bandung
│   └── recommendations/      # Form Preferensi & AI Assistant Kang Bandung
├── models/
│   ├── blockchain/           # ReviewBlock (Model Blok Rantai SHA-256)
│   └── ...                   # Data classes: Destination, Itinerary, Review, Notification, UserProfile
├── services/
│   ├── ai_assistant_service.dart       # Gemini AI & Smart Heuristic dengan Domain Guardrails
│   ├── review_blockchain_service.dart  # Pengelola Buku Besar Blockchain Ulasan
│   ├── travel_converter_service.dart   # Layanan Kurs Real-Time (Live API) & Zona Waktu
│   ├── map_service.dart                # Layanan Peta OSM & Navigasi Eksternal
│   ├── itinerary_export_service.dart   # Ekspor Dokumen HTML/PDF & WhatsApp
│   └── network_connectivity_service.dart # Pemantau Status Jaringan
├── shared/widgets/           # Widget reusable: DestinationCard, EmptyView, ErrorView
└── main.dart                 # Entry point aplikasi & inisialisasi services
```

---

## 🧪 Pengujian & Verifikasi Kualitas (Quality Assurance)

Proyek ini divalidasi dengan pengujian otomatis (*Automated Testing*) yang komprehensif:

### 1. Menjalankan Semua Unit & Widget Test (16/16 Passed)
```bash
flutter test
```
*Hasil:*
```text
00:03 +16: All tests passed!
```
Cakupan Test Suite:
- `test/ai_guardrail_test.dart`: Verifikasi batasan domain AI Kang Bandung menolak perintah coding & kalkulator di luar konteks wisata.
- `test/blockchain_test.dart`: Inisialisasi Genesis Block, hashing berantai SHA-256, dan deteksi manipulasi data ulasan.
- `test/bank_auth_lock_test.dart`: Alur kunci aplikasi ala bank, validasi input PIN 6 digit, auto-logout kembali ke LoginScreen, dan eliminasi guest mode.
- `test/travel_converter_test.dart`: Kalkulasi konversi kurs mata uang real-time live API, toleransi offline, dan format simbol mata uang.
- `test/profile_avatar_test.dart`: Penyimpanan foto avatar profil dari galeri/kamera ke database SQLite.
- `test/widget_test.dart`: Pengujian integritas rendering antarmuka BandungHubApp.

### 2. Menjalankan Uji Analisis Statis (0 Issues)
```bash
flutter analyze
```
*Hasil:*
```text
Analyzing projek_akhir...
No issues found! (ran in 2.5s)
```

---

## 🚀 Panduan Menjalankan Aplikasi

### Prasyarat:
- Flutter SDK (>= 3.0.0)
- Android SDK (API level 21+)
- Perangkat Android fisik atau Emulator

### Langkah-langkah:
1. **Masuk ke direktori proyek:**
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
  3. Integrasi *OpenStreetMap* tanpa API key berbayar dan tanpa batas wilayah rute navigasi.
  4. Pengamanan ulasan dengan inovasi *Review Blockchain Ledger (SHA-256)*.
  5. Asisten AI lokal dengan batasan domain (*Domain Guardrails*) yang tangguh.
  6. Pengamanan otentikasi Ala Bank (*Bank-Style App Lock*) menggunakan Sensor Biometrik & Keypad PIN 6-digit.
  7. Konverter valuta asing real-time terhubung langsung ke bursa mata uang global (`open.er-api.com`).
  8. Pengambilan foto profil langsung dari Galeri dan Kamera tersimpan di database lokal SQLite.
- **Kesan Perkuliahan:**
  > "Mata kuliah Pemrograman Aplikasi Mobile ini memberikan pemahaman mendalam mengenai pengembangan aplikasi mobile modern berstandar industri. Penyelesaian Projek Akhir BandungHub dari Phase 1 hingga Phase 14 membuktikan bahwa aplikasi yang tangguh, responsif, dan ramah pengguna dapat dibangun dengan arsitektur yang terstruktur rapi."
- **Pesan & Saran:**
  > "Materi yang diajarkan sudah sangat aplikatif dan relevan dengan industri. Saran untuk pengembangan kurikulum ke depan adalah penambahan materi CI/CD pipeline otomatis dengan GitHub Actions untuk kompilasi APK/AAB serta eksplorasi Flutter Multiplatform (Web & Desktop)."

---

© 2026 **BandungHub Team** : Final Project Pemrograman Aplikasi Mobile.