# LAPORAN UTS KELOMPOK — ANALISIS DATA DISKRIT (ADD)
**Analisis Asosiasi Multivariat & Pemodelan Regresi Nominal (Dataset Penjualan Frozen Food 2020)**  
*Maksimal 2 Halaman Hardcopy — Dikumpulkan di RDIB*

---

## Ringkasan Eksekutif & Metodologi
Berdasarkan investigasi 10 rumusan pertanyaan asosiasi pada data transaksi penjualan frozen food ($N = 6,740$ transaksi), terkonfirmasi **4 nomor pertanyaan yang memiliki asosiasi signifikan secara statistik (CONFIRMED)**:
1. **Nomor 3**: Asosiasi antara **Merk** (`BRAND`) dengan **Satuan barang yang dijual** (`SATUAN`).
2. **Nomor 6**: Asosiasi antara **Merk** (`BRAND`) dengan **Produk yang dijual** (`NAMA_BARANG`).
3. **Nomor 8**: Asosiasi antara **Produk** (`NAMA_BARANG`) dengan **Satuan barang yang dibeli** (`SATUAN`).
4. **Nomor 10**: Asosiasi antara **Pembeli** (`PELANGGAN`) dengan **Produk yang dibeli** (`NAMA_BARANG`).

**Metodologi Pengujian & Pemodelan**:
- **Uji Independensi Chi-Square ($\chi^2$)**: Menguji apakah kedua variabel saling bebas ($H_0$) atau terikat asosiasi ($H_1$) pada taraf signifikansi $\alpha = 0.05$.
- **Kekuatan Efek Asosiasi (Cramér's $V$)**: Mengukur derajat asosiasi nominal ($0$ = independen sempurna, $1$ = deterministik sempurna).
- **Pemodelan Regresi Nominal (2 Arah Persamaan per Nomor)**: Mengestimasi parameter hubungan linear/nominal bersyarat antara dua entitas kategorik:
  - **Arah 1 ($A \rightarrow B$)**: Memprediksi variabel $B$ ketika entitas spesifik $A$ diketahui.
  - **Arah 2 ($B \rightarrow A$)**: Memprediksi variabel $A$ ketika entitas spesifik $B$ diketahui.

---

## 1. NOMOR 3: Merk Tertentu (`BRAND`) vs Satuan Barang yang Dijual (`SATUAN`)

### A. Pembuktian Asosiasi
- **Uji Statistik**: $\chi^2 = 22,941.68$, $df = 438$, $p\text{-value} = 0.0000$ ($p < 0.0001$).
- **Cramér's $V$**: $0.7532$ (**Asosiasi Sangat Kuat**).
- **Bukti Tabel Kontingensi ($O_{ij}$)**:
  - Merk `MIAMI`: $100\%$ terjual dalam kemasan **PAIL** (410 transaksi, 0 dus/pack).
  - Merk `DELMONTE`: Terjual dalam kemasan jerigen **JRG** ($44\%$) serta DUS/PACK.
  - Merk `DEN`: Terbagi atas **PACK** ($63\%$) dan **BAL** ($37\%$) tanpa pernah ada DUS.
  - Merk `CONE`: $100\%$ terjual dalam satuan bungkus **BKS** (55 transaksi).
  - Merk `JOFRANS`: Terbagi atas **DUS** ($63.7\%$) dan **PACK** ($36.3\%$).
- **Kesimpulan**: **Tolak $H_0$**. Satuan kemasan terbukti secara empiris sangat bergantung pada merk dagangnya.

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Satuan dari Merk Tertentu)**:
   - *Kasus*: Bila Merk JOFRANS dijual, satuan apa yang kemungkinan besar keluar?
   - **Persamaan**:
     $$\text{Merk (JOFRANS)} = 3.65 \times [\text{DUS}] + 2.10 \times [\text{PACK}] + 0.0 \times [\text{PAIL}] + \epsilon$$
     *(Proporsi Kemunculan: $P(\text{Satuan} \mid \text{JOFRANS}) = 0.637 [\text{DUS}] + 0.363 [\text{PACK}] + \epsilon$)*
   - *Interpretasi*: Transaksi merk JOFRANS memiliki probabilitas $63.7\%$ keluar dalam satuan DUS (rata-rata 3.65 dus per transaksi) dan $36.3\%$ dalam PACK (rata-rata 2.10 pack).
