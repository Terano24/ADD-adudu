# LAPORAN UTS KELOMPOK — ANALISIS DATA DISKRIT (ADD)
**Analisis Asosiasi Multivariat & Pemodelan Regresi Nominal (Dataset Penjualan Frozen Food 2020)**  
*Institut Teknologi Sepuluh Nopember — Departemen Sistem Informasi*

---

## Ringkasan Eksekutif & Metodologi
Berdasarkan investigasi 10 rumusan pertanyaan asosiasi pada data transaksi penjualan frozen food (N = 6.740 transaksi), terkonfirmasi **4 nomor pertanyaan yang memiliki asosiasi signifikan secara statistik (CONFIRMED)**:
1. **Nomor 3**: Asosiasi antara **Merk** (BRAND) dengan **Satuan barang yang dijual** (SATUAN).
2. **Nomor 6**: Asosiasi antara **Merk** (BRAND) dengan **Produk yang dijual** (NAMA_BARANG).
3. **Nomor 8**: Asosiasi antara **Produk** (NAMA_BARANG) dengan **Satuan barang yang dibeli** (SATUAN).
4. **Nomor 10**: Asosiasi antara **Pembeli** (PELANGGAN) dengan **Produk yang dibeli** (NAMA_BARANG).

**Metodologi Pengujian & Pemodelan**:
- **Uji Independensi Chi-Square (χ²)**: Menguji apakah kedua variabel saling bebas (H₀) atau terikat asosiasi (H₁) pada taraf signifikansi α = 0,05.
- **Kekuatan Efek Asosiasi (Cramér's V)**: Mengukur derajat asosiasi nominal (0 = independen sempurna, 1 = deterministik sempurna).
- **Pemodelan Regresi Nominal (2 Arah Persamaan per Nomor)**: Mengestimasi parameter hubungan linear/nominal bersyarat antara dua entitas kategorik:
  - **Arah 1 (A → B)**: Memprediksi variabel B ketika entitas spesifik A diketahui.
  - **Arah 2 (B → A)**: Memprediksi variabel A ketika entitas spesifik B diketahui.

---

## 1. NOMOR 3: Merk Tertentu (BRAND) vs Satuan Barang yang Dijual (SATUAN)

### A. Pembuktian Asosiasi
- **Uji Statistik**: χ² = 22.941,68; df = 438; p-value = 0,0000 (p < 0,0001).
- **Cramér's V**: 0,7532 (**Asosiasi Sangat Kuat**).
- **Bukti Tabel Kontingensi (Frekuensi Observasi)**:
  - Merk JOFRANS: Terbagi atas DUS (63,7% / 747 transaksi) dan PACK (36,3% / 425 transaksi).
  - Merk OKEY: Didominasi DUS (76,8% / 591 transaksi) dan PACK (23,2% / 179 transaksi).
  - Merk MINAKU: Terbagi atas DUS (69,0% / 368 transaksi) dan PACK (31,0% / 165 transaksi).
  - Merk MIAMI: 100% terjual dalam kemasan PAIL (410 transaksi, 0 dus/pack).
  - Merk DEN: Terbagi atas PACK (62,8% / 226 transaksi) dan BAL (37,2% / 134 transaksi) tanpa pernah ada DUS.
  - Merk DELMONTE: Terjual dalam kemasan jerigen JRG (44,0% / 11 transaksi), DUS (24,0%), dan PACK (24,0%).
  - Merk CONE: 100% terjual dalam satuan bungkus BKS (55 transaksi).
- **Kesimpulan**: **Tolak H₀**. Satuan kemasan terbukti secara empiris sangat bergantung pada merk dagangnya.

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Satuan dari Merk Tertentu)**:
   - *Kasus*: Bila Merk JOFRANS dijual, satuan apa yang kemungkinan besar keluar?
   - **Persamaan Empiris**:
     Merk (JOFRANS) = 3,65 × [DUS] + 2,10 × [PACK] + 0,00 × [PAIL] + ε
     *(Proporsi Kemunculan: P(Satuan | JOFRANS) = 0,637 [DUS] + 0,363 [PACK] + ε)*
   - *Interpretasi*: Transaksi merk JOFRANS memiliki probabilitas 63,7% keluar dalam satuan DUS (rata-rata 3,65 dus per transaksi) dan 36,3% dalam PACK (rata-rata 2,10 pack).
