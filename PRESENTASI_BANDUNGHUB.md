# PANDUAN SLIDE PRESENTASI PROJEK AKHIR
# BandungHub: Smart Tourism & Heritage Navigator Kota Bandung

> **Catatan Penggunaan:**
> Dokumen ini disusun sebagai panduan lengkap materi slide PowerPoint (PPT) / Canva / Google Slides untuk Sidang & Presentasi Projek Akhir Mata Kuliah **Pemrograman Aplikasi Mobile (PAM)**.
> 
> Setiap slide telah dilengkapi dengan **Isi Visual Slide (Poin Ringkas)**, **Catatan Pembicara (Speaker Notes/Naskah Presentasi)**, **Rekomendasi Visual/Tangkapan Layar**, serta **Matriks Pemenuhan Rubrik Penilaian 100%**.

---

## DAFTAR ISI SLIDE
1. [Slide 1: Judul, Identitas Proyek & Konsep Utama](#slide-1-judul-identitas-proyek--konsep-utama)
2. [Slide 2: Latar Belakang & Rumusan Masalah Wisatawan](#slide-2-latar-belakang--rumusan-masalah-wisatawan)
3. [Slide 3: Solusi Produk & Arsitektur Fitur Terintegrasi](#slide-3-solusi-produk--arsitektur-fitur-terintegrasi)
4. [Slide 4: Arsitektur Database (SQLite + Supabase Non-Firebase), Session & Web Service API](#slide-4-arsitektur-database-sqlite--supabase-non-firebase-session--web-service-api)
5. [Slide 5: Katalog 38 Destinasi, Fasilitas Pencarian Cerdas & Pemilihan Filter](#slide-5-katalog-38-destinasi-fasilitas-pencarian-cerdas--pemilihan-filter)
6. [Slide 6: Rencana Perjalanan, Konversi Multi-Mata Uang (10 Valuta) & Konversi Zona Waktu (WIB, WITA, WIT, London)](#slide-6-rencana-perjalanan-konversi-multi-mata-uang-10-valuta--konversi-zona-waktu-wib-wita-wit-london)
7. [Slide 7: Fasilitas LBS (Peta & Rute Kendaraan) & Integrasi Multi-Sensor (Magnetometer, Accelerometer, Gyroscope)](#slide-7-fasilitas-lbs-peta--rute-kendaraan--integrasi-multi-sensor-magnetometer-accelerometer-gyroscope)
8. [Slide 8: Ekosistem AI (AI Lens Vision & LLM Chatbot Kang Bandung) & Blockchain Ulasan Sepolia](#slide-8-ekosistem-ai-ai-lens-vision--llm-chatbot-kang-bandung--blockchain-ulasan-sepolia)
9. [Slide 9: Sistem Keamanan Sesi Bank, Login Biometrik & Menu Profil Lengkap (Avatar, Saran & Kesan Kuliah PAM, Logout)](#slide-9-sistem-keamanan-sesi-bank-login-biometrik--menu-profil-lengkap-avatar-saran--kesan-kuliah-pam-logout)
10. [Slide 10: Notifikasi Mobile Cerdas, Gamifikasi Wisata (Bocchi Jumpy) & Pengujian Sistem (28/28 Tests Passed)](#slide-10-notifikasi-mobile-cerdas-gamifikasi-wisata-bocchi-jumpy--pengujian-sistem-2828-tests-passed)
11. [Slide 11: Demo Alur Pengguna Terpadu (User Journey)](#slide-11-demo-alur-pengguna-terpadu-user-journey)
12. [Slide 12: Matriks Pemenuhan 100% Rubrik Penilaian Projek Akhir PAM](#slide-12-matriks-pemenuhan-100-rubrik-penilaian-projek-akhir-pam)
13. [Slide 13: Kesimpulan & Sesi Tanya Jawab (Q&A)](#slide-13-kesimpulan--sesi-tanya-jawab-qa)

---

### Slide 1: Judul, Identitas Proyek & Konsep Utama
* **Judul Slide:** BandungHub
* **Subjudul:** Aplikasi Mobile Smart Tourism & Heritage Navigator Kota Bandung
* **Poin Utama di Slide:**
  * **Mata Kuliah:** Projek Akhir Pemrograman Aplikasi Mobile (PAM)
  * **Platform:** Multiplatform Mobile (Android & iOS) berbasis Flutter 3.x (Dart)
  * **Konsep Utama:** Platform pemandu wisata cerdas (*Smart Travel Companion*) yang memadukan navigasi geospasial LBS, ketahanan data *Offline-First* SQLite, kecerdasan buatan Gemini AI (Multimodal Vision & LLM Concierge), dan transparansi ulasan terdesentralisasi via Blockchain Ethereum Sepolia.
  * **Tim Pengembang:** [Nama Anda / NIM & Rekan Tim]
* **Rekomendasi Visual:**
  * Logo BandungHub (siluet Tangkuban Parahu dan daun teh hijau Parahyangan).
  * Mockup 2 smartphone menampilkan Beranda dan Peta Navigasi BandungHub.
* **Speaker Notes (Naskah Pembicara):**
  > "Selamat pagi/siang Bapak/Ibu dosen penguji serta rekan-rekan sekalian. Pada kesempatan kali ini, kami mempresentasikan karya Projek Akhir Pemrograman Aplikasi Mobile yang berjudul **BandungHub: Smart Tourism & Heritage Navigator Kota Bandung**. BandungHub hadir bukan sekadar katalog pariwisata statis, melainkan ekosistem asisten perjalanan cerdas yang mengintegrasikan layanan LBS, kecerdasan buatan, multi-sensor perangkat, ketahanan offline SQLite, hingga integritas ulasan berbasis blockchain."

---

### Slide 2: Latar Belakang & Rumusan Masalah Wisatawan
* **Judul Slide:** Latar Belakang & Tantangan Nyata Wisatawan
* **Poin Utama di Slide:**
  * 🔴 **Informasi Tersebar & Tidak Sinkron:** Detail harga tiket, jam operasional, dan lokasi wisata sering kali usang dan terpecah di berbagai media sosial.
  * 🔴 **Kendala Jaringan di Daerah Blank Spot:** Sinyal internet sering kali lemah atau hilang total saat wisatawan berada di daerah perbukitan/pegunungan (Lembang, Ciwidey, Pangalengan).
  * 🔴 **Kerumitan Navigasi & Kemacetan Khas Bandung:** Sulitnya membedakan rute aman untuk sepeda motor (non-tol) dan kendaraan roda empat (tol Pasteur/Pasupati).
  * 🔴 **Kalkulasi Anggaran & Perbedaan Waktu Wisatawan Global:** Turis asing kebingungan mengonversi estimasi biaya ke mata uang asalnya serta menyesuaikan jadwal liburan dengan zona waktu asalnya.
  * 🔴 **Keraguan Keaslian Ulasan:** Maraknya ulasan daring yang rawan dimanipulasi secara sepihak untuk mendongkrak popularitas destinasi secara tidak jujur.
* **Rekomendasi Visual:**
  * 4 Ikon Masalah: No Signal / Blank Spot, Kemacetan Jalan, Kerumitan Konversi Kurs/Waktu, dan Ulasan Tidak Terverifikasi.
* **Speaker Notes (Naskah Pembicara):**
  > "Kawasan Bandung Raya merupakan salah satu destinasi wisata terpadat di Indonesia. Kendala utama wisatawan di lapangan adalah sinyal yang drop di daerah perbukitan, rute jalan alternatif yang membingungkan bagi pengendara motor, kalkulasi biaya liburan yang tidak praktis bagi turis mancanegara, serta keraguan akan keaslian ulasan di internet. BandungHub dirancang secara khusus untuk menjawab seluruh permasalahan tersebut secara tuntas."

---

### Slide 3: Solusi Produk & Arsitektur Fitur Terintegrasi
* **Judul Slide:** Solusi: BandungHub Smart Tourism Ecosystem
* **Poin Utama di Slide:**
  * 🟢 **38 Destinasi Terkurasi Lengkap:** 5 kategori tematik dengan fasilitas pencarian instan dan filter pintar.
  * 🟢 **LBS & Rute Kendaraan Nyata:** Peta interaktif OpenStreetMap OSRM untuk Motor (non-tol) dan Mobil (jalan tol) + sensor kompas digital halus.
  * 🟢 **Arsitektur Dual-Storage Offline-First:** Sinkronisasi cloud online Supabase (Non-Firebase) dan cache lokal tangguh SQLite (`sqflite`).
  * 🟢 **Ekosistem AI Cerdas (Vision & LLM):** Bandung AI Lens untuk memindai visual landmark dan Bandung AI Chatbot untuk panduan lokal adaptif.
  * 🟢 **Fitur Konversi Terpadu:** Konverter 10 mata uang dunia dan penyesuaian jadwal kunjungan pada zona waktu (WIB, WITA, WIT, London).
  * 🟢 **Ulasan Anti-Manipulasi Blockchain Sepolia:** Hash kriptografis SHA-256 yang di-anchor langsung ke Ethereum Sepolia Testnet.
  * 🟢 **Keamanan Akun Berlapis:** Sesi aman, sensor biometrik (sidik jari/wajah), dan PIN 6-digit keypad ala aplikasi perbankan.
  * 🟢 **Gamifikasi Edukatif:** Mini game arkade *Bocchi Jumpy* bertema kuliner & budaya Sunda.
* **Rekomendasi Visual:**
  * Diagram showcase 8 pilar inovasi BandungHub mengelilingi mockup smartphone utama.
* **Speaker Notes (Naskah Pembicara):**
  > "Solusi yang dihadirkan BandungHub bersifat komprehensif. Mulai dari navigasi geospasial LBS multi-moda, perencana liburan dengan kalkulator budget multi-mata uang dan zona waktu, asisten cerdas AI multimodal, gamifikasi edukatif, hingga inovasi keamanan akun standar perbankan dan pencatatan ulasan di blockchain publik Ethereum Sepolia."

---

### Slide 4: Arsitektur Database (SQLite + Supabase Non-Firebase), Session & Web Service API
* **Judul Slide:** Arsitektur Sistem, Basis Data & Integrasi API
* **Poin Utama di Slide:**
  * **Database & Penyimpanan Hybrid (Dual-Storage):**
    * *Penyimpanan Lokal:* SQLite (`sqflite`) untuk menyimpan data offline 38 destinasi, session akun, preferensi, dan antrean sinkronisasi (*offline sync queue*).
    * *Penyimpanan Online:* Supabase Cloud Database (PostgreSQL) — **100% Bebas Ketergantungan Firebase**.
  * **Manajemen Sesi & Login Terenkripsi:**
    * Otentikasi aman Supabase Auth & penyimpanan token terenkripsi di *Secure Storage*.
    * Manajemen session otomatis: Auto-lock session saat aplikasi berada di latar belakang (*background timeout*) lebih dari 2 menit.
  * **Integrasi Web Service / REST API Eksternal:**
    * 🌐 **Supabase REST API:** Sinkronisasi cloud katalog destinasi, ulasan pengunjung, dan cloud itinerary.
    * 🗺️ **OpenStreetMap & OSRM Engine:** API rute jalan nyata tanpa batasan kuota berbayar Google Maps API.
    * 🤖 **Google Gemini AI REST API:** Model multimodal vision dan generative text LLM.
    * 💱 **Open Exchange Rates API (`open.er-api.com`):** Sinkronisasi kurs valuta asing real-time dari pasar uang dunia.
    * ⛓️ **Ethereum Sepolia RPC:** Pengiriman transaksi ulasan ke jaringan blockchain publik terdesentralisasi.
* **Rekomendasi Visual:**
  * Diagram alir sistem:
    `Flutter UI -> Repositories -> [Web Services (OSRM / Gemini / Forex / Sepolia)] & [Supabase Cloud] <-> [SQLite Offline Storage]`
* **Speaker Notes (Naskah Pembicara):**
  > "Sesuai dengan kriteria penilaian, aplikasi ini tidak menggunakan Firebase. Untuk backend online, kami memanfaatkan Supabase Cloud PostgreSQL, dipadukan dengan database lokal SQLite di perangkat. Ketika internet terputus, aplikasi tetap berjalan lancar 100% menggunakan SQLite. Seluruh panggilan web service—mulai dari routing OpenStreetMap OSRM, kurs forex real-time, Google Gemini AI, hingga transaksi RPC Ethereum Sepolia—dikelola melalui arsitektur Repository Pattern yang modular dan rapi."

---

### Slide 5: Katalog 38 Destinasi, Fasilitas Pencarian Cerdas & Pemilihan Filter
* **Judul Slide:** Katalog Eksplorasi 38 Destinasi & Fasilitas Pencarian
* **Poin Utama di Slide:**
  * **38 Destinasi Resmi Terkurasi dalam 5 Kategori Tematik:**
    * 🏛️ *Sejarah & Budaya:* Gedung Sate, Museum KAA, Museum Geologi, Bosscha, dll.
    * 🌲 *Wisata Alam:* Kawah Putih, Tangkuban Parahu, Tahura Juanda, Ranca Upas, Tebing Keraton.
    * 👨‍👩‍👧‍👦 *Wisata Keluarga:* Saung Angklung Udjo, Floating Market, Farmhouse Susu, Lembang Park & Zoo.
    * 🍜 *Kuliner Legendaris:* Pasar Punclut, Sudirman Street, Kopi Aroma Banceuy, Batagor Kingsley.
    * 🎡 *Hiburan Modern:* Trans Studio Bandung, Kiara Artha Park, Paris Van Java Mall.
  * **Fasilitas Pencarian & Pemilihan Interaktif:**
    * 🔍 **Pencarian Instan (Live Search):** Filter langsung berdasarkan pengetikan nama destinasi atau kata kunci.
    * 🏷️ **Pemilihan Kategori (Category Chips):** Memfilter kartu destinasi berdasarkan 5 kelompok tema secara instan.
    * 💰 **Pemilihan Batas Anggaran (Budget Range Slider):** Memilih destinasi sesuai batas maksimal harga tiket masuk yang dimiliki wisatawan.
    * ❤️ **Pemilihan Favorit (Bookmark):** Menandai destinasi impian untuk dimasukkan ke dalam rencana perjalanan.
  * **Metadata Komprehensif:** Koordinat GPS presisi, jam buka-tutup, HTM, rating riil, nomor kontak pengelola, dan galeri foto HD.
* **Rekomendasi Visual:**
  * Tangkapan layar layar *Eksplorasi* menampilkan search bar, pilihan kategori chip, slider budget, dan grid kartu destinasi.
* **Speaker Notes (Naskah Pembicara):**
  > "Katalog BandungHub memuat 38 destinasi resmi yang dikelompokkan ke dalam 5 tema wisata. Pengguna dapat dengan mudah mencari dan memilih destinasi melalui fitur live search, kategori chip, maupun slider batas anggaran tiket masuk. Setiap destinasi memiliki koordinat GPS, jam operasional, harga tiket, dan galeri foto beresolusi tinggi."

---

### Slide 6: Rencana Perjalanan, Konversi Multi-Mata Uang (10 Valuta) & Konversi Zona Waktu (WIB, WITA, WIT, London)
* **Judul Slide:** Perencana Perjalanan & Fitur Ramah Wisatawan Global
* **Poin Utama di Slide:**
  * **Penyusunan Jadwal Harian (Daily Itinerary Planner):** Pengelompokan destinasi per hari (Hari 1, Hari 2, dst.) lengkap dengan jam kunjungan, catatan aktivitas, dan kalkulasi total biaya liburan.
  * **Konversi Multi-Mata Uang Terpadu (10 Valuta Asing):**
    * 💱 **Mata Uang Didukung:** IDR (Rupiah), USD (Dolar AS), EUR (Euro), SGD (Dolar Singapura), MYR (Ringgit Malaysia), JPY (Yen Jepang), AUD (Dolar Australia), CNY (Yuan China), SAR (Riyal Saudi), GBP (Poundsterling).
    * Kurs diperbarui otomatis secara real-time via API dan dicache secara offline.
    * Rincian biaya tiket, makan, transportasi, dan total per orang otomatis terkonversi secara instan pada kartu rincian anggaran.
  * **Konversi Zona Waktu Internasional Terpadu (Dropdown Timezone Selector):**
    * ⏰ **Pilihan Zona Waktu Lengkap:** **WIB** (Bandung UTC+7), **WITA** (Bali/Makassar UTC+8), **WIT** (Jayapura UTC+9), **London / GMT** (Inggris UTC+0), serta zona SGT, JST, EST, CET.
    * Jadwal kunjungan di Bandung otomatis dikonversi dan menampilkan perbandingan jam lokal wisatawan sehingga wisatawan mancanegara tidak salah waktu kunjungan.
  * **Ekspor Dokumen Siap Pakai:** Dokumen resmi berformat PDF siap cetak serta format Catatan Teks ringkas yang siap dikirim via WhatsApp.
* **Rekomendasi Visual:**
  * Mockup layar detail Itinerary menampilkan dropdown mata uang (USD / MYR), pemilih zona waktu (WIB, WITA, WIT, London/GMT), dan pratinjau lembar PDF yang dihasilkan.
* **Speaker Notes (Naskah Pembicara):**
  > "Memenuhi syarat rubrik konversi mata uang dan zona waktu, BandungHub menyematkan fitur ini langsung ke dalam Perencana Perjalanan. Pengguna dapat memilih 10 mata uang dunia dan seluruh estimasi biaya otomatis terkonversi. Tak hanya itu, tersedia penyesuaian zona waktu mulai dari WIB, WITA, WIT, hingga London (GMT) dan New York (EST). Hal ini sangat memudahkan wisatawan mancanegara untuk menyelaraskan jadwal perjalanan mereka sebelum diekspor ke format PDF atau teks WhatsApp."

---

### Slide 7: Fasilitas LBS (Peta & Rute Kendaraan) & Integrasi Multi-Sensor (Magnetometer, Accelerometer, Gyroscope)
* **Judul Slide:** Fasilitas LBS & Pemanfaatan Multi-Sensor Perangkat
* **Poin Utama di Slide:**
  * **Fasilitas Location-Based Service (LBS):**
    * 📍 **Penentuan Posisi GPS Riil:** Menggunakan sensor GPS (`geolocator`) untuk mendeteksi posisi pengguna secara real-time.
    * 📏 **Kalkulasi Jarak Terdekat:** Menghitung jarak dinamis pengguna ke 38 destinasi Bandung (*Haversine distance matrix*).
    * 🗺️ **Routing Kendaraan Nyata (OpenStreetMap OSRM):**
      * 🛵 **Sepeda Motor:** Rute non-tol melalui jalan arteri dan jalur alternatif cepat.
      * 🚗 **Mobil:** Rute protokol utama dengan akses jalan tol bebas hambatan.
  * **Integrasi Minimal 2 Sensor Perangkat (Aktual: 3 Sensor Aktif):**
    * 🧭 **Sensor 1 - Magnetometer:** Mengukur vektor medan magnet bumi untuk menghitung sudut azimuth arah kompas 0°–360° secara presisi.
    * 📐 **Sensor 2 - Accelerometer:** Mengukur vektor percepatan gravitasi bumi untuk mendeteksi kemiringan perangkat (pitch & roll), kompensasi kemiringan kompas 3D, serta kontrol gerak tilt di mini game.
    * 🔄 **Sensor 3 - Gyroscope:** Mengukur kecepatan rotasi sudut untuk melengkapi kestabilan orientasi perangkat.
    * 🌊 **Low-Pass Filter Sensor Smoothing:** Algoritma penyaring getaran tangan agar perputaran jarum kompas bergerak sangat halus tanpa patah-patah (*anti-jitter*).
* **Rekomendasi Visual:**
  * Tangkapan layar peta rute navigasi kendaraan di atas, berdampingan dengan widget kompas digital presisi 360° di bawahnya.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk fasilitas LBS, BandungHub memanfaatkan GPS perangkat untuk menghitung jarak pengguna ke seluruh objek wisata dan menampilkan navigasi jalan nyata untuk sepeda motor dan mobil via OpenStreetMap. Terkait pemenuhan sensor perangkat, aplikasi kami mengintegrasikan 3 sensor sekaligus: Magnetometer untuk kompas arah 360 derajat, Accelerometer untuk deteksi kemiringan dan kemudi game, serta Gyroscope. Algoritma low-pass filter disematkan agar kompas bergerak halus tanpa getaran."

---

### Slide 8: Ekosistem AI (AI Lens Vision & LLM Chatbot Kang Bandung) & Blockchain Ulasan Sepolia
* **Judul Slide:** Kecerdasan Buatan (Vision & LLM) & Ulasan Blockchain Sepolia
* **Poin Utama di Slide:**
  * 🤖 **Fasilitas AI Multimodal & Fitur LLM Sesuai Tema:**
    * 📷 **Bandung AI Lens (Computer Vision):** Memindai objek cagar budaya dan landmark Bandung (Gedung Sate, Kawah Putih, Braga, Bosscha) menggunakan Google Gemini Vision + smart offline fallback.
    * 💬 **Bandung AI Travel Assistant (LLM Chatbot "Kang Bandung"):** Asisten percakapan cerdas berbahasa ramah yang memahami konteks pariwisata Bandung.
      * *Respon Adaptif Kontekstual:* Menjawab ringkas dan *to-the-point* untuk pertanyaan cepat seputar lokasi/kuliner, atau menyajikan rekomendasi mendalam ketika diminta menyusun rencana liburan.
      * *Domain Guardrails:* Dilengkapi sistem pengaman topik agar AI tetap fokus pada pariwisata Bandung.
  * ⛓️ **Fitur Blockchain Sederhana Terdesentralisasi (Ethereum Sepolia):**
    * Setiap ulasan yang dikirim pengguna dienkripsi dengan *SHA-256 Hash Chaining* berantai (Genesis Block #0 hingga Blok N).
    * **Anchor ke Ethereum Sepolia Testnet:** Data hash ulasan ditambatkan langsung ke jaringan blockchain publik Ethereum Sepolia.
    * **Verifikasi Publik Etherscan:** Tombol *"Lihat di Sepolia Etherscan"* dan fitur salin TxHash memungkinkan dosen penguji memverifikasi transaksi ulasan secara independen di penjelajah blok resmi (`sepolia.etherscan.io`).
* **Rekomendasi Visual:**
  * Screenshot jendela obrolan AI Chatbot Kang Bandung dan viewfinder AI Lens di sisi kiri.
  * Screenshot kartu ulasan blockchain lengkap dengan hash, tombol salin, dan bukti transaksi di web Sepolia Etherscan di sisi kanan.
* **Speaker Notes (Naskah Pembicara):**
  > "Pada aspek AI dan LLM, BandungHub menghadirkan dua fitur unggulan: AI Lens berbasis Computer Vision untuk mengenali landmark visual, dan AI Chatbot Kang Bandung berbasis LLM Gemini yang adaptif menyesuaikan panjang respon dengan konteks pertanyaan. Untuk fitur blockchain, setiap ulasan dienkripsi SHA-256 dan di-anchor ke jaringan publik Ethereum Sepolia Testnet, di mana dosen penguji dapat memverifikasi keabsahan ulasan secara langsung melalui penjelajah publik Etherscan."

---

### Slide 9: Sistem Keamanan Sesi Bank, Login Biometrik & Menu Profil Lengkap (Avatar, Saran & Kesan Kuliah PAM, Logout)
* **Judul Slide:** Keamanan Sesi Ala Bank, Biometrik & Menu Profil Lengkap
* **Poin Utama di Slide:**
  * **Login Biometrik & Keamanan Sesi Ala Bank (Bank-Style App Lock):**
    * Autentikasi biometrik instan via sensor sidik jari (*fingerprint*) atau pengenalan wajah (*face unlock*).
    * Keypad numerik 6-digit PIN yang responsif dan aman.
    * Kunci otomatis (*Background Inactivity Lock*) saat aplikasi ditinggalkan lebih dari 2 menit.
  * **Menu Profil Lengkap di Bottom Navigation:**
    * 🖼️ **Foto Profil (Avatar):** Mengunggah foto profil dari Kamera atau Galeri perangkat dan tersimpan di database SQLite (Base64).
    * 🎓 **Menu Khusus: "Saran & Kesan Mata Kuliah PAM" (Pemrograman Aplikasi Mobile):**
      * Lembar refleksi terstruktur untuk Tim Pengembang (Mahasiswa 1 & Mahasiswa 2).
      * Memuat kesan perkuliahan, topik favorit, saran pengembangan kurikulum, dan rating pengalaman belajar.
    * 🛡️ **Kelola PIN & Biometrik Terpadu:** Penggantian PIN, penghapusan PIN, atau penonaktifan biometrik wajib verifikasi PIN lama terlebih dahulu.
    * 🚪 **Menu Logout Akun:** Menghapus sesi aktif secara aman dan mengembalikan pengguna ke halaman gerbang autentikasi.
* **Rekomendasi Visual:**
  * Screenshot layar kunci biometrik / PIN, layar Profil dengan foto avatar, form Saran & Kesan Mata Kuliah PAM, dan tombol Logout.
* **Speaker Notes (Naskah Pembicara):**
  > "Dari segi antarmuka navigasi bawah dan profil, kami memenuhi seluruh kriteria rubrik: Menu Profil dilengkapi foto avatar pengguna dari kamera/galeri, menu khusus 'Saran & Kesan Mata Kuliah PAM' yang memuat refleksi tim pengembang, serta tombol Logout. Sistem keamanan dilengkapi gerbang biometrik sidik jari dan PIN 6-digit ala aplikasi perbankan modern, di mana setiap perubahan keamanan wajib memverifikasi PIN lama terlebih dahulu."

---

### Slide 10: Notifikasi Mobile Cerdas, Gamifikasi Wisata (Bocchi Jumpy) & Pengujian Sistem (28/28 Tests Passed)
* **Judul Slide:** Notifikasi Mobile, Gamifikasi Edukatif & Jaminan Kualitas
* **Poin Utama di Slide:**
  * 🔔 **Fitur Notifikasi Berbasis Mobile Sesuai Konsep:**
    * Menggunakan `flutter_local_notifications` dengan saluran notifikasi prioritas tinggi (*Android Exact Alarm*).
    * *Pengingat Agenda Liburan:* Memberikan alarm notifikasi sebelum jadwal kunjungan destinasi dimulai.
    * *Pengingat Eksplorasi Wisata:* Notifikasi pengingat lokasi wisata terdekat dan sambutan selamat datang saat aplikasi dibuka.
  * 🎮 **Mini Game Edukatif Terkait Tema (Bocchi Jumpy & Kuis Sunda):**
    * Game arkade vertikal *Bocchi Jumpy* di mana karakter melompat mengumpulkan kuliner khas Bandung (Batagor, Peuyeum, Colenak) dan suvenir Angklung.
    * Memanfaatkan sensor kemiringan perangkat (*Accelerometer tilt steering*) atau kontrol sentuh responsif.
    * Dilengkapi fitur Trivia Kuis Budaya Sunda untuk mengasah wawasan wisatawan.
  * 🧪 **Pengujian Sistem Otomatis (100% Lulus):**
    * **28 Pengujian Otomatis (Automated Tests)** lulus sempurna (`00:04 +28: All tests passed!`).
    * Mencakup: Web3 & Blockchain Anchor, Sensor Smoothing 3D Kompas, AI Guardrails & Adaptation, Bank App Lock & Biometrik, Routing LBS Mobil/Motor, dan SQLite Offline Storage.
    * Analisis kode bersih tanpa error (`flutter analyze: No issues found!`).
* **Rekomendasi Visual:**
  * Screenshot banner notifikasi mobile di status bar, tampilan mini game Bocchi Jumpy, dan terminal eksekusi `flutter test` bertuliskan `All tests passed!`.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk fitur notifikasi mobile, BandungHub dilengkapi alarm notifikasi pengingat jadwal liburan dan destinasi terdekat. Kami juga menyematkan mini game edukatif Bocchi Jumpy yang memanfaatkan sensor gerak kemiringan accelerometer untuk mengumpulkan kuliner khas Bandung. Seluruh fungsionalitas ini telah diuji secara komprehensif melalui 28 automated tests yang lulus 100 persen dan kode yang terverifikasi bersih bebas lint issue."

---

### Slide 11: Demo Alur Pengguna Terpadu (User Journey)
* **Judul Slide:** Skenario Demonstrasi Alur Pengguna (Live Demo Flow)
* **Poin Utama di Slide:**
  * **Tahap 1 (Akses Cepat & Konsultasi AI):** Masuk dengan sidik jari/PIN -> Beranda -> Tanya tips liburan ke AI Chatbot Kang Bandung (tunjukkan respon cepat & adaptif).
  * **Tahap 2 (Pindai Landmark AI Lens):** Buka AI Lens -> Arahkan kamera ke landmark (Gedung Sate) -> AI memaparkan sejarah dan rekomendasi aktivitas.
  * **Tahap 3 (Susun Rencana & Konversi Global):** Buat itinerary baru -> Buka rincian anggaran -> Ubah mata uang ke USD/MYR -> Ubah zona waktu ke London (GMT) -> Ekspor ke dokumen PDF.
  * **Tahap 4 (Navigasi LBS & Kompas Halus):** Pilih destinasi -> Tampilkan rute jalan riil sepeda motor (non-tol) -> Perlihatkan jarum kompas digital 360° yang berputar mulus.
  * **Tahap 5 (Ulasan Blockchain & Etherscan):** Tulis ulasan wisata -> Perlihatkan hash blok yang tercetak -> Buka tombol *"Lihat di Sepolia Etherscan"* untuk pembuktian on-chain.
  * **Tahap 6 (Menu Profil & Evaluasi Kuliah PAM):** Buka tab Profil -> Tunjukkan foto avatar -> Buka menu *Saran & Kesan Mata Kuliah PAM* -> Uji ganti PIN / matikan biometrik (wajib verifikasi PIN lama) -> Uji tombol Logout.
* **Rekomendasi Visual:**
  * Diagram alir 6 langkah demonstrasi langsung dilengkapi mockup tangkapan layar di setiap langkahnya.
* **Speaker Notes (Naskah Pembicara):**
  > "Dalam sesi demonstrasi langsung, kami akan mempraktikkan alur terpadu ini: mulai dari login biometrik, konsultasi ke AI Chatbot, memindai objek dengan AI Lens, mengonversi mata uang dan zona waktu di itinerary, menavigasi rute jalan nyata dan kompas, mengirim ulasan terverifikasi di Sepolia Etherscan, serta memperlihatkan pengisian Saran dan Kesan Kuliah PAM di menu Profil."

---

### Slide 12: Matriks Pemenuhan 100% Rubrik Penilaian Projek Akhir PAM
* **Judul Slide:** Matriks Pemenuhan 100% Rubrik Penilaian PAM
* **Poin Utama di Slide (Tabel Kesesuaian Kriteria):**

| Syarat Rubrik Penilaian Dosen | Status | Bukti Implementasi di BandungHub |
| :--- | :---: | :--- |
| **1. Konsep Projek Akhir Terpadu** | ✅ 100% | *Smart Tourism & Heritage Navigator Kota Bandung* (Katalog 38 destinasi, LBS, Itinerary, AI, Blockchain). |
| **2. Login Enkripsi (Non-Firebase) & Session** | ✅ 100% | Supabase Cloud Database + SQLite Local Cache, Password Hashing, Session Timeout & Auto-lock 2 menit. |
| **3. Login Biometric** | ✅ 100% | Sensor Sidik Jari (*Fingerprint*) & Pengenalan Wajah (*Face Unlock*) via library `local_auth`. |
| **4. Database Lokal & Online** | ✅ 100% | Dual-Storage: **SQLite (`sqflite`)** lokal tangguh (*offline-first*) & **Supabase Cloud (PostgreSQL)** online. |
| **5. Web Service / API, LBS, Multiplatform** | ✅ 100% | API: OSRM Routing, Gemini AI, Open Exchange, Sepolia RPC. LBS: GPS geolocator & rute peta. Multiplatform: Flutter (Android & iOS). |
| **6. Bottom Nav: Profil (Ada Foto), Saran & Kesan PAM, Logout** | ✅ 100% | Tab Profil di Bottom Nav; Foto Avatar dari Kamera/Galeri (Base64 SQLite); Menu Khusus *Saran & Kesan Mata Kuliah PAM*; Tombol Logout Akun. |
| **7. Konversi Mata Uang (≥3) & Waktu (WIB, WIT, WITA, London)** | ✅ 100% | 10 Mata Uang (IDR, USD, EUR, SGD, MYR, GBP, dll.); Zona Waktu: **WIB, WITA, WIT, London (GMT)**, EST, JST terpadu di Itinerary. |
| **8. Minimal 2 Sensor Sesuai Konsep** | ✅ 100% | **3 Sensor Aktif:** Magnetometer (Kompas 360°), Accelerometer (Kemiringan 3D & Tilt Game), Gyroscope (Kecepatan Sudut). |
| **9. Fitur / Fasilitas AI & Fitur LLM** | ✅ 100% | **AI Vision:** Bandung AI Lens (Gemini Multimodal). **LLM:** Bandung AI Chatbot Kang Bandung (Gemini LLM adaptif kontekstual). |
| **10. Mini Games Sederhana Sesuai Konsep** | ✅ 100% | Game arkade *Bocchi Jumpy* (mengumpulkan kuliner khas Bandung via sensor tilt/touch) & Kuis Budaya Sunda. |
| **11. Fasilitas Pencarian & Pemilihan** | ✅ 100% | Live Search Bar, Filter 5 Kategori Tematik, Slider Batas Budget Tiket Masuk, dan Penanda Destinasi Favorit. |
| **12. Fitur Notifikasi Berbasis Mobile** | ✅ 100% | `flutter_local_notifications`: Alarm jadwal itinerary liburan, pengingat lokasi destinasi, dan sambutan selamat datang. |
| **13. Fitur Blockchain Sederhana** | ✅ 100% | Review Blockchain Ledger SHA-256 + Anchoring ke **Ethereum Sepolia Testnet** (bisa dicek live di Sepolia Etherscan). |

* **Speaker Notes (Naskah Pembicara):**
  > "Bapak dan Ibu dosen penguji dapat mencermati tabel matriks pada slide ini. Seluruh 13 butir spesifikasi dan kriteria penilaian mata kuliah Pemrograman Aplikasi Mobile telah kami penuhi secara lengkap 100% tanpa ada poin yang terlewat, bahkan kami perkaya dengan inovasi Web3 Blockchain Sepolia dan pengujian otomatis 28 skenario."

---

### Slide 13: Kesimpulan & Sesi Tanya Jawab (Q&A)
* **Judul Slide:** Kesimpulan & Sesi Tanya Jawab (Q&A)
* **Poin Utama di Slide:**
  * 🌟 **Solusi Nyata & Komprehensif:** Menyelesaikan kendala nyata wisatawan di Kota Bandung melalui pendekatan teknologi terintegrasi.
  * 🌟 **Kesiapan Teknis Teruji:** Arsitektur modular bersih (*clean architecture*), lulus 28 automated tests (100%), dan siap berjalan dalam kondisi offline maupun online.
  * 🌟 **Inovasi Masa Depan:** Membuktikan potensi sinergi antara aplikasi mobile cerdas, AI generatif, dan teknologi desentralisasi blockchain.
  * **Terima Kasih / Sesi Tanya Jawab (Q&A)**
  * Kontak: [Email Anda] | GitHub: [Link Repo GitHub Anda]
* **Rekomendasi Visual:**
  * Mockup 3 smartphone berdampingan menampilkan Beranda, Peta Navigasi Rute, dan Kartu Ulasan Blockchain Sepolia. Teks besar: *"Terima Kasih - Sesi Tanya Jawab (Q&A)"*.
* **Speaker Notes (Naskah Pembicara):**
  > "Sebagai kesimpulan, BandungHub membuktikan bahwa aplikasi mobile pariwisata dapat dibangun secara tangguh, modern, dan memenuhi seluruh standar kompetensi mata kuliah Pemrograman Aplikasi Mobile. Sekian presentasi dari kami, terima kasih banyak atas waktu dan perhatian Bapak/Ibu dosen penguji. Waktu dan tempat kami persilakan untuk sesi tanya jawab."

---

## 💡 PANDUAN PRAKTIS LIVE DEMO & JAWABAN PERTANYAAN DOSEN PENGUJI:

1. **Urutan Live Demo Terbaik di HP/Emulator (Durasi 5-7 Menit):**
   - **Langkah 1:** Buka aplikasi -> Tunjukkan layar kunci **BankAppLockScreen** -> Tempelkan sidik jari (biometrik) atau ketik PIN 6 digit untuk membuka.
   - **Langkah 2:** Pada Beranda, gunakan *Search Bar* untuk mencari destinasi (misal *"Kawah Putih"*), ubah filter kategori (*Alam*), dan gerakkan slider budget untuk mendemokan **Fasilitas Pencarian dan Pemilihan**.
   - **Langkah 3:** Buka **AI Chatbot Kang Bandung**, ajukan pertanyaan singkat: *"Rekomendasi batagor enak di Bandung"* -> Perlihatkan AI menjawab ringkas, relevan, dan to the point.
   - **Langkah 4:** Buka **Rencana Perjalanan (Itinerary)** -> Tunjukkan konversi mata uang (misal ke Ringgit/USD) dan zona waktu (pilih **London / GMT** atau **WITA**) -> Klik tombol ekspor PDF untuk membuktikan dokumen terbuat dengan rapi.
   - **Langkah 5:** Buka **Peta Navigasi** -> Pilih moda *Sepeda Motor* (tunjukkan rute non-tol) -> Putar HP untuk mendemokan perputaran jarum **Kompas Sensor 360°** yang halus.
   - **Langkah 6:** Tulis sebuah ulasan di salah satu destinasi -> Tunjukkan hash SHA-256 yang tercetak -> Klik tombol *"Lihat di Sepolia Etherscan"* untuk membuktikan **Fitur Blockchain Sederhana** terhubung ke Ethereum Sepolia.
   - **Langkah 7:** Masuk ke tab **Profil** -> Tunjukkan foto profil avatar -> Buka menu **Saran & Kesan Mata Kuliah PAM** -> Buka pengaturan PIN/Biometrik (buktikan wajib verifikasi PIN lama) -> Klik tombol **Logout**.

2. **Antisipasi Pertanyaan Dosen:**
   - *Tanya:* "Kenapa tidak pakai Firebase?"
     *Jawab:* "Sesuai ketentuan tugas akhir yang meminta autentikasi non-Firebase, kami menggunakan Supabase Cloud (PostgreSQL) yang lebih fleksibel, didukung penyimpanan lokal SQLite untuk kapabilitas Offline-First sejati."
   - *Tanya:* "Sensor apa saja yang dipakai?"
     *Jawab:* "Kami mengimplementasikan 3 sensor: Magnetometer untuk kompas arah mata angin 360 derajat, Accelerometer untuk deteksi kemiringan 3D dan kontrol tilt pada mini game Bocchi Jumpy, serta Gyroscope."
   - *Tanya:* "Apakah blockchain-nya beneran atau simulasi?"
     *Jawab:* "Buku besar ulasannya nyata menggunakan enkripsi SHA-256 Merkle Chaining lokal dan ditambatkan (*anchor*) ke jaringan publik Ethereum Sepolia Testnet melalui transaksi RPC resmi yang dapat diverifikasi siapa saja di Sepolia Etherscan."