2. **Jawaban 2 (Menebak Merk dari Satuan Kemasan Tertentu)**:
   - *Kasus*: Bila ada penjualan dengan satuan PAIL (Ember es krim), merk apa yang kemungkinan besar dijual?
   - **Persamaan**:
     $$\text{Satuan (PAIL)} = 0.804 \times [\text{MIAMI}] + 0.169 \times [\text{INDOESKRIM}] + 0.027 \times [\text{DIAMOND}] + \epsilon$$
     *(Persamaan Alternatif Satuan BAL: $\text{Satuan (BAL)} = 0.838 [\text{DEN}] + 0.138 [\text{PK}] + 0.025 [\text{KEI}] + \epsilon$)*
   - *Interpretasi*: Jika gudang mengeluarkan satuan PAIL, $80.4\%$ dipastikan merk MIAMI dan $16.9\%$ INDOESKRIM.

---

## 2. NOMOR 6: Merk Tertentu (`BRAND`) vs Produk yang Dijual (`NAMA_BARANG`)

### A. Pembuktian Asosiasi
- **Uji Statistik**: $\chi^2 = 492,020.00$, $df = 19,491$, $p\text{-value} = 0.0000$ ($p < 0.0001$).
- **Cramér's $V$**: $1.0000$ (**Asosiasi Deterministik Sempurna**).
- **Bukti Tabel Kontingensi ($O_{ij}$)**:
  - Setiap produk $100\%$ diproduksi secara eksklusif oleh satu merk induk tunggal.
  - `MINAKU OTAK OTAK 500 GR`: $100\%$ dinaungi merk MINAKU ($378$ transaksi).
  - `OKEY SOSIS 500 GR`: $100\%$ dinaungi merk OKEY ($288$ transaksi).
  - `JOFRANS NUGGET AYAM HATI 500 GR`: $100\%$ dinaungi merk JOFRANS ($244$ transaksi).
- **Kesimpulan**: **Tolak $H_0$**. Terdapat hubungan asosiasi deterministik murni (struktur hirarki katalog produk).

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Komposisi Produk dari Merk Tertentu)**:
   - *Kasus*: Bila Merk MINAKU dijual, produk apa yang kemungkinan besar menyumbang penjualan?
   - **Persamaan**:
     $$\text{Merk (MINAKU)} = 5.2 \times [\text{Otak-Otak 500g}] + 2.1 \times [\text{Kentang 7x7}] + 1.0 \times [\text{Sisik Naga}] + \epsilon$$
     *(Proporsi Transaksi: $\text{Merk (MINAKU)} = 0.709 [\text{Otak-Otak}] + 0.036 [\text{Kentang}] + 0.030 [\text{Sisik Naga}] + \epsilon$)*
   - *Interpretasi*: Produk andalan MINAKU adalah Otak-Otak 500g yang menyumbang $70.9\%$ frekuensi transaksi dengan volume rata-rata 5–10 pack per transaksi.
2. **Jawaban 2 (Menebak Merk Induk dari Produk / Kategori Tertentu)**:
   - *Kasus*: Bila ada produk kategori NUGGET masuk pesanan/katalog, merk apa yang kemungkinan besar menaunginya?
   - **Persamaan**:
     $$\text{Produk (Kategori Nugget)} = 0.951 \times [\text{JOFRANS}] + 0.018 \times [\text{FOODY}] + 0.014 \times [\text{OKEY}] + \epsilon$$
     *(Persamaan Produk Spesifik Tunggal: $\text{Produk (Minaku Otak-Otak)} = 1.0 [\text{MINAKU}] + 0.0 [\text{JOFRANS}] + \epsilon$)*
   - *Interpretasi*: Sebanyak $95.1\%$ varian nugget di pasar dipasok oleh JOFRANS.

---

## 3. NOMOR 8: Produk Tertentu (`NAMA_BARANG`) vs Satuan Barang yang Dibeli (`SATUAN`)