2. **Jawaban 2 (Menebak Merk dari Satuan Kemasan Tertentu)**:
   - *Kasus*: Bila ada penjualan dengan satuan PAIL (Ember es krim) atau BAL (Karung), merk apa yang kemungkinan besar dijual?
   - **Persamaan Empiris (Satuan PAIL)**:
     Satuan (PAIL) = 0,804 × [MIAMI] + 0,169 × [INDOESKRIM] + 0,027 × [DIAMOND] + ε
   - **Persamaan Alternatif (Satuan BAL)**:
     Satuan (BAL) = 0,838 × [DEN] + 0,138 × [PK] + 0,025 × [KEI] + ε
   - *Interpretasi*: Jika gudang mengeluarkan satuan PAIL, 80,4% dipastikan merk MIAMI dan 16,9% INDOESKRIM. Jika gudang mengeluarkan satuan BAL, 83,8% dipastikan merk sosis DEN dan 13,8% merk PK.

---

## 2. NOMOR 6: Merk Tertentu (BRAND) vs Produk yang Dijual (NAMA_BARANG)

### A. Pembuktian Asosiasi
- **Uji Statistik**: χ² = 492.020,00; df = 19.491; p-value = 0,0000 (p < 0,0001).
- **Cramér's V**: 1,0000 (**Asosiasi Deterministik Sempurna**).
- **Bukti Tabel Kontingensi (Frekuensi Observasi)**:
  - Setiap produk 100% diproduksi secara eksklusif oleh satu merk induk tunggal (struktur blok ortogonal sempurna).
  - MINAKU OTAK OTAK 500 GR: 100% dinaungi merk MINAKU (378 transaksi).
  - OKEY SOSIS 500 GR: 100% dinaungi merk OKEY (288 transaksi).
  - JOFRANS NUGGET AYAM HATI 500 GR: 100% dinaungi merk JOFRANS (244 transaksi).
  - MIAMI ICE CREAM REG. NEAPOLITAN 8 LT: 100% dinaungi merk MIAMI (174 transaksi).
- **Kesimpulan**: **Tolak H₀**. Terdapat hubungan asosiasi deterministik murni (struktur hierarki katalog produk).

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Komposisi Produk dari Merk Tertentu)**:
   - *Kasus*: Bila Merk MINAKU dijual, produk apa yang kemungkinan besar menyumbang penjualan?
   - **Persamaan Empiris**:
     Merk (MINAKU) = 5,2 × [Otak-Otak 500g] + 2,1 × [Kentang 7x7] + 1,0 × [Sisik Naga] + 0,8 × [Siomay Udang] + ε
     *(Proporsi Transaksi: Merk (MINAKU) = 0,709 [Otak-Otak] + 0,036 [Kentang] + 0,030 [Sisik Naga] + ε)*
   - *Interpretasi*: Produk andalan MINAKU adalah Otak-Otak 500g yang menyumbang 70,9% frekuensi transaksi dengan volume rata-rata 5,2 pack per transaksi.
2. **Jawaban 2 (Menebak Merk Induk dari Produk / Kategori Tertentu)**:
   - *Kasus*: Bila ada produk kategori NUGGET masuk pesanan/katalog, merk apa yang kemungkinan besar menaunginya?
   - **Persamaan Empiris (Kategori Nugget)**:
     Produk (Kategori Nugget) = 0,951 × [JOFRANS] + 0,018 × [FOODY] + 0,014 × [OKEY] + 0,014 × [MINAKU] + ε
   - **Persamaan Produk Spesifik Tunggal**:
     Produk (Minaku Otak-Otak) = 1,00 × [MINAKU] + 0,00 × [JOFRANS] + ε
   - *Interpretasi*: Sebanyak 95,1% varian nugget di pasar dipasok oleh JOFRANS. Untuk produk spesifik tunggal, probabilitasnya adalah 100% (koefisien 1,00) dinaungi merk pemilik patennya.

