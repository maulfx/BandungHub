# PANDUAN SLIDE PRESENTASI PROJEK AKHIR
# BandungHub: Smart Tourism & Heritage Navigator Kota Bandung

> **Catatan Penggunaan:**
> Dokumen ini disusun sebagai panduan lengkap materi slide PowerPoint (PPT) / Canva / Google Slides. Setiap slide telah dilengkapi dengan **Isi Visual Slide (Poin Ringkas)**, **Catatan Pembicara (Speaker Notes/Naskah Presentasi)**, dan **Rekomendasi Visual/Tangkapan Layar**.

---

## DAFTAR ISI SLIDE
1. [Slide 1: Judul & Identitas Proyek](#slide-1-judul--identitas-proyek)
2. [Slide 2: Latar Belakang & Rumusan Masalah](#slide-2-latar-belakang--rumusan-masalah)
3. [Slide 3: Solusi Produk - BandungHub](#slide-3-solusi-produk---bandunghub)
4. [Slide 4: Arsitektur Sistem & Teknologi](#slide-4-arsitektur-sistem--teknologi)
5. [Slide 5: Katalog 38 Destinasi Wisata & Budaya](#slide-5-katalog-38-destinasi-wisata--budaya)
6. [Slide 6: Rencana Perjalanan (Itinerary Planner) & Ekspor Dokumen](#slide-6-rencana-perjalanan-itinerary-planner--ekspor-dokumen)
7. [Slide 7: Peta Interaktif, Navigasi Multi-Moda & Kompas](#slide-7-peta-interaktif-navigasi-multi-moda--kompas)
8. [Slide 8: Ulasan Wisatawan & Rekomendasi Cerdas](#slide-8-ulasan-wisatawan--rekomendasi-cerdas)
9. [Slide 9: Arsitektur Offline-First & Keamanan Akun](#slide-9-arsitektur-offline-first--keamanan-akun)
10. [Slide 10: Pengujian Sistem & Jaminan Kualitas](#slide-10-pengujian-sistem--jaminan-kualitas)
11. [Slide 11: Demo Alur Pengguna (User Journey)](#slide-11-demo-alur-pengguna-user-journey)
12. [Slide 12: Kesimpulan & Sesi Tanya Jawab (Q&A)](#slide-12-kesimpulan--sesi-tanya-jawab-qa)

---

### Slide 1: Judul & Identitas Proyek
* **Judul Slide:** BandungHub
* **Subjudul:** Aplikasi Mobile Smart Tourism & Heritage Navigator Kota Bandung Berbasis Flutter & Supabase Cloud
* **Poin Utama di Slide:**
  * Proyek Akhir Praktikum Pemrograman Mobile
  * Platform: Mobile (Android & iOS)
  * Framework: Flutter 3.x (Dart)
  * Backend: Supabase Cloud Database & Auth + Local SQLite Storage
  * Nama Pengembang / Tim: [Nama Anda / NIM]
* **Rekomendasi Visual:**
  * Logo BandungHub di bagian tengah/kiri.
  * Mockup layar HP menampilkan beranda BandungHub dengan foto Gedung Sate / Braga.
* **Speaker Notes (Naskah Pembicara):**
  > "Selamat pagi/siang Bapak/Ibu dosen penguji serta rekan-rekan sekalian. Pada kesempatan kali ini, saya akan mempresentasikan karya Projek Akhir Pemrograman Mobile saya yang berjudul **BandungHub: Smart Tourism & Heritage Navigator Kota Bandung**. Aplikasi ini dirancang sebagai solusi navigasi dan eksplorasi wisata pintar yang memadukan keindahan budaya, efisiensi perencanaan perjalanan, dan teknologi cloud modern."

---

### Slide 2: Latar Belakang & Rumusan Masalah
* **Judul Slide:** Latar Belakang & Tantangan Wisatawan
* **Poin Utama di Slide:**
  * 🔴 **Informasi Tersebar:** Informasi tiket, jam operasional, dan lokasi wisata Bandung sering tidak mutakhir dan terpecah di berbagai media sosial.
  * 🔴 **Kendala Jaringan di Daerah Wisata:** Sinyal internet sering kali lemah saat wisatawan berada di daerah pegunungan (Ciwidey, Lembang, Pangalengan).
  * 🔴 **Perencanaan Perjalanan yang Rumit:** Wisatawan kesulitan memperkirakan rute terbaik, alokasi waktu per hari, dan total estimasi anggaran liburan.
  * 🔴 **Ulasan Tidak Transparan:** Banyak ulasan daring yang tidak terverifikasi atau tidak mencerminkan kondisi lapangan sebenarnya.
* **Rekomendasi Visual:**
  * Ilustrasi 4 ikon masalah (Koneksi lemah, Rute macet, Jadwal bentrok, Ulasan bias).
* **Speaker Notes (Naskah Pembicara):**
  > "Kota Bandung merupakan salah satu destinasi wisata terfavorit di Indonesia. Namun, wisatawan kerap menghadapi masalah nyata: sinyal internet yang drop saat berada di daerah Lembang atau Kawah Putih, perencanaan anggaran yang sering meleset, dan informasi rute yang membingungkan. Berangkat dari masalah tersebut, kami merancang BandungHub dengan pendekatan offline-first dan sinkronisasi cloud real-time."

---

### Slide 3: Solusi Produk - BandungHub
* **Judul Slide:** Solusi: BandungHub Smart Tourism
* **Poin Utama di Slide:**
  * 🟢 **38 Destinasi Terkurasi Lengkap:** 5 kategori (Sejarah, Alam, Keluarga, Kuliner, Hiburan).
  * 🟢 **Perencana Perjalanan Cerdas (Itinerary):** Perhitungan estimasi budget (tiket, transport, makan) secara otomatis.
  * 🟢 **Peta & Rute Multi-Moda:** Navigasi interaktif mobil, motor, sepeda, dan jalan kaki + sensor kompas digital halus.
  * 🟢 **Sinkronisasi Cloud & Offline-First:** Berjalan lancar tanpa internet, otomatis tersinkron ke Supabase saat online.
  * 🟢 **Ekspor Fleksibel:** Simpan dan bagikan rencana perjalanan dalam format Catatan Teks atau PDF resmi.
* **Rekomendasi Visual:**
  * Diagram showcase 5 fitur utama mengelilingi ikon smartphone BandungHub.
* **Speaker Notes (Naskah Pembicara):**
  > "BandungHub hadir sebagai asisten perjalanan serba bisa. Aplikasi ini mengintegrasikan seluruh data destinasi Bandung, menyediakan fitur rencana perjalanan yang dapat dihitung anggarannya secara otomatis, peta rute dengan berbagai pilihan moda transportasi, serta fitur ekspor PDF dan teks agar wisatawan dapat dengan mudah membagikan rencananya kepada keluarga atau rombongan."

---

### Slide 4: Arsitektur Sistem & Teknologi
* **Judul Slide:** Arsitektur Sistem & Teknologi Modern
* **Poin Utama di Slide:**
  * **Frontend Mobile:** Flutter (Dart) dengan arsitektur *Clean Code* & *Repository Pattern*.
  * **Cloud Database & Auth:** Supabase Cloud (PostgreSQL) untuk autentikasi user, katalog wisata, review, dan cloud itinerary.
  * **Local Resilient Database:** SQLite (`sqflite`) & `SharedPreferences` untuk ketahanan data saat offline.
  * **Map & Geospatial:** `flutter_map` + OpenStreetMap API untuk peta vektor ringan tanpa ketergantungan berbayar Google Maps API.
  * **Hardware Sensor Integration:** Akses sensor orientasi magnetometer dengan *low-pass filter* untuk kompas yang presisi dan halus.
* **Rekomendasi Visual:**
  * Bagan alir arsitektur:
    `Flutter UI -> Repositories -> [Supabase Cloud API (Online)] <-> [Local SQLite Cache (Offline)]`
* **Speaker Notes (Naskah Pembicara):**
  > "Dari segi arsitektur teknis, aplikasi ini dibangun di atas Flutter dengan pola Repository Pattern yang modular. Kami menerapkan konsep Hybrid Offline-First: aplikasi menggunakan SQLite lokal di HP untuk menyimpan data saat tidak ada sinyal, namun otomatis tersinkronisasi dua arah ke database Supabase Cloud di internet ketika perangkat terhubung secara online."

---

### Slide 5: Katalog 38 Destinasi Wisata & Budaya
* **Judul Slide:** Katalog Eksplorasi 38 Destinasi Terkurasi
* **Poin Utama di Slide:**
  * **5 Kategori Tematik:**
    * 🏛️ **Sejarah & Budaya:** Gedung Sate, Museum KAA, Museum Geologi, Bosscha, dll.
    * 🌲 **Wisata Alam:** Kawah Putih, Tangkuban Parahu, Tahura Juanda, Ranca Upas, Tebing Keraton.
    * 👨‍👩‍👧‍👦 **Wisata Keluarga:** Saung Angklung Udjo, Floating Market, Farmhouse Susu, Lembang Park & Zoo.
    * 🍜 **Kuliner Legendaris:** Pasar Punclut, Sudirman Street, Kopi Aroma Banceuy, Batagor Kingsley.
    * 🎡 **Hiburan Modern:** Trans Studio Bandung, Kiara Artha Park, Paris Van Java.
  * **Kelengkapan Metadata:** Koordinat GPS, jam operasional, harga tiket masuk, rating riil, dan galeri foto HD.
  * **Fitur Filter Pintar:** Pencarian instan berdasarkan nama, kategori, batas anggaran, dan favorit.
* **Rekomendasi Visual:**
  * Cuplikan layar halaman **Katalog & Eksplorasi** dengan filter chip dan kartu destinasi.
* **Speaker Notes (Naskah Pembicara):**
  > "BandungHub memiliki database 38 destinasi resmi yang lengkap dan terkurasi. Setiap destinasi memiliki informasi detail: jam buka-tutup, harga tiket, lokasi GPS, hingga foto resolusi tinggi. Pengguna juga dapat memfilter destinasi sesuai anggaran tiket yang dimiliki, mempermudah wisatawan merencanakan liburan sesuai kantong."

---

### Slide 6: Rencana Perjalanan (Itinerary Planner) & Ekspor Dokumen
* **Judul Slide:** Rencana Perjalanan Pintar & Ekspor Dokumen
* **Poin Utama di Slide:**
  * **Penyusunan Rencana Harian:** Pengelompokan destinasi berdasarkan hari (Hari 1, Hari 2, dst.) dan jam kunjungan.
  * **Kalkulator Budget Otomatis:** Menghitung otomatis total tiket, alokasi kuliner, transportasi, dan biaya tambahan per orang.
  * **Opsi Ekspor Fleksibel:**
    * 📄 **Format PDF Resmi:** Tampilan dokumen rapi siap cetak lengkap dengan tabel rincian biaya dan jadwal.
    * 📝 **Format Catatan Teks:** Teks ringkas yang siap dibagikan via WhatsApp, Telegram, atau aplikasi catatan.
  * **Sinkronisasi Akun Cloud:** Rencana perjalanan tersimpan di Supabase Cloud terikat dengan ID pengguna, aman walau ganti perangkat.
* **Rekomendasi Visual:**
  * Mockup layar detail rencana perjalanan bersanding dengan pratinjau dokumen PDF yang dihasilkan.
* **Speaker Notes (Naskah Pembicara):**
  > "Fitur unggulan lainnya adalah Perencana Perjalanan. Pengguna dapat membuat agenda liburan per hari, memilih destinasi yang ingin dikunjungi, dan aplikasi akan secara otomatis menghitung estimasi biaya total per orang. Hasil rencana ini dapat diekspor menjadi dokumen PDF resmi atau dibagikan sebagai catatan teks ke rombongan perjalanan melalui WhatsApp."

---

### Slide 7: Peta Interaktif, Navigasi Multi-Moda & Kompas
* **Judul Slide:** Navigasi Geospasial & Kompas Digital
* **Poin Utama di Slide:**
  * **Peta Interaktif Wisata:** Penandaan marker warna-warni berdasarkan kategori destinasi di peta Bandung.
  * **Routing Multi-Moda Transportasi:**
    * 🚗 Mobil (Rute jalan raya utama)
    * 🛵 Sepeda Motor (Akses rute cepat)
    * 🚴 Sepeda (Jalur olahraga santai)
    * 🚶 Pejalan Kaki (Trotoar kota ramah pedestrian)
  * **Kompas Digital Minimalis:**
    * Desain modern, bersih, dan informatif.
    * Didukung algoritma *Low-Pass Sensor Smoothing* agar putaran jarum kompas bergerak mulus tanpa patah-patah.
* **Rekomendasi Visual:**
  * Screenshot peta navigasi rute di atas dan widget kompas digital di bawah.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk memudahkan mobilitas, BandungHub menyediakan peta interaktif lengkap dengan penunjuk rute multi-moda: mobil, motor, sepeda, dan jalan kaki. Kami juga menyematkan kompas digital dengan algoritma sensor smoothing, sehingga pergerakan jarum kompas saat pengguna mengarahkan HP di alam terbuka bergerak sangat halus dan responsif."

---

### Slide 8: Ulasan Wisatawan & Rekomendasi Cerdas
* **Judul Slide:** Ulasan Terpercaya & Rekomendasi Berbasis Preferensi
* **Poin Utama di Slide:**
  * **Sistem Ulasan Real-Time di Supabase:** Pengguna dapat memberikan ulasan, rating bintang 1-5, dan foto pengalaman langsung ke cloud.
  * **Integritas Ulasan Kriptografis (Cryptographic Hash):** Setiap ulasan diamankan dengan rantai hash anti-manipulasi data (*blockchain-inspired audit ledger*).
  * **Statistik Riil & Rating Transparan:** Menyajikan distribusi bintang ulasan dan persentase kepuasan pengunjung.
  * **Rekomendasi Cerdas Sesuai Preferensi:** Memberikan saran destinasi terbaik berdasarkan budget, preferensi tema wisata, dan waktu luang pengguna.
* **Rekomendasi Visual:**
  * Tangkapan layar lembar ulasan destinasi + visualisasi grafik rating bintang.
* **Speaker Notes (Naskah Pembicara):**
  > "Keaslian ulasan adalah hal krusial bagi wisatawan. Di BandungHub, setiap ulasan yang dikirim langsung tersimpan di Supabase Cloud dan diverifikasi dengan pencatatan hash kriptografis guna mencegah manipulasi ulasan. Selain itu, terdapat sistem rekomendasi berbasis preferensi pengguna yang menyesuaikan saran wisata berdasarkan budget dan ketertarikan pribadi."

---

### Slide 9: Arsitektur Offline-First & Keamanan Akun
* **Judul Slide:** Ketahanan Data (Offline-First) & Keamanan Akun
* **Poin Utama di Slide:**
  * **Arsitektur Dual-Storage (Offline Resilient):**
    * *Online:* Mengambil data langsung dari Supabase REST API & PostgreSQL Cloud.
    * *Offline:* Otomatis beralih ke cache lokal SQLite tanpa crash atau layar kosong.
  * **Antrian Sinkronisasi Otomatis:** Aksi saat offline (favorit, ulasan, rencana) masuk antrean dan tersinkron saat internet pulih.
  * **Keamanan Akun Berlapis (Bank-Style Security):**
    * Autentikasi Supabase Auth dengan email & password terenkripsi.
    * Penguncian aplikasi dengan PIN 6-digit & Sensor Biometrik (Fingerprint/Face Unlock).
    * Auto-lock session saat aplikasi berpindah ke latar belakang (*background*).
* **Rekomendasi Visual:**
  * Screenshot layar kunci PIN / Biometrik dan panel kontrol penyimpanan cache di halaman Profil.
* **Speaker Notes (Naskah Pembicara):**
  > "Ketahanan dan keamanan aplikasi menjadi prioritas utama. Ketika pengguna berada di pelosok tanpa sinyal internet, aplikasi tetap 100% fungsional menggunakan cache lokal. Dari sisi keamanan, aplikasi dilengkapi sistem penguncian PIN 6-digit dan biometrik sidik jari layaknya standar aplikasi perbankan modern untuk melindungi data pribadi dan rencana perjalanan pengguna."

---

### Slide 10: Pengujian Sistem & Jaminan Kualitas
* **Judul Slide:** Pengujian Sistem & Jaminan Kualitas Kode
* **Poin Utama di Slide:**
  * 🧪 **Unit & Widget Testing Komprehensif:**
    * **24 Pengujian Otomatis (Automated Tests)**: Lulus 100% (`All tests passed!`).
    * Cakupan pengujian: Routing Service, Bank Auth Lock, Sensor Smoothing, Integritas Blockchain Review, Personalization Engine, dan Widget Navigasi.
  * 🛡️ **Validasi Linting & Bebas Error:** Mengikuti aturan konvensi Dart/Flutter (*clean code practices*).
  * ⚡ **Performa Responsif:** Waktu muat awal (*startup time*) di bawah 1,5 detik dengan konsumsi memori hemat.
* **Rekomendasi Visual:**
  * Cuplikan layar terminal eksekusi `flutter test` yang menampilkan tulisan hijau: `00:04 +24: All tests passed!`.
* **Speaker Notes (Naskah Pembicara):**
  > "Untuk menjamin kualitas dan stabilitas perangkat lunak, seluruh fungsionalitas kritis diuji menggunakan suite Automated Test. Sebanyak 24 skenario pengujian unit dan widget test berhasil lulus 100%, mencakup logika routing, keamanan PIN biometrik, kalkulasi itinerary, hingga pengujian integritas database."

---

### Slide 11: Demo Alur Pengguna (User Journey)
* **Judul Slide:** Alur Demonstrasi Pengguna (User Journey)
* **Poin Utama di Slide:**
  * **Langkah 1 (Masuk & Eksplorasi):** Login pengguna -> Jelajahi 38 destinasi di Beranda atau Peta.
  * **Langkah 2 (Rencana Perjalanan):** Buat agenda liburan baru -> Tambahkan destinasi per hari -> Cek estimasi anggaran total.
  * **Langkah 3 (Navigasi):** Buka rute destinasi -> Pilih moda mobil/jalan kaki -> Cek arah dengan kompas.
  * **Langkah 4 (Ulasan & Ekspor):** Tulis ulasan pengalaman ke Supabase Cloud -> Ekspor rencana perjalanan ke format PDF / Catatan Teks.
* **Rekomendasi Visual:**
  * Diagram 4 langkah alur pengguna berurutan dilengkapi miniatur screenshot aplikasi di setiap langkahnya.
* **Speaker Notes (Naskah Pembicara):**
  > "Berikut adalah skenario singkat pengalaman pengguna: Pengguna masuk ke akun, mencari destinasi wisata favorit di Bandung, menyusunnya ke dalam rencana perjalanan 2 hari lengkap dengan kalkulasi biaya, membuka navigasi peta dan kompas menuju lokasi, memberikan review langsung ke Supabase, dan mengekspor dokumen perjalanannya ke file PDF."

---

### Slide 12: Kesimpulan & Sesi Tanya Jawab (Q&A)
* **Judul Slide:** Kesimpulan & Nilai Tambah Aplikasi
* **Poin Utama di Slide:**
  * 🌟 **Solusi Komprehensif:** Menggabungkan katalog wisata terkurasi, navigasi multi-moda, dan perencana anggaran dalam satu aplikasi terpadu.
  * 🌟 **Teknologi Handal:** Kombinasi tangguh antara Flutter, Supabase Cloud, dan Offline SQLite Storage.
  * 🌟 **Kesiapan Rilis:** Telah melalui pengujian menyeluruh (24/24 tests passed) dengan desain antarmuka modern yang adaptif.
  * **Terima Kasih / Sesi Tanya Jawab (Q&A)**
  * Kontak: [Email Anda] | GitHub: [Link Repo GitHub Anda]
* **Rekomendasi Visual:**
  * Tampilan mockup 3 smartphone berdampingan menampilkan halaman Beranda, Peta, dan Rencana Perjalanan. Teks besar: *"Terima Kasih - Ada Pertanyaan?"*
* **Speaker Notes (Naskah Pembicara):**
  > "Sebagai penutup, aplikasi BandungHub bukan sekadar katalog wisata biasa, melainkan platform Smart Tourism terintegrasi yang menghadirkan kepraktisan, keandalan offline, dan keamanan bagi wisatawan yang berkunjung ke Kota Bandung. Sekian presentasi dari saya, terima kasih banyak atas perhatian Bapak/Ibu dosen dan rekan-rekan sekalian. Waktu dan tempat saya persilakan untuk sesi tanya jawab."

---

## TIPS TAMBAHAN UNTUK PRESENTASI:
1. **Durasi Waktu:** Alokasikan waktu sekitar 7–10 menit untuk pemaparan slide dan 5 menit untuk demonstrasi langsung (*live demo*) di emulator atau HP fisik.
2. **Koneksi Live Demo:** Tunjukkan bahwa ketika HP beralih ke mode Airplane (tanpa internet), aplikasi tetap bisa membuka katalog 38 destinasi dan melihat rencana perjalanan (bukti arsitektur offline-first bekerja).
3. **Poin Plus untuk Dosen:** Jelaskan bagaimana Supabase Cloud berperan sebagai backend serverless PostgreSQL yang mengelola ulasan real-time dan sinkronisasi itinerary pengguna.