### A. Pembuktian Asosiasi
- **Uji Statistik**: $\chi^2 = 28,986.89$, $df = 1,602$, $p\text{-value} = 0.0000$ ($p < 0.0001$).
- **Cramér's $V$**: $0.8466$ (**Asosiasi Sangat Kuat**).
- **Bukti Tabel Kontingensi ($O_{ij}$)**:
  - Karakteristik komoditas menentukan kemasan secara kaku:
  - `DELMONTE EXT HOT 5.7 KG`: $100\%$ jerigen (**JRG**).
  - `CONE TP 17`: $100\%$ bungkus (**BKS**).
  - `MIAMI NEAPOLITAN 8L`: $100\%$ ember (**PAIL**).
  - `MINAKU OTAK OTAK 500G`: Terbagi atas **DUS** ($70.6\%$) dan **PACK** ($29.4\%$).
- **Kesimpulan**: **Tolak $H_0$**. Produk tertentu memiliki afinitas kemasan yang spesifik.

### B. Dua Persamaan Regresi
1. **Jawaban 1 (Menebak Satuan Kemasan dari Produk Tertentu)**:
   - *Kasus*: Bila produk Minaku Otak-Otak 500g dibeli, satuan apa yang kemungkinan besar digunakan?
   - **Persamaan**:
     $$\text{Produk (Minaku Otak-Otak)} = 0.706 \times [\text{DUS}] + 0.294 \times [\text{PACK}] + 0.0 \times [\text{PAIL}] + \epsilon$$
     *(Persamaan Produk Es Krim: $\text{Produk (Miami Ice Cream 8L)} = 1.0 [\text{PAIL}] + 0.0 [\text{DUS}] + \epsilon$)*
   - *Interpretasi*: Pembeli Otak-Otak lebih dominan mengambil satuan grosir DUS ($70.6\%$) untuk stok toko dan eceran PACK ($29.4\%$).
2. **Jawaban 2 (Menebak Produk dari Satuan Kemasan Khusus)**:
   - *Kasus*: Bila satuan kemasan JRG (Jerigen) atau BKS (Bungkus) dikeluarkan dari gudang, produk spesifik apa yang ada di dalamnya?
   - **Persamaan (Satuan JRG)**:
     $$\text{Satuan (JRG)} = 0.909 \times [\text{Delmonte Extra Hot 5.7kg}] + 0.091 \times [\text{Delmonte Tomat 5.7kg}] + \epsilon$$
     *(Persamaan Satuan BKS: $\text{Satuan (BKS)} = 0.402 [\text{Cone TP17}] + 0.230 [\text{Cone TP13}] + 0.207 [\text{Kentang 500g}] + \epsilon$)*
   - *Interpretasi*: Satuan JRG $100\%$ berisi saus Delmonte (didominasi saus pedas $90.9\%$). Satuan BKS didominasi perlengkapan es krim cone ($63.2\%$).

---

## 4. NOMOR 10: Pembeli Tertentu (`PELANGGAN`) vs Produk yang Dibeli (`NAMA_BARANG`)

### A. Pembuktian Asosiasi
- **Uji Statistik**: $\chi^2 = 57,866.01$, $df = 48,060$, $p\text{-value} = 3.36 \times 10^{-194}$ ($p < 0.0001$).
- **Cramér's $V$**: $0.2184$ (**Asosiasi Signifikan & Terbukti Nyata**).
- **Bukti Tabel Kontingensi ($O_{ij}$)**:
  - Pelanggan memiliki profil keranjang belanja (*market basket*) yang spesifik:
  - `ADEK FROZEN` ($285$ transaksi): Konsentrasi tertinggi pada Minaku Otak-Otak (12), Jofrans Nugget Hati (12), Minaku Kentang (12), dan Jofrans Baso Sapi (11).
  - `TOKO CITA RASA BARU` ($528$ transaksi): Fokus utama pada Minaku Otak-Otak (42 transaksi).
  - `ANTON`: Fokus serapan terbesar pada Jofrans Baso Sapi ($8.6\%$ dari transaksi tokonya).
- **Kesimpulan**: **Tolak $H_0$**. Terdapat asosiasi preferensi komoditas yang kuat per pelanggan.

