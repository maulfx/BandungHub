# PANDUAN SLIDE PRESENTASI PROJEK AKHIR
# BandungHub: Smart Tourism & Heritage Navigator Kota Bandung

> **Catatan Penggunaan:**
> Dokumen ini disusun sebagai panduan lengkap materi slide PowerPoint (PPT) / Canva / Google Slides. Setiap slide telah dilengkapi dengan **Isi Visual Slide (Poin Ringkas)**, **Catatan Pembicara (Speaker Notes/Naskah Presentasi)**, dan **Rekomendasi Visual/Tangkapan Layar**.
> 
> *Versi Pembaruan Terkini: Telah diselaraskan dengan integrasi Ethereum Sepolia Blockchain Anchor, AI Travel Assistant Adaptif, Sensor Kompas Halus, dan Pembaruan Sistem Keamanan PIN & Biometrik Profil.*

---

## DAFTAR ISI SLIDE
1. [Slide 1: Judul & Identitas Proyek](#slide-1-judul--identitas-proyek)
2. [Slide 2: Latar Belakang & Rumusan Masalah](#slide-2-latar-belakang--rumusan-masalah)
3. [Slide 3: Solusi Produk - BandungHub](#slide-3-solusi-produk---bandunghub)
4. [Slide 4: Arsitektur Sistem & Teknologi Terkini](#slide-4-arsitektur-sistem--teknologi-terkini)
5. [Slide 5: Katalog 38 Destinasi Wisata & Budaya](#slide-5-katalog-38-destinasi-wisata--budaya)
6. [Slide 6: Rencana Perjalanan Pintar, Konversi Multi-Mata Uang & Zona Waktu](#slide-6-rencana-perjalanan-pintar-konversi-multi-mata-uang--zona-waktu)
7. [Slide 7: Peta Interaktif, Navigasi Kendaraan (Motor & Mobil) & Kompas Presisi](#slide-7-peta-interaktif-navigasi-kendaraan-motor--mobil--kompas-presisi)
8. [Slide 8: Ekosistem AI Cerdas & Integritas Ulasan Blockchain Sepolia](#slide-8-ekosistem-ai-cerdas--integritas-ulasan-blockchain-sepolia)
9. [Slide 9: Ketahanan Data (Offline-First) & Keamanan Akun Berlapis](#slide-9-ketahanan-data-offline-first--keamanan-akun-berlapis)
10. [Slide 10: Pengujian Sistem & Jaminan Kualitas Kode](#slide-10-pengujian-sistem--jaminan-kualitas-kode)
11. [Slide 11: Demo Alur Pengguna (User Journey)](#slide-11-demo-alur-pengguna-user-journey)
12. [Slide 12: Kesimpulan & Sesi Tanya Jawab (Q&A)](#slide-12-kesimpulan--sesi-tanya-jawab-qa)

---

### Slide 1: Judul & Identitas Proyek
* **Judul Slide:** BandungHub
* **Subjudul:** Aplikasi Mobile Smart Tourism & Heritage Navigator Kota Bandung Berbasis Flutter, Supabase Cloud & Sepolia Blockchain
* **Poin Utama di Slide:**
  * Proyek Akhir Praktikum Pemrograman Mobile
  * Platform: Mobile (Android & iOS)
  * Framework: Flutter 3.x (Dart)
  * Backend & Cloud: Supabase Cloud Database (PostgreSQL) + Auth
  * Local Storage: SQLite (`sqflite`) Resilient Offline Storage
  * Smart Features: Google Gemini AI (Vision & Assistant) + Ethereum Sepolia Testnet Anchor
  * Nama Pengembang / Tim: [Nama Anda / NIM]
* **Rekomendasi Visual:**
  * Logo BandungHub di bagian tengah/kiri.
  * Mockup layar HP menampilkan beranda BandungHub dengan kartu destinasi Gedung Sate / Braga.
* **Speaker Notes (Naskah Pembicara):**
  > "Selamat pagi/siang Bapak/Ibu dosen penguji serta rekan-rekan sekalian. Pada kesempatan kali ini, saya akan mempresentasikan karya Projek Akhir Pemrograman Mobile saya yang berjudul **BandungHub: Smart Tourism & Heritage Navigator Kota Bandung**. Aplikasi ini dirancang sebagai platform pariwisata pintar terintegrasi yang memadukan keindahan budaya Parahyangan, efisiensi perencana liburan, kecerdasan buatan Gemini AI, serta transparansi ulasan terdesentralisasi berbasis Blockchain Ethereum Sepolia."

---

### Slide 2: Latar Belakang & Rumusan Masalah
* **Judul Slide:** Latar Belakang & Tantangan Wisatawan
* **Poin Utama di Slide:**
  * 🔴 **Informasi Tersebar & Tidak Sinkron:** Informasi tiket, jam operasional, dan lokasi wisata Bandung sering kali tidak mutakhir dan terpecah di berbagai kanal media sosial.
  * 🔴 **Kendala Jaringan di Kawasan Wisata:** Sinyal internet sering kali lemah atau hilang saat wisatawan berada di daerah dataran tinggi (Ciwidey, Lembang, Pangalengan).
  * 🔴 **Perencanaan Perjalanan & Budget yang Rumit:** Wisatawan kesulitan menyusun rute efisien, membagi waktu per hari, dan memperhitungkan anggaran liburan (terlebih bagi wisatawan mancanegara).
  * 🔴 **Keraguan Integritas Ulasan Wisata:** Banyak ulasan online yang rentan dipalsukan atau dimanipulasi oleh pihak pengelola untuk menaikkan rating secara tidak jujur.
* **Rekomendasi Visual:**
  * Ilustrasi 4 ikon masalah (Koneksi lemah/No Signal, Kemacetan rute, Jadwal & Budget bentrok, Ulasan bias/dimanipulasi).
* **Speaker Notes (Naskah Pembicara):**
  > "Kota Bandung merupakan salah satu magnet wisata utama di Indonesia. Namun, wisatawan di lapangan kerap menghadapi kendala nyata: sinyal internet yang drop saat berada di Lembang atau Ciwidey, kebingungan mengatur rute agar tidak terjebak macet, anggaran yang membengkak tanpa kalkulasi jelas, serta keraguan akan keaslian ulasan di internet. Dari persoalan tersebut, BandungHub dikembangkan dengan arsitektur offline-first, navigasi cerdas, asisten AI, dan pencatatan ulasan anti-manipulasi."

---

### Slide 3: Solusi Produk - BandungHub
* **Judul Slide:** Solusi: BandungHub Smart Tourism Ecosystem
* **Poin Utama di Slide:**
  * 🟢 **38 Destinasi Terkurasi Lengkap:** 5 kategori tematik (Sejarah & Budaya, Alam, Keluarga, Kuliner Legendaris, Hiburan Modern).
  * 🟢 **Bandung AI Duo (Vision & Chatbot):**
    * *Bandung AI Lens:* Pindai visual cagar budaya secara instan dengan Google Gemini AI Vision.
    * *Bandung AI Assistant:* Chatbot pemandu lokal interaktif dengan respon kontekstual adaptif (ringkas/detail).
  * 🟢 **Perencana Perjalanan Cerdas (Itinerary Planner):** Kalkulator budget otomatis, konversi multi-mata uang dunia, dan penyesuaian zona waktu global.
  * 🟢 **Peta & Navigasi Multi-Moda Nyata:** Navigasi interaktif Sepeda Motor (non-tol) & Mobil (tol/arteri) via OpenStreetMap + Kompas digital halus presisi 360°.
  * 🟢 **Integritas Ulasan Berbasis Ethereum Sepolia Blockchain:** Ulasan diamankan kriptografi SHA-256 berantai dan di-anchor ke jaringan publik Sepolia Testnet (dapat diverifikasi via Etherscan).
  * 🟢 **Arsitektur Offline-First & Keamanan Berlapis:** Berjalan mulus tanpa sinyal internet melalui SQLite lokal, diamankan PIN 6-digit & Biometrik ala perbankan.
* **Rekomendasi Visual:**
  * Diagram showcase 6 pilar inovasi BandungHub mengelilingi mockup smartphone aplikasi.
* **Speaker Notes (Naskah Pembicara):**
  > "BandungHub menghadirkan ekosistem pariwisata yang lengkap dalam satu genggaman. Kami menggabungkan database 38 destinasi terkurasi, kecerdasan buatan multimodal untuk mengenali objek dan menjawab pertanyaan wisata, rute navigasi jalan nyata untuk motor dan mobil, perencana anggaran multi-mata uang, hingga inovasi Web3 di mana setiap ulasan di-anchor ke blockchain publik Ethereum Sepolia agar bebas dari manipulasi data."

---

### Slide 4: Arsitektur Sistem & Teknologi Terkini
* **Judul Slide:** Arsitektur Sistem & Landasan Teknologi
* **Poin Utama di Slide:**
  * **Frontend Mobile:** Flutter 3.x (Dart) dengan pola *Clean Architecture* & *Repository Pattern* modular.
  * **Cloud Backend & Database:** Supabase Cloud (PostgreSQL) untuk autentikasi user, katalog terpusat, ulasan real-time, dan cloud itinerary.
  * **Local Resilient Database:** SQLite (`sqflite`) & `SharedPreferences` untuk ketahanan data saat perangkat offline (tanpa sinyal).
  * **Map & Geospatial Routing:** `flutter_map` + OpenStreetMap API + OSRM Engine (rute jalan riil tanpa ketergantungan berbayar Google Maps API).
  * **Hardware Sensor Fusion:** Akses magnetometer & akselerometer dengan algoritma *Low-Pass Sensor Smoothing* untuk pergerakan kompas yang halus dan presisi.
  * **Decentralized Web3 Ledger:** Integrasi SHA-256 Chaining & RPC Ethereum Sepolia Testnet untuk pencatatan hash ulasan permanen.
  * **Artificial Intelligence Engine:** Google Gemini REST API dengan domain guardrails khusus pariwisata Bandung.
* **Rekomendasi Visual:**
  * Diagram alir arsitektur sistem:
    `Flutter UI -> Services & Repositories -> [Supabase Cloud / Sepolia RPC (Online)] <-> [Local SQLite Cache (Offline)]`
* **Speaker Notes (Naskah Pembicara):**
  > "Dari sisi rekayasa perangkat lunak, BandungHub mengedepankan arsitektur hybrid yang tangguh. Aplikasi menggunakan Flutter dengan pola Repository Pattern yang rapi. Ketika ada jaringan, aplikasi terhubung ke Supabase Cloud dan RPC Ethereum Sepolia. Namun ketika berada di area blank spot, aplikasi otomatis beralih menggunakan cache SQLite lokal tanpa terjadi force close atau lag, menjamin pengalaman pengguna tetap mulus."

---

### Slide 5: Katalog 38 Destinasi Wisata & Budaya
* **Judul Slide:** Katalog Eksplorasi 38 Destinasi Terkurasi
* **Poin Utama di Slide:**
  * **5 Kategori Tematik Komprehensif:**
    * 🏛️ **Sejarah & Budaya:** Gedung Sate, Museum KAA, Museum Geologi, Bosscha, Monumen Perjuangan, dll.
    * 🌲 **Wisata Alam:** Kawah Putih, Tangkuban Parahu, Tahura Juanda, Ranca Upas, Tebing Keraton, Situ Patenggang.
    * 👨‍👩‍👧‍👦 **Wisata Keluarga:** Saung Angklung Udjo, Floating Market, Farmhouse Susu, Lembang Park & Zoo, Dago Dream Park.
    * 🍜 **Kuliner Legendaris:** Pasar Punclut, Sudirman Street Day & Night, Kopi Aroma Banceuy, Batagor Kingsley, Mie Kocok Mang Dadeng.
    * 🎡 **Hiburan Modern:** Trans Studio Bandung, Kiara Artha Park, Paris Van Java Mall.
  * **Kelengkapan Metadata Tiap Destinasi:** Koordinat GPS presisi, jam operasional, harga tiket masuk, rating riil tersinkron, dan galeri foto HD.
  * **Fitur Filter Pintar:** Pencarian instan berdasarkan kata kunci, filter kategori, batas anggaran tiket, dan penanda destinasi favorit.
* **Rekomendasi Visual:**
  * Cuplikan layar halaman **Katalog & Eksplorasi** menampilkan filter chip, kolom pencarian, dan grid kartu destinasi Bandung.
* **Speaker Notes (Naskah Pembicara):**
  > "BandungHub menyediakan basis data 38 destinasi resmi yang dikelompokkan ke dalam lima kategori tematik. Setiap kartu destinasi menyajikan informasi komprehensif mulai dari harga tiket, jam buka, titik koordinat, hingga galeri foto berkualitas tinggi. Pengguna dapat langsung memfilter destinasi sesuai kategori atau menyesuaikan dengan batas budget yang dimiliki."

---

### Slide 6: Rencana Perjalanan Pintar, Konversi Multi-Mata Uang & Zona Waktu
* **Judul Slide:** Perencana Perjalanan & Fitur Ramah Wisatawan Global
* **Poin Utama di Slide:**
  * **Penyusunan Agenda Per Hari (Daily Itinerary):** Pengelompokan destinasi berdasarkan jadwal harian (Hari 1, Hari 2, dst.) lengkap dengan estimasi jam kunjungan.
  * **Kalkulator Budget Otomatis & Konversi Multi-Mata Uang:**
    * 💱 **Pilihan Mata Uang Lengkap (IDR, USD, MYR, SGD, EUR, JPY, AUD, CNY, dll.):** Rincian biaya tiket, transportasi, makan, dan total per orang otomatis terkonversi secara instan sesuai kurs terkini.
    * Wisatawan mancanegara (misal turis Malaysia atau Singapura) langsung mengetahui estimasi pengeluaran tanpa perlu membuka kalkulator kurs terpisah.
  * **Sinkronisasi Jadwal Berdasarkan Zona Waktu (Timezone Converter):**
    * ⏰ **Pilihan Zona Waktu Asal Pengguna (WIB, WITA, WIT, SGT/MYT, JST, EST, dll.):**
    * Jadwal kunjungan di Bandung (WIB/UTC+7) otomatis dikonversi dan menampilkan perbandingan jam lokal wisatawan sehingga tidak ada jadwal yang terlewat.
  * **Ekspor Dokumen Fleksibel:**
    * 📄 **Format PDF Resmi:** Dokumen rapi siap cetak lengkap dengan tabel rincian biaya, jadwal, dan catatan perjalanan.
    * 📝 **Format Catatan Teks:** Teks ringkas yang siap dibagikan via WhatsApp, Telegram, atau aplikasi catatan rombongan.
  * **Penyimpanan Cloud Terikat Akun:** Seluruh rencana perjalanan tersinkron ke Supabase Cloud terhubung dengan ID pengguna.
* **Rekomendasi Visual:**
  * Mockup layar detail rencana perjalanan menunjukkan dropdown mata uang (USD / MYR), selector zona waktu, serta pratinjau dokumen PDF yang dihasilkan.
* **Speaker Notes (Naskah Pembicara):**
  > "Fitur unggulan lainnya adalah Perencana Perjalanan Cerdas yang dirancang ramah bagi wisatawan domestik maupun mancanegara. Aplikasi menyediakan kalkulator anggaran otomatis dengan konverter multi-mata uang dunia serta pemilih zona waktu internasional, sehingga wisatawan asing dapat langsung memahami jadwal dan biaya liburan mereka. Seluruh rencana ini dapat diekspor secara instan ke format PDF resmi atau teks WhatsApp."

---

### Slide 7: Peta Interaktif, Navigasi Kendaraan (Motor & Mobil) & Kompas Presisi
* **Judul Slide:** Navigasi Geospasial Multi-Moda & Kompas Digital
* **Poin Utama di Slide:**
  * **Peta Interaktif Wisata Bandung:** Penandaan marker warna-warni yang intuitif berdasarkan kategori destinasi di peta Bandung Raya.
  * **Routing Kendaraan Nyata (OpenStreetMap OSRM):**
    * 🛵 **Sepeda Motor:** Perhitungan rute cerdas non-tol melalui jalan arteri dan jalur alternatif tercepat.
    * 🚗 **Mobil:** Perhitungan rute jalan protokol utama dengan akses jalan tol bebas hambatan (Pasteur, Pasupati, dll.).
  * **Kompas Digital Presisi 360°:**
    * Orientasi kompas akurat dengan perhitungan derajat 0°–360° sesuai arah mata angin riil.
    * Menggunakan algoritma *Low-Pass Sensor Smoothing* pada data sensor gerak perangkat sehingga jarum kompas berputar mulus tanpa patah-patah (*anti-jitter*).
    * Penempatan antarmuka yang bersih dan harmonis tanpa menutupi panel navigasi dan tombol kontrol peta.
* **Rekomendasi Visual:**
  * Tangkapan layar peta interaktif dengan jalur rute rute jalan nyata (motor/mobil) bersanding dengan tampilan widget kompas digital modern.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk menunjang mobilitas di jalanan Bandung yang khas, BandungHub menyediakan navigasi rute jalan nyata yang membedakan jalur mobil dan motor. Sistem otomatis memilih rute non-tol untuk pengendara roda dua. Selain itu, kami menyematkan sensor kompas digital dengan algoritma low-pass smoothing, memastikan jarum berputar mulus 360 derajat dan akurat memandu orientasi arah wisatawan di lapangan."

---

### Slide 8: Ekosistem AI Cerdas & Integritas Ulasan Blockchain Sepolia
* **Judul Slide:** Ekosistem AI Cerdas & Integritas Ulasan Blockchain Sepolia
* **Poin Utama di Slide:**
  * 🤖 **Bandung AI Duo (Multimodal Vision & Smart Chatbot):**
    * 📷 **Bandung AI Lens:** Pengenalan visual cagar budaya & landmark bersejarah (Gedung Sate, Bosscha, Braga, Kawah Putih) melalui kamera dengan Google Gemini Vision + smart offline fallback.
    * 💬 **Bandung AI Travel Assistant:** Chatbot konsultasi wisata interaktif dengan penalaran cerdas yang adaptif (menjawab singkat & to-the-point untuk pertanyaan cepat, atau menyajikan saran mendalam saat diminta itinerary/tips liburan). Dilengkapi *domain guardrails* agar selalu fokus pada pariwisata Bandung.
  * ⛓️ **Integritas Ulasan Berbasis Ethereum Sepolia Blockchain (Real Web3 Anchor):**
    * Setiap ulasan yang dikirim pengguna dienkripsi dengan *SHA-256 Merkle Chaining* lokal dan secara otomatis di-anchor ke jaringan publik **Ethereum Sepolia Testnet**.
    * **Transparansi Tanpa Rekayasa:** Pengguna dan penguji dapat menyalin hash kriptografis serta Transaction Hash (TxHash) resmi.
    * **Verifikasi Publik Etherscan:** Tombol khusus *"Lihat di Sepolia Etherscan"* membuka penjelajah blok publik (`sepolia.etherscan.io`) untuk membuktikan transaksi benar-benar tercatat secara desentralisasi dan permanen.
* **Rekomendasi Visual:**
  * Cuplikan layar viewfinder Bandung AI Lens dan percakapan AI Chatbot di sebelah kiri.
  * Cuplikan kartu ulasan berlabel Blockchain, tombol Salin Hash, dan bukti konfirmasi transaksi di Sepolia Etherscan di sebelah kanan.
* **Speaker Notes (Naskah Pembicara):**
  > "Kepercayaan wisatawan terhadap ulasan adalah prioritas utama. BandungHub menghadirkan inovasi terdepan: setiap ulasan wisatawan tidak hanya disimpan di cloud Supabase, namun juga di-anchor langsung ke jaringan Blockchain publik Ethereum Sepolia. Dosen penguji dapat menyalin hash ulasan dan mengeceknya langsung di web Sepolia Etherscan sebagai bukti bahwa ulasan tersebut kekal dan bebas pemalsuan. Tak hanya itu, kami melengkapinya dengan Bandung AI Lens untuk memindai landmark visual serta AI Chatbot adaptif untuk konsultasi wisata instan."

---

### Slide 9: Ketahanan Data (Offline-First) & Keamanan Akun Berlapis
* **Judul Slide:** Ketahanan Data (Offline-First) & Keamanan Akun Berlapis
* **Poin Utama di Slide:**
  * **Arsitektur Dual-Storage (Offline Resilient):**
    * *Mode Online:* Sinkronisasi real-time via Supabase Cloud REST API & PostgreSQL.
    * *Mode Offline:* Pengalihan otomatis ke basis data lokal SQLite tanpa lag, layar putih, atau force close saat internet terputus.
    * *Antrean Sinkronisasi (Sync Queue):* Aksi saat offline (favorit, draft ulasan, rencana liburan) otomatis tersinkron begitu koneksi internet pulih.
  * **Keamanan Akun Berlapis Standar Perbankan (Bank-Style App Lock):**
    * Autentikasi aman melalui Supabase Auth (email & password terenkripsi).
    * Gerbang penguncian aplikasi dengan **PIN 6-digit keypad** & **Sensor Biometrik** (Fingerprint / Face Unlock).
    * *Background Inactivity Lock:* Sesi aplikasi otomatis terkunci ketika berpindah ke latar belakang selama lebih dari 2 menit.
  * **Pengelolaan Keamanan Terpadu & Proteksi Sesi di Profil:**
    * Fitur disatukan dalam satu menu **"Kelola PIN Keamanan"** yang bersih.
    * **Wajib Verifikasi PIN Lama:** Mengubah PIN, menghapus PIN, maupun menonaktifkan sensor biometrik mewajibkan verifikasi PIN lama terlebih dahulu untuk mencegah pembajakan akun.
    * Penataan identitas yang rapi: Badge *Terverifikasi* khusus disematkan pada akun dengan hak akses Administrator.
* **Rekomendasi Visual:**
  * Tangkapan layar antarmuka BankAppLockScreen (keypad PIN & prompt biometrik) serta dialog Kelola PIN di halaman Profil.
* **Speaker Notes (Naskah Pembicara):**
  > "Dari segi keandalan, aplikasi ini menerapkan konsep Offline-First sejati. Saat pengguna berada di kawasan blank spot pegunungan Bandung, seluruh data 38 destinasi tetap dapat diakses melalui SQLite lokal. Dari aspek keamanan, kami menerapkan standar perbankan dengan PIN 6-digit dan biometrik sidik jari. Di menu Profil, setiap tindakan sensitif seperti mengganti PIN atau mematikan biometrik diwajibkan melewati verifikasi PIN lama terlebih dahulu demi melindungi privasi pengguna."

---

### Slide 10: Pengujian Sistem & Jaminan Kualitas Kode
* **Judul Slide:** Pengujian Sistem & Jaminan Kualitas Kode
* **Poin Utama di Slide:**
  * 🧪 **Unit & Widget Testing Komprehensif:**
    * **28 Pengujian Otomatis (Automated Tests)**: Lulus 100% sempurna (`00:06 +28: All tests passed!`).
    * **Cakupan Pengujian Kritis:**
      * ✅ *Web3 & Blockchain:* Genesis block hashing, chaining integritas ulasan, dan audit data.
      * ✅ *AI Guardrails & Adaptation:* Pembatasan topik pariwisata Bandung dan fleksibilitas respon asisten.
      * ✅ *Bank Auth & Security:* Sesi kunci aplikasi, keypad PIN numerik, dan proteksi biometrik.
      * ✅ *Geospatial & Sensor:* Routing kendaraan (motor & mobil), sensor smoothing kompas 3D anti-flip, dan pemetaan arah mata angin.
      * ✅ *Personalization Engine & Widgets:* Penilaian rekomendasi preferensi dan rendering antarmuka utama.
  * 🛡️ **Bebas Error & Clean Code:** Terverifikasi lulus analisis linting Dart/Flutter (`flutter analyze`).
  * ⚡ **Performa Ringan:** Startup time di bawah 1,5 detik dengan pemakaian memori yang sangat hemat.
* **Rekomendasi Visual:**
  * Cuplikan layar terminal eksekusi `flutter test` yang menampilkan tulisan hijau: `00:06 +28: All tests passed!`.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk memastikan stabilitas dan keandalan sistem, kami menerapkan serangkaian pengujian otomatis menyeluruh. Sebanyak 28 skenario pengujian unit dan widget test berhasil lulus 100%. Pengujian ini mencakup keabsahan rantai hash ulasan blockchain, kepatuhan guardrail AI, keamanan gerbang PIN biometrik, logika navigasi jalan nyata, hingga penghalusan sensor kompas digital."

---

### Slide 11: Demo Alur Pengguna (User Journey)
* **Judul Slide:** Alur Demonstrasi Pengguna (User Journey)
* **Poin Utama di Slide:**
  * **Langkah 1 (Masuk & Konsultasi AI):** Masuk dengan aman -> Eksplorasi 38 destinasi atau minta rekomendasi wisata ke AI Chatbot Kang Bandung.
  * **Langkah 2 (Pindai AI Lens):** Arahkan kamera ke landmark ikonik (misal foto Gedung Sate) -> AI Lens menyajikan sejarah & tips kunjungan.
  * **Langkah 3 (Susun Rencana & Cek Biaya):** Buat itinerary harian -> Cek konversi mata uang (misal Ringgit atau Dollar) & sesuaikan zona waktu -> Ekspor ke PDF / Teks WhatsApp.
  * **Langkah 4 (Navigasi Rute & Kompas):** Buka rute jalan riil (pilih mode Sepeda Motor non-tol atau Mobil) -> Pandu orientasi arah dengan kompas digital presisi.
  * **Langkah 5 (Ulasan Blockchain & Uji Keamanan):** Kirim ulasan ulasan wisata -> Tunjukkan hash kriptografis & tautan Etherscan Sepolia -> Masuk ke Profil untuk mendemokan proteksi Kelola PIN & Biometrik.
* **Rekomendasi Visual:**
  * Diagram alir 5 langkah pengalaman pengguna yang dilengkapi miniatur tangkapan layar aplikasi di masing-masing tahap.
* **Speaker Notes (Naskah Pembicara):**
  > "Dalam sesi demonstrasi langsung nanti, saya akan mempraktikkan alur nyata seorang wisatawan: mulai dari berkonsultasi rencana wisata dengan AI Chatbot, memindai objek bersejarah lewat AI Lens, menyusun rencana perjalanan lengkap dengan konversi mata uang dan ekspor PDF, menavigasikan rute peta dan kompas halus, mengirim ulasan terverifikasi di Sepolia Etherscan, serta memperlihatkan proteksi keamanan PIN di menu Profil."

---

### Slide 12: Kesimpulan & Sesi Tanya Jawab (Q&A)
* **Judul Slide:** Kesimpulan & Nilai Tambah Inovasi
* **Poin Utama di Slide:**
  * 🌟 **Solusi Pariwisata Komprehensif:** Menyatukan katalog terkurasi, kecerdasan buatan multimodal (Lens & Chat), navigasi jalan nyata, dan perencana anggaran global dalam satu aplikasi terpadu.
  * 🌟 **Pionir Transparansi Web3:** Integrasi blockchain publik Ethereum Sepolia memberikan jaminan bahwa ulasan wisatawan otentik, transparan, dan tidak dapat dimanipulasi.
  * 🌟 **Keandalan & Standar Keamanan Tinggi:** Arsitektur Offline-First yang siap menghadapi blank spot pegunungan serta keamanan berlapis standar aplikasi perbankan.
  * 🌟 **Kesiapan Rilis Teruji:** Lulus 28/28 automated tests dengan performa responsif dan antarmuka modern Material 3.
  * **Terima Kasih / Sesi Tanya Jawab (Q&A)**
  * Kontak: [Email Anda] | Repositori GitHub: [Link Repo GitHub Anda]
* **Rekomendasi Visual:**
  * Mockup 3 smartphone berdampingan menampilkan Beranda, Peta Navigasi, dan Kartu Ulasan Blockchain Sepolia. Teks penutup: *"Terima Kasih - Sesi Tanya Jawab (Q&A)"*.
* **Speaker Notes (Naskah Pembicara):**
  > "Sebagai penutup, BandungHub membuktikan bagaimana perpaduan teknologi mobile modern, kecerdasan buatan, dan blockchain dapat mentransformasi pengalaman berwisata menjadi lebih praktis, aman, dan terpercaya. Demikian pemaparan presentasi dari saya, terima kasih banyak atas perhatian Bapak/Ibu dosen penguji serta rekan-rekan sekalian. Waktu dan kesempatan saya persilakan untuk sesi tanya jawab."

---

## 💡 TIPS STRATEGIS DEMO PRESENTASI UNTUK MAHASISWA:
1. **Waktu Pemaparan Ideal:**
   * 7–8 menit presentasi slide (fokus pada solusi masalah, arsitektur, dan inovasi Sepolia Blockchain + AI).
   * 5–7 menit demonstrasi langsung (*live demo*) pada emulator Android atau smartphone fisik.
2. **Poin Emas Pembuktian di Hadapan Dosen Penguji:**
   * **Demo Mode Pesawat (Airplane Mode):** Nyalakan mode pesawat di HP/emulator, buka aplikasi -> buktikan aplikasi tetap lancar membuka katalog 38 destinasi dan itinerary (bukti Offline-First SQLite berjalan nyata).
   * **Demo Blockchain Sepolia:** Tulis sebuah ulasan di salah satu destinasi, buka detail ulasan, perlihatkan kode Hash / TxHash ulasan yang tercetak, lalu klik tombol *"Lihat di Sepolia Etherscan"*. Tunjukkan kepada dosen bahwa transaksi ulasan benar-benar terdaftar di blockchain publik Ethereum Sepolia.
   * **Demo Responsif AI Chatbot:** Tanyakan pertanyaan sederhana (misal: *"Batagor enak di mana?"*) untuk menunjukkan jawaban ringkas to-the-point, lalu tanyakan *"Rencanakan liburan 1 hari di Lembang"* untuk memperlihatkan respon terstruktur dan komprehensif.
   * **Demo Keamanan Profil:** Masuk ke Profil -> Buka *Kelola PIN Keamanan* -> Tunjukkan bahwa sistem meminta verifikasi PIN lama sebelum mengizinkan penggantian atau penonaktifan biometrik.