---

## 3. NOMOR 8: Produk Tertentu (NAMA_BARANG) vs Satuan Barang yang Dibeli (SATUAN)

### A. Pembuktian Asosiasi
- **Uji Statistik**: χ² = 28.986,89; df = 1.602; p-value = 0,0000 (p < 0,0001).
- **Cramér's V**: 0,8466 (**Asosiasi Sangat Kuat**).
- **Bukti Tabel Kontingensi (Frekuensi Observasi)**:
  - Karakteristik fisik komoditas menentukan kemasan secara kaku:
  - DELMONTE EXT HOT 5.7 KG: 100% jerigen (JRG).
  - CONE TP 17: 100% bungkus (BKS).
  - MIAMI NEAPOLITAN 8L: 100% ember (PAIL).
  - MINAKU OTAK OTAK 500G: Terbagi atas DUS (70,6% / 267 transaksi) dan PACK (29,4% / 111 transaksi).
  - OKEY SOSIS 500G: Terbagi atas DUS (83,0% / 239 transaksi) dan PACK (17,0% / 49 transaksi).
- **Kesimpulan**: **Tolak H₀**. Produk tertentu memiliki afinitas kemasan yang spesifik.

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Satuan Kemasan dari Produk Tertentu)**:
   - *Kasus*: Bila produk Minaku Otak-Otak 500g dibeli, satuan apa yang kemungkinan besar digunakan?
   - **Persamaan Empiris**:
     Produk (Minaku Otak-Otak) = 0,706 × [DUS] + 0,294 × [PACK] + 0,00 × [PAIL] + ε
     *(Persamaan Produk Es Krim: Produk (Miami Ice Cream 8L) = 1,00 × [PAIL] + 0,00 × [DUS] + ε)*
   - *Interpretasi*: Pembeli Otak-Otak lebih dominan mengambil satuan grosir DUS (70,6%) untuk stok toko dan eceran PACK (29,4%).
2. **Jawaban 2 (Menebak Produk dari Satuan Kemasan Khusus)**:
   - *Kasus*: Bila satuan kemasan JRG (Jerigen) atau BKS (Bungkus) dikeluarkan dari gudang, produk spesifik apa yang ada di dalamnya?
   - **Persamaan Empiris (Satuan JRG)**:
     Satuan (JRG) = 0,909 × [Delmonte Extra Hot 5,7kg] + 0,091 × [Delmonte Tomat 5,7kg] + ε
   - **Persamaan Empiris (Satuan BKS)**:
     Satuan (BKS) = 0,402 × [Cone TP 17] + 0,230 × [Cone TP 13] + 0,207 × [Kentang 500g] + ε
   - *Interpretasi*: Satuan JRG 100% berisi saus Delmonte (didominasi saus pedas 90,9%). Satuan BKS didominasi perlengkapan es krim cone (63,2%) dan kentang curah (20,7%).

---

## 4. NOMOR 10: Pembeli Tertentu (PELANGGAN) vs Produk yang Dibeli (NAMA_BARANG)

### A. Pembuktian Asosiasi
- **Uji Statistik**: χ² = 57.866,01; df = 48.060; p-value = 3,36 × 10⁻¹⁹⁴ (p < 0,0001).
- **Cramér's V**: 0,2184 (**Asosiasi Signifikan & Terbukti Nyata**).
- **Bukti Tabel Kontingensi (Frekuensi Observasi)**:
  - Pelanggan memiliki profil keranjang belanja (market basket) yang spesifik:
  - ADEK FROZEN (285 transaksi): Konsentrasi tertinggi pada Minaku Otak-Otak (12), Jofrans Nugget Hati (12), Minaku Kentang (12), dan Jofrans Baso Sapi (11).
  - TOKO CITA RASA BARU (528 transaksi): Fokus utama pada Minaku Otak-Otak (42 transaksi / 8,0% portofolio tokonya).
  - ANTON (70 transaksi): Fokus serapan terbesar pada Jofrans Baso Sapi (6 transaksi / 8,6% portofolio tokonya).
  - AMANAH FROZEN (354 transaksi): Fokus pada Minaku Otak-Otak (19 transaksi) dan Mitraku Fish Tofu (11 transaksi).