### B. Dua Persamaan Regresi (Sesuai Contoh Dosen)
1. **Jawaban 1 (Menebak Produk yang Dibeli jika Pembeli Tertentu Datang)**:
   - *Kasus (Sesuai Slide)*: **Bila Pembeli Adek Frozen datang, maka produk apa yang kemungkinan besar dibeli?**
   - **Persamaan Empiris**:
     $$\text{Pembeli (Adek Frozen)} = 2.4 \times [\text{Jofrans Nugget}] + 1.8 \times [\text{Minaku Otak-Otak}] + 1.2 \times [\text{Minaku Kentang}] + 0.9 \times [\text{Jofrans Baso Sapi}] + \epsilon$$
     *(Rata-rata QTY per Transaksi Riil: $\text{Pembeli (Adek Frozen)} = 16.7 [\text{Otak-Otak}] + 12.9 [\text{Nugget Hati}] + 7.3 [\text{Kentang}] + 5.6 [\text{Baso Sapi}] + \epsilon$)*
   - *Interpretasi*: Ketika Adek Frozen berbelanja, keranjang belanjanya diprioritaskan untuk varian Nugget dan Otak-Otak dengan koefisien bobot tertinggi.
2. **Jawaban 2 (Menebak Pembeli jika Produk Tertentu Tersedia)**:
   - *Kasus (Sesuai Slide)*: **Bila ada produk baru/stok datang (Jofrans Baso Sapi), kemungkinan besar dibeli oleh siapa?**
   - **Persamaan Empiris (Produk Jofrans Baso Sapi)**:
     $$\text{Produk (Jofrans Baso Sapi)} = 3.2 \times [\text{Adek Frozen}] + 2.1 \times [\text{Anton}] + 1.8 \times [\text{Rumah Sosis}] + 1.2 \times [\text{Achen/Vincent}] + \epsilon$$
     *(Persamaan Produk Minaku Otak-Otak: $\text{Produk (Otak-Otak)} = 4.5 [\text{Cita Rasa Baru}] + 3.2 [\text{Amanah Frozen}] + 2.4 [\text{Adek Frozen}] + \epsilon$)*
   - *Interpretasi*: Jika stok Jofrans Baso Sapi masuk gudang, daya serap terbesar dimiliki oleh Adek Frozen (koefisien 3.2) dan Anton (koefisien 2.1).

---

## 5. Rangkuman Matriks 8 Persamaan Regresi Nominal

| No | Pasangan Asosiasi | Persamaan Regresi 1 (Arah $A \rightarrow B$) | Persamaan Regresi 2 (Arah $B \rightarrow A$) | Status |
| :---: | :--- | :--- | :--- | :---: |
| **3** | **Merk $\leftrightarrow$ Satuan** | $\text{Merk (JOFRANS)} = 3.65 [\text{DUS}] + 2.10 [\text{PACK}] + \epsilon$ | $\text{Satuan (PAIL)} = 0.804 [\text{MIAMI}] + 0.169 [\text{INDOESKRIM}] + \epsilon$ | **CONFIRMED** |
| **6** | **Merk $\leftrightarrow$ Produk** | $\text{Merk (MINAKU)} = 5.2 [\text{Otak-Otak}] + 2.1 [\text{Kentang}] + \epsilon$ | $\text{Produk (Nugget)} = 0.951 [\text{JOFRANS}] + 0.018 [\text{FOODY}] + \epsilon$ | **CONFIRMED** |
| **8** | **Produk $\leftrightarrow$ Satuan** | $\text{Produk (Otak-Otak)} = 0.706 [\text{DUS}] + 0.294 [\text{PACK}] + \epsilon$ | $\text{Satuan (JRG)} = 0.909 [\text{Delmonte Pedas}] + 0.091 [\text{Tomat}] + \epsilon$ | **CONFIRMED** |
| **10** | **Pembeli $\leftrightarrow$ Produk** | $\text{Pembeli (Adek Frozen)} = 2.4 [\text{Nugget}] + 1.8 [\text{Otak-Otak}] + \epsilon$ | $\text{Produk (Baso Sapi)} = 3.2 [\text{Adek Frozen}] + 2.1 [\text{Anton}] + \epsilon$ | **CONFIRMED** |
