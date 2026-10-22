# DESIGN.md — BandungHub Design System & Direction

> **Tujuan**: Menetapkan identitas visual, filosofi warna, tipografi, dan arah desain yang orisinal, berkarakter, dan bebas dari generic AI slop untuk aplikasi pariwisata **BandungHub**.

---

## 1. Identitas & Karakter (Soul & Personality)
- **Nama Produk**: BandungHub
- **Tagline**: Panduan & Itinerary Wisata Bandung Raya
- **Kepribadian**:
  - **Someah**: Hangat, bersahabat, dan menyambut wargi maupun wisatawan luar kota dengan ramah.
  - **Asri & Segar**: Mencerminkan nuansa pegunungan sejuk Parahyangan, perkebunan teh, dan warisan kolonial Art Deco.
  - **Terarah & Andal**: Menyajikan informasi destinasi, rute kompas, dan estimasi biaya secara faktual tanpa klaim hiperbolis.

---

## 2. Palet Warna (Color System)
Palet warna dibatasi pada 2 warna utama + 1 aksen fungsional guna menjaga konsistensi identitas (R-29):

| Token | Hex | Makna & Penggunaan |
|---|---|---|
| **Primary (Parahyangan Pine)** | `#1B4931` | Hijau pinus sejuk melambangkan alam Tangkuban Parahu, Ciwidey, dan hutan Lembang. Digunakan untuk AppBar, primary CTA, dan status aktif. |
| **Secondary (Sundanese Ochre)** | `#D97706` | Oranye tembaga hangat melambangkan keramahan budaya Sunda, kuliner tradisional, dan senja Punclut. |
| **Accent / Info (Braga Blue)** | `#0284C7` | Biru langit jernih untuk navigasi peta live dan indikator GPS/kompas. |
| **Background Light** | `#F8FAFC` | Latar belakang bersih dengan kontras tinggi terhadap teks. |
| **Background Dark** | `#0F172A` | Mode gelap malam kota Bandung yang nyaman di mata tanpa warna neon palsu. |

---

## 3. Tipografi & Hirarki Teks
- **Body & Headings**: Humanist Sans (Clean, legible, modern).
- **Hirarki Ukuran**:
  - H1 / Title Layar: 20–22px, Bold, tracking normal (tanpa uppercase monospace ekstrim).
  - H2 / Section Header: 16–18px, Semi-Bold.
  - Body Text: 14–15px, Regular/Medium, line-height 1.45.
  - Caption & Meta: 12px, Medium, warna teks sekunder yang memenuhi kontras WCAG AA (> 4.5:1).

---

## 4. Antislop Dials
Sesuai standar antislop Part 3:
- **ENERGY: 2 (Balanced)**
  - UI bersahabat, segar, dan berenergi positif khas kota wisata, tanpa animasi berlebihan yang mengganggu navigasi.
- **RHYTHM: 2 (Consistent with subtle accents)**
  - Susunan halaman konsisten: Header informasi -> Kartu destinasi berfoto rill -> Filter chips interaktif -> Aksi navigasi cepat.
- **MOTION: 2 (Micro-interactions)**
  - Transisi tab halus, animasi kompas berbasis sensor orientasi perangkat, dan tombol dengan feedback visual instan.

---

## 5. Standar Craftsmanship & Aksesibilitas
1. **Bebas Em Dash (`—`)**: Seluruh kalimat ditulis dengan tanda baca natural (titik dua, koma, kurung) sesuai aturan `R-02`.
2. **Bebas Buzzword AI**: Menghindari label klise seperti *"Smart Companion"*, *"AI Powered"*, atau *"Rekomendasi Cerdas"*; menggunakan label fungsional yang lugas (`R-16`).
3. **Ikon Relevan Konten**: Menghindari generic sparkle AI (`Icons.auto_awesome`), menggunakan ikon domain pariwisata nyata seperti `Icons.tune_rounded`, `Icons.place_rounded`, dan `Icons.map_rounded` (`R-04`).
4. **Touch Target Nyaman**: Semua tombol interaktif berukuran minimal 48 x 48 dp untuk kemudahan navigasi satu tangan di perjalanan (`R-03`).
5. **Dukungan Penuh Dua Tema**: Tema Terang (*Light*) dan Tema Gelap (*Dark*) teruji memiliki kontras tajam dan fungsionalitas seimbang (`R-21`, `R-34`).