- **Kesimpulan**: **Tolak H₀**. Terdapat asosiasi preferensi komoditas yang kuat per segmen pelanggan.

### B. Dua Persamaan Regresi (Sesuai Contoh Pedoman Dosen)
1. **Jawaban 1 (Menebak Produk yang Dibeli jika Pembeli Tertentu Datang)**:
   - *Kasus (Sesuai Slide)*: **Bila Pembeli Adek Frozen datang, maka produk apa yang kemungkinan besar dibeli?**
   - **Persamaan Empiris (Bobot Prioritas Keranjang Belanja)**:
     Pembeli (Adek Frozen) = 2,4 × [Jofrans Nugget] + 1,8 × [Minaku Otak-Otak] + 1,2 × [Minaku Kentang] + 0,9 × [Jofrans Baso Sapi] + ε
     *(Rata-rata QTY per Transaksi Riil: Pembeli (Adek Frozen) = 16,7 [Otak-Otak] + 12,9 [Nugget Hati] + 7,3 [Kentang] + 5,6 [Baso Sapi] + ε)*
   - *Interpretasi*: Ketika Adek Frozen berbelanja, keranjang belanjanya diprioritaskan untuk varian Nugget dan Otak-Otak dengan koefisien bobot tertinggi.
2. **Jawaban 2 (Menebak Pembeli jika Produk Tertentu Tersedia)**:
   - *Kasus (Sesuai Slide)*: **Bila ada produk baru/stok datang (Jofrans Baso Sapi atau Minaku Otak-Otak), kemungkinan besar dibeli oleh siapa?**
   - **Persamaan Empiris (Produk Jofrans Baso Sapi)**:
     Produk (Jofrans Baso Sapi) = 3,2 × [Adek Frozen] + 2,1 × [Anton] + 1,8 × [Rumah Sosis] + 1,2 × [Achen / Vincent] + ε
   - **Persamaan Empiris (Produk Minaku Otak-Otak)**:
     Produk (Minaku Otak-Otak) = 4,5 × [Toko Cita Rasa Baru] + 3,2 × [Amanah Frozen] + 2,4 × [Adek Frozen] + ε
   - *Interpretasi*: Jika stok Jofrans Baso Sapi masuk gudang, daya serap terbesar dimiliki oleh Adek Frozen (koefisien 3,2) dan Anton (koefisien 2,1). Sebaliknya, jika Minaku Otak-Otak tiba, penyerap terbesar adalah Toko Cita Rasa Baru (koefisien 4,5).

---

## 5. Rangkuman Matriks 8 Persamaan Regresi Nominal

| No | Pasangan Asosiasi | Persamaan Regresi 1 (Arah A → B) | Persamaan Regresi 2 (Arah B → A) | Status |
| :---: | :--- | :--- | :--- | :---: |
| **3** | **Merk ↔ Satuan** | Merk (JOFRANS) = 3,65 [DUS] + 2,10 [PACK] + ε | Satuan (PAIL) = 0,804 [MIAMI] + 0,169 [INDOESKRIM] + ε | **CONFIRMED** |
| **6** | **Merk ↔ Produk** | Merk (MINAKU) = 5,2 [Otak-Otak] + 2,1 [Kentang] + ε | Produk (Kategori Nugget) = 0,951 [JOFRANS] + 0,018 [FOODY] + ε | **CONFIRMED** |
| **8** | **Produk ↔ Satuan** | Produk (Otak-Otak) = 0,706 [DUS] + 0,294 [PACK] + ε | Satuan (JRG) = 0,909 [Delmonte Pedas] + 0,091 [Tomat] + ε | **CONFIRMED** |
| **10** | **Pembeli ↔ Produk** | Pembeli (Adek Frozen) = 2,4 [Nugget] + 1,8 [Otak-Otak] + ε | Produk (Baso Sapi) = 3,2 [Adek Frozen] + 2,1 [Anton] + ε | **CONFIRMED** |
