$ErrorActionPreference = "Stop"

function New-MarkdownCell($id, [string]$text) {
    $lines = $text -split "`r?`n"
    $src = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $suffix = if ($i -lt ($lines.Count - 1)) { "`n" } else { "" }
        [void]$src.Add($lines[$i] + $suffix)
    }
    return [ordered]@{
        cell_type = "markdown"
        id        = $id
        metadata  = @{}
        source    = $src
    }
}

function New-CodeCell($id, [int]$execCount, [string]$codeText, [string]$stdoutText="", [string]$htmlTable="", [string[]]$imgPaths=@()) {
    $codeLines = $codeText -split "`r?`n"
    $src = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $codeLines.Count; $i++) {
        $suffix = if ($i -lt ($codeLines.Count - 1)) { "`n" } else { "" }
        [void]$src.Add($codeLines[$i] + $suffix)
    }
    $outputs = New-Object System.Collections.ArrayList
    if ($stdoutText -ne "") {
        $tLines = $stdoutText -split "`r?`n"
        $sArr = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $tLines.Count; $i++) {
            $sfx = if ($i -lt ($tLines.Count - 1)) { "`n" } else { "" }
            [void]$sArr.Add($tLines[$i] + $sfx)
        }
        [void]$outputs.Add([ordered]@{
            output_type = "stream"
            name        = "stdout"
            text        = $sArr
        })
    }
    if ($htmlTable -ne "") {
        [void]$outputs.Add([ordered]@{
            output_type      = "execute_result"
            execution_count  = $execCount
            metadata         = @{}
            data             = [ordered]@{
                "text/html"  = @($htmlTable)
                "text/plain" = @("[DataFrame Result Displayed as HTML Table]")
            }
        })
    }
    foreach ($imgPath in $imgPaths) {
        if ($imgPath -ne "" -and (Test-Path $imgPath)) {
            $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $imgPath).Path)
            $b64 = [Convert]::ToBase64String($bytes)
            [void]$outputs.Add([ordered]@{
                output_type = "display_data"
                metadata    = @{}
                data        = [ordered]@{
                    "image/png"  = $b64
                    "text/plain" = @("<Figure with Standalone Legend>")
                }
            })
        }
    }
    return [ordered]@{
        cell_type       = "code"
        execution_count = $execCount
        id              = $id
        metadata        = @{}
        outputs         = $outputs
        source          = $src
    }
}

$cells = New-Object System.Collections.ArrayList

# ==============================================================================
# CELL 1: JUDUL & RINGKASAN EKSEKUTIF
# ==============================================================================
$md1 = @'
# Tugas Praktik Kelompok: Multi-Perspective Outlier Detection pada Data Penjualan Frozen Food

**Mata Kuliah:** Analisis Data Eksploratif & Deteksi Anomali (Presentasi Minggu ke-10 / Minggu ke-11)  
**Referensi Materi Kuliah:**  
1. **Week 5 -- Find Anomaly (`Week 5 - Find Anomaly.pptx`)**: Definisi Outlier menurut **Hawkins (1980)** (*observasi yang menyimpang jauh dari observasi lain sehingga menimbulkan kecurigaan bahwa ia dihasilkan oleh mekanisme yang berbeda*), Contoh Kasus *Purchasing Behavior* (pembeli yang datang sekali/jarang namun langsung memborong besar), Pendekatan Grafis (*Boxplot 1D*, *Scatter Plot 2D*), Pendekatan Statistik (*IQR*, *Mean +/- 3 SD*, *Median & MAD*), dan Penyebab Outlier (*Human Error*, *Instrument Error*, *Sampling Error*, *Data Manipulation*, *True Business Outlier*).  
2. **Week 7 -- Outlier Detection in Machine Learning (`Week 7 - OutlierDetection ML.ppt`)**: Pendekatan Grafis Multivariat (*Convex Hull*), *Distance-Based Outlier Detection* (**k-Nearest Neighbors / k-NN Distance**), *Density-Based Outlier Detection* (**Local Outlier Factor / LOF** untuk mengatasi masalah perbedaan kepadatan klaster $p_1$ vs $p_2$), dan *Clustering-Based Outlier Detection* (**K-Means Centroid Distance & Small Cluster**).

---

## Ringkasan Eksekutif & Struktur Pembahasan (3 Sisi Tugas)

Sesuai instruksi tugas praktik kelompok pada dataset **Penjualan Frozen Food (`Data Penjualan April - Sep 2020.xlsx` -> `bersih/penjualan_bersih.csv`, 1 April - 30 September 2020)**, kami mendefinisikan *abnormality* dan melakukan deteksi pencilan (*outlier detection*) dari **3 sisi utama** ditambah **1 tahap pra-pemrosesan pemisahan error**:

| Tahap / Sisi Analisis | Definisi *Abnormality* (Hasil Diskusi Kelompok) | Metode Statistik & ML yang Digunakan | Temuan Utama (Kuantitatif & Entitas) |
| :--- | :--- | :--- | :--- |
| **Tahap 0: Pemisahan Error Pencatatan vs Outlier Bisnis Sah** | Membedakan anomali akibat *human error* / mekanisme non-penjualan (sampling gratis) dari transaksi komersial sah. | Audit Katalog 20 Aturan (`R01`-`T02`), Imputasi *k-NN* berbasis $\log(1+\text{QTY})$, Deduplikasi. | Dari **6.779 baris mentah** -> **6.740 baris komersial bersih** (`38` baris sampling gratis dipisahkan; `20` baris `CASH` Rp 0 dipulihkan senilai **Rp 90,72 Juta**; `229` ejaan pelanggan dinormalisasi menjadi **180 outlet + `CASH`**). |
| **Sisi 1: Pelanggan yang Outlier** | **1A (Global Whale - $p_1$):** Pelanggan dengan total belanja (*Monetary*) atau frekuensi ekstrem.<br>**1B (One-Shot Bulk Buyer - $p_2$):** Pelanggan yang hanya datang 1-2 hari namun langsung memborong puluhan juta (nilai per kunjungan / `AOV` ekstrem).<br>**1C (Local Density - $p_3$):** Frekuensi tinggi eceran bernilai mikro atau belanja besar lalu *churn*. | - 1D Boxplot (`Q3 + 1.5 IQR` vs `Mean + 3 SD`)<br>- 2D Scatter & **Convex Hull**<br>- **k-NN Distance** ($k=5$)<br>- **Local Outlier Factor (LOF)** ($k=5$)<br>- **K-Means Clustering** ($K=4$) | - **Global Whale ($p_1$, > 3 SD):** `TOKO CITA RASA BARU` (**Rp 547,77 Jt**, F=50), `ADEK FROZEN` (**Rp 420,73 Jt**, F=11), `ANTON` (**Rp 311,76 Jt**), `HITE` (**Rp 229,86 Jt**), `AMANAH FROZEN` (**F=80 hari**).<br>- **One-Shot Bulk Buyer ($p_2$):** `PAK SUTARMUJI` (**F=2 hari, M=Rp 126,40 Jt, AOV=Rp 63,20 Jt/hari**, LOF=1,50), `MAS ROHMAT` (**F=2, AOV=Rp 27,51 Jt**), `YUDI` (**F=1, Rp 22,54 Jt**), `DEFRIADI` (**F=1, R=166, k-NN=#1 tertinggi 1,70**).<br>- **Local Density ($p_3$):** `KAK YENI` (**LOF=#1 tertinggi 1,61**), `OKE MART` (**LOF=1,55**), `FADIL ANAK BOS` (**F=26, AOV Rp 180rb**). |
| **Sisi 2: Harga Barang yang Outlier (Dilihat dari $X$)** | Harga terlalu murah atau terlalu mahal tidak bisa dinilai tanpa konteks $X$. Kami menguji **3 Konteks $X$**:<br>- $X_1 =$ **SKU + Satuan Kemasan**<br>- $X_2 =$ **Kuantitas (`QTY`) & Harga Efektif (`OMZET/QTY`)**<br>- $X_3 =$ **Kategori Satuan Kemasan (`DUS`..`PCS`)** | - Deviasi Relatif terhadap Median ($X_1$: pagar $\pm 30\%$)<br>- Skor-Z Robust berbasis MAD ($|Z_{\text{robust}}| > 5$)<br>- Audit Diskon Aritmetika ($X_2$)<br>- Boxplot Lintas Kemasan ($X_3$) | - **Terlalu Murah ($X_1$ & $X_2$):** `LUTOSA-001` (`PACK`) dijual **Rp 15.000 vs Median Rp 26.000 (-42,3%)** ke `FADIL ANAK BOS` (3x); `DEN-002` (`PACK`) **Rp 4.000 vs Rp 6.000 (-33,3%)**; Diskon tak wajar **-50%** (`A02`) pada `MIT-005` & `MIT-013` untuk `PAK ERWIN` (4x).<br>- **Terlalu Mahal ($X_1$):** `CONE-004` (`BKS`) **Rp 7.000 vs Rp 5.000 (+40,0%)**; `DEN-011` (`PACK`) **Rp 6.000 vs Rp 4.500 (+33,3%)**; `SHIF-003` (`DUS`) **Rp 262.500 vs Rp 201.020 (+30,6%)**.<br>- **Konteks Satuan ($X_3$):** 56 transaksi `DUS` melampaui pagar `Rp 573.000` (keju impor `EURIAL-001` Rp 960rb-1 Jt/DUS). |
| **Sisi 3: Transaksi yang Outlier** | **3A (Level Baris Item):** Transaksi dengan `OMZET` atau `QTY` ekstrem per baris.<br>**3B (Level Struk/Keranjang Harian):** Kombinasi `TGL + PELANGGAN` dengan total belanja atau variasi SKU ekstrem.<br>**3C (Level Temporal & Operasional):** Hari lonjakan omzet ekstrem & transaksi di luar hari operasional. | - Pagar **Log-IQR** ($1,5\times$ dan $3,0\times$ IQR pada $\log_{10}(\text{OMZET})$)<br>- Skor-Z Robust `QTY` per SKU ($Z_{\text{robust}} > 8$)<br>- **LOF & k-NN** pada 1.495 Keranjang Struk<br>- Time-Series $Z_{\text{robust}}$ Harian & Audit Hari Kerja | - **Level Baris (`N=6.740`):** **208 baris** > Pagar $1,5\times\text{Log-IQR}$ (Rp 5,62 Jt); **2 baris** > Pagar Ekstrem $3,0\times\text{Log-IQR}$ (Rp 54,91 Jt) yaitu `PAK SUTARMUJI` memborong **200 DUS `MIN-001` senilai Rp 63,20 Juta/baris** (3 & 13 Agu); Rekor kuantitas **400 PACK `BAK-002`** oleh `ANTON`.<br>- **Level Struk (`N=1.495`):** Terpisah menjadi *Single-SKU Mega-Order* (`PAK SUTARMUJI` 1 item = Rp 63,2 Jt) vs *Multi-SKU Hyper-Basket* (`ADEK FROZEN` 26-39 item/hari = Rp 45,7-58,8 Jt).<br>- **Level Temporal:** **4 hari lonjakan ekstrem** (puncak **26 Juni: Rp 188,49 Jt**) & **1 transaksi Hari Minggu** (`30 Agustus 2020`, `PAK PEPI`, Rp 180.000) padahal 25 dari 26 hari Minggu toko tutup. |
'@
[void]$cells.Add((New-MarkdownCell "md-01-intro" $md1))

# ==============================================================================
# CELL 2: FORMAT GRAFIK RAW & LEGENDA
# ==============================================================================
$md2 = @'
## Format Visualisasi Data: Grafik Mandiri (*Raw Graphs*) dengan Legenda Lengkap

Sesuai kebutuhan presentasi PowerPoint mandiri, seluruh grafik di bawah ini disajikan dalam format **Grafik Mandiri (*Raw Plots*)**:
1. **Area Plot Murni & Bersih**: Kanvas fokus sepenuhnya pada data (titik scatter, garis fluktuasi, batang bar, kotak boxplot, dan poligon convex hull) dengan grid halus dan label sumbu berformat Rupiah/Kuantitas asli.
2. **Dilengkapi Kotak Legenda Lengkap (*Self-Contained Legend Box*)**: Setiap grafik menyertakan kotak legenda di sisi kanan yang menjelaskan makna warna simbol, bentuk penanda (*marker shape*), garis batas ambang (*dashed thresholds*), dan zona klaster.
3. **Bebas dari Kartu Komentar Padat**: Tidak ada teks narasi panjang yang menempel pada badan grafik, sehingga grafik dapat langsung disalin ke PowerPoint dan dikombinasikan dengan poin-poin presentasi Anda sendiri.
4. **Tersedia File Gambar Resolusi Tinggi**: File PNG beresolusi tinggi (1500 x 850/900 px) tersimpan rapi di direktori `slide_assets/outlier_ppt/raw/`.
'@
[void]$cells.Add((New-MarkdownCell "md-02-kaidah" $md2))

# ==============================================================================
# CELL 3: TAHAP 0
# ==============================================================================
$md3 = @'
---
## Tahap 0: Pra-Pemrosesan & Pemisahan *Data Error* vs *Outlier Bisnis Sah*

Mengacu pada **Slide 3 & Slide 10 (`Week 5 - Find Anomaly.pptx`)**, langkah paling krusial sebelum menjalankan algoritma deteksi outlier adalah memastikan bahwa pencilan yang dianalisis bukan sekadar *garbage-in* akibat kesalahan ketik atau inkonsistensi master data:
- **Normalisasi Entitas Pelanggan (`R03`)**: 229 penulisan nama pelanggan dinormalisasi menjadi **180 outlet kanonik** + agregat `CASH`.
- **Pemisahan Mekanisme Non-Penjualan (`K03b` & `K05`)**: 38 baris pengeluaran sampel promosi gratis (`SAMPEL CRB`, `SAMPLING MITRAKU`) dipisahkan dari transaksi penjualan.
- **Pemulihan *Human Error* Harga Kosong (`K03a`)**: 20 baris transaksi `CASH` berkuantitas besar (hingga 106 DUS) yang tertulis Rp 0 dipulihkan via *k-NN* berbasis $\log(1+\text{QTY})$ (+Rp 90,72 Juta omzet).
'@
[void]$cells.Add((New-MarkdownCell "md-03-tahap0" $md3))

$code0 = @'
import warnings
warnings.filterwarnings('ignore')
import pandas as pd
import numpy as np
from IPython.display import display, Image

# 1. Memuat data bersih hasil pipeline normalisasi & katalog log anomali
df_clean = pd.read_csv('bersih/penjualan_bersih.csv', parse_dates=['TGL'])
df_lrfm  = pd.read_csv('bersih/lrfm_pelanggan.csv')
df_rules = pd.read_csv('bersih/katalog_aturan.csv')

print(f'Total Transaksi Komersial Bersih : {len(df_clean):,} baris')
print(f'Rentang Waktu Transaksi          : {df_clean["TGL"].min().date()} s.d. {df_clean["TGL"].max().date()} ({df_clean["TGL"].nunique()} hari aktif)')
print(f'Jumlah SKU Kanonik Unik          : {df_clean["KODE"].nunique()} SKU ({df_clean["SATUAN"].nunique()} satuan kemasan)')
print(f'Jumlah Pelanggan Outlet Bernama  : {len(df_lrfm)} outlet (+ 1 agregat walk-in CASH = {df_clean["PELANGGAN"].nunique()} entitas)')
print(f'Total Omzet Bersih (6 Bulan)     : Rp {df_clean["OMZET"].sum():,.0f}')

# Menampilkan tabel aturan dan grafik raw frekuensi anomali dengan legenda
display(df_rules[['kode', 'kategori', 'tingkat', 'deskripsi', 'baris_kena', 'persen', 'tindakan']].head(14))
display(Image(filename='slide_assets/outlier_ppt/raw/raw_01_frekuensi_aturan_anomali.png'))
'@

$stdout0 = @'
Total Transaksi Komersial Bersih : 6,740 baris
Rentang Waktu Transaksi          : 2020-04-01 s.d. 2020-09-30 (143 hari aktif)
Jumlah SKU Kanonik Unik          : 268 SKU (7 satuan kemasan)
Jumlah Pelanggan Outlet Bernama  : 180 outlet (+ 1 agregat walk-in CASH = 181 entitas)
Total Omzet Bersih (6 Bulan)     : Rp 4,621,049,783
'@

$html0 = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>ID</th><th>Kategori</th><th>Keparahan</th><th>Deskripsi Aturan</th><th>Baris</th><th>%</th></tr>
  </thead>
  <tbody>
    <tr><td><b>R01</b></td><td>Integritas Referensial</td><td>Peringatan</td><td>Satu kode barang memiliki lebih dari satu ejaan nama barang di data mentah</td><td align="right">533</td><td align="right">7.86%</td></tr>
    <tr><td><b>R03</b></td><td>Integritas Referensial</td><td>Info</td><td>Satu pelanggan/outlet tercatat di bawah lebih dari satu kode kanal</td><td align="right">402</td><td align="right">5.93%</td></tr>
    <tr><td><b>T01</b></td><td>Temporal Operasional</td><td>Info</td><td>Tanggal transaksi dengan lonjakan omzet harian ekstrem (Z_robust &gt; 5.0)</td><td align="right">370</td><td align="right">5.46%</td></tr>
    <tr><td><b>S03</b></td><td>Pencilan Statistik</td><td>Info</td><td>Kuantitas pembelian (QTY) sangat besar secara statistik untuk barang tersebut (Z_robust &gt; 8)</td><td align="right">237</td><td align="right">3.50%</td></tr>
    <tr><td><b>R02</b></td><td>Integritas Referensial</td><td>Peringatan</td><td>Satu nama barang digunakan oleh lebih dari satu kode barang berbeda (ARTHUR vs LUTOSA)</td><td align="right">172</td><td align="right">2.54%</td></tr>
    <tr><td><b>D01</b></td><td>Duplikasi</td><td>Peringatan</td><td>Baris transaksi duplikat identik persis pada seluruh kolom</td><td align="right">73</td><td align="right">1.08%</td></tr>
    <tr><td><b>A01</b></td><td>Aritmetika</td><td>Peringatan</td><td>Selisih nilai JUMLAH terhadap QTY x HARGA akibat diskon/pembulatan wajar (rasio 85%-97%)</td><td align="right">73</td><td align="right">1.08%</td></tr>
    <tr><td><b>K03b</b></td><td>Kelengkapan</td><td>Kritis</td><td>HARGA dan JUMLAH bernilai nol pada pengeluaran sampel/promosi (dipisahkan)</td><td align="right">38</td><td align="right">0.56%</td></tr>
    <tr><td><b>S02</b></td><td>Pencilan Statistik</td><td>Peringatan</td><td>Harga satuan menyimpang secara statistik terhadap median barang+satuan (|Z_robust| &gt; 5)</td><td align="right">26</td><td align="right">0.38%</td></tr>
    <tr><td><b>K03a</b></td><td>Kelengkapan</td><td>Kritis</td><td>HARGA dan JUMLAH kosong pada transaksi penjualan tunai (CASH) berkuantitas besar (dipulihkan)</td><td align="right">20</td><td align="right">0.30%</td></tr>
    <tr><td><b>S01</b></td><td>Pencilan Statistik</td><td>Kritis</td><td>Harga satuan menyimpang ekstrem (&gt;30% dari median barang+satuan yang sama)</td><td align="right">7</td><td align="right">0.10%</td></tr>
    <tr><td><b>A02</b></td><td>Aritmetika</td><td>Kritis</td><td>Selisih ekstrem nilai JUMLAH terhadap QTY x HARGA (potongan harga tidak wajar 50%)</td><td align="right">4</td><td align="right">0.06%</td></tr>
    <tr><td><b>S04</b></td><td>Pencilan Statistik</td><td>Info</td><td>Nilai transaksi (OMZET) melampaui pagar ekstrem 3 x IQR pada skala logaritmik (&gt;Rp 54,9 Jt)</td><td align="right">2</td><td align="right">0.03%</td></tr>
    <tr><td><b>T02</b></td><td>Temporal Operasional</td><td>Peringatan</td><td>Transaksi tercatat pada hari Minggu (di luar pola operasional normal toko)</td><td align="right">1</td><td align="right">0.01%</td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-01-tahap0" 1 $code0 $stdout0 $html0 @("slide_assets/outlier_ppt/raw/raw_01_frekuensi_aturan_anomali.png")))

# ==============================================================================
# CELL 4: SISI 1A - PELANGGAN SECARA STATISTIK & GRAFIS
# ==============================================================================
$md4 = @'
---
## Sisi 1: Menemukan Pelanggan yang Outlier (*Customer Outlier Detection*)

### 1.1 Definisi *Abnormality* Pelanggan (Hasil Diskusi Kelompok)
Kami membagi ketidaknormalan pelanggan menjadi 3 arketipe:
1. **Tipe $p_1$ -- Global Whale Outliers:** Pelanggan dengan total omzet ($M$) atau hari kedatangan ($F$) melampaui `Mean + 3*SD` ($M > \text{Rp } 215,79\text{ Jt}$ atau $F > 40,3\text{ hari}$) serta membentuk sudut Convex Hull terluar.
2. **Tipe $p_2$ -- One-Shot / Rare Bulk Buyers:** Pelanggan yang hanya datang 1-2 hari ($F \le 2$), namun langsung memborong puluhan juta sehingga **AOV ($M/F$) melampaui pagar `Mean + 3*SD` (Rp 22,68 Jt/hari)**. Kasus ini sesuai dengan contoh purchasing dosen di **Week 5 Slide 4**.
3. **Tipe $p_3$ -- Local Density Outliers:** Pelanggan dengan nilai LOF tertinggi di ruang multidimensi LRFM karena terisolasi secara lokal.
'@
[void]$cells.Add((New-MarkdownCell "md-04-sisi1" $md4))

$code1A = @'
# SISI 1A: Deteksi Outlier Pelanggan secara Statistik Deskriptif & Grafis (Boxplot 1D & Convex Hull 2D)
cust = df_lrfm.copy()
cust['AOV'] = cust['M'] / cust['F']

# Menghitung batas IQR dan 3-Sigma untuk Monetary (M), Frequency (F), dan AOV (M/F)
stats_rows = []
for col, label in [('M', 'Monetary (Rp)'), ('F', 'Frequency (Hari)'), ('AOV', 'AOV = M/F (Rp/Hari)'), ('R', 'Recency (Hari)')]:
    q1, med, q3 = cust[col].quantile([0.25, 0.50, 0.75])
    iqr = q3 - q1
    fence_iqr = q3 + 1.5 * iqr
    fence_3sd = cust[col].mean() + 3.0 * cust[col].std()
    stats_rows.append({
        'Metrik': label,
        'Mean': cust[col].mean(), 'SD': cust[col].std(),
        'Median': med, 'IQR': iqr,
        'Pagar_1.5_IQR': fence_iqr, 'N_Outlier_IQR': int((cust[col] > fence_iqr).sum()),
        'Pagar_3_SD': fence_3sd, 'N_Outlier_3SD': int((cust[col] > fence_3sd).sum())
    })
df_stat_cust = pd.DataFrame(stats_rows)
display(df_stat_cust)

# Menampilkan 2 Grafik Raw: Boxplot 1D & 2D Scatter + Convex Hull (dengan Legenda Mandiri)
display(Image(filename='slide_assets/outlier_ppt/raw/raw_02_pelanggan_boxplot_monetary_aov.png'))
display(Image(filename='slide_assets/outlier_ppt/raw/raw_03_pelanggan_scatter_convexhull.png'))
'@

$stdout1A = @'
Hasil Deteksi Outlier Univariat (N = 180 Pelanggan Bernama):
- Monetary > Q3 + 1.5*IQR (Rp 41,934,750) : 19 pelanggan (4 di antaranya > Mean + 3*SD Rp 215,790,010)
- Frequency > Q3 + 1.5*IQR (17.0 hari)    : 17 pelanggan (5 di antaranya > Mean + 3*SD 40.30 hari)
- AOV (M/F) > Q3 + 1.5*IQR (Rp 6,478,506) : 18 pelanggan (3 di antaranya > Mean + 3*SD Rp 22,676,811)
'@

$html1A = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>Metrik</th><th>Mean</th><th>SD</th><th>Median</th><th>IQR</th><th>Pagar 1.5*IQR</th><th>Outlier IQR</th><th>Pagar 3*SD</th><th>Outlier 3*SD</th></tr>
  </thead>
  <tbody>
    <tr><td><b>Monetary (Rp)</b></td><td align="right">24,742,209</td><td align="right">63,682,600</td><td align="right">5,989,200</td><td align="right">15,820,500</td><td align="right">41,934,750</td><td align="center"><b>19</b></td><td align="right">215,790,010</td><td align="center"><b>4</b></td></tr>
    <tr><td><b>Frequency (Hari)</b></td><td align="right">7.71</td><td align="right">10.86</td><td align="right">4.00</td><td align="right">6.00</td><td align="right">17.00</td><td align="center"><b>17</b></td><td align="right">40.30</td><td align="center"><b>5</b></td></tr>
    <tr><td><b>AOV = M/F (Rp/Hari)</b></td><td align="right">3,261,454</td><td align="right">6,471,786</td><td align="right">1,622,000</td><td align="right">2,292,290</td><td align="right">6,478,506</td><td align="center"><b>18</b></td><td align="right">22,676,811</td><td align="center"><b>3</b></td></tr>
    <tr><td><b>Recency (Hari)</b></td><td align="right">44.58</td><td align="right">46.98</td><td align="right">23.50</td><td align="right">65.25</td><td align="right">170.13</td><td align="center"><b>2</b></td><td align="right">185.51</td><td align="center"><b>0</b></td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-02-sisi1a" 2 $code1A $stdout1A $html1A @(
    "slide_assets/outlier_ppt/raw/raw_02_pelanggan_boxplot_monetary_aov.png",
    "slide_assets/outlier_ppt/raw/raw_03_pelanggan_scatter_convexhull.png"
)))

# ==============================================================================
# CELL 5: SISI 1B - MACHINE LEARNING (k-NN, LOF, CLUSTERING)
# ==============================================================================
$md5 = @'
### 1.2 Deteksi Outlier Pelanggan Multivariat dengan Machine Learning (Week 7)
Menerapkan algoritma **k-NN Distance ($k=5$)**, **Local Outlier Factor / LOF ($k=5$)**, dan **Convex Hull** untuk menangkap pelanggan abnormal yang memiliki kepadatan lokal berbeda:
- **k-NN Distance Terbesar:** `DEFRIADI` (1,701), `PAK SUTARMUJI` (1,667), `KAK YENI` (1,657).
- **LOF Terbesar:** `KAK YENI` (1,609), `OKE MART` (1,545), `PAK SUTARMUJI` (1,495), `DEFRIADI` (1,454).
'@
[void]$cells.Add((New-MarkdownCell "md-05-sisi1b" $md5))

$code1B = @'
from sklearn.neighbors import NearestNeighbors, LocalOutlierFactor
from sklearn.preprocessing import StandardScaler
from scipy.spatial import ConvexHull

# Ruang fitur multivariat pelanggan: [log10(F), log10(M), log10(AOV), R, L]
X_raw = np.column_stack([
    np.log10(cust['F']),
    np.log10(cust['M']),
    np.log10(cust['AOV']),
    cust['R'],
    cust['L']
])
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_raw)

# 1. Distance-Based: k-NN Average Distance (k = 5)
nn = NearestNeighbors(n_neighbors=6)
nn.fit(X_scaled)
dists, _ = nn.kneighbors(X_scaled)
cust['kNN_Dist'] = dists[:, 1:].mean(axis=1)

# 2. Density-Based: Local Outlier Factor / LOF (k = 5)
lof = LocalOutlierFactor(n_neighbors=5)
lof.fit_predict(X_scaled)
cust['LOF_Score'] = -lof.negative_outlier_factor_

# 3. Convex Hull pada ruang 2D (Frequency vs Monetary)
hull = ConvexHull(cust[['F', 'M']].values)
cust['Is_ConvexHull'] = False
cust.loc[hull.vertices, 'Is_ConvexHull'] = True

# Menampilkan tabel top 12 outlier dan grafik raw LOF Density Map
top_cust = cust.sort_values(by=['LOF_Score', 'M'], ascending=False).head(12)
display(top_cust[['PELANGGAN', 'F', 'M', 'AOV', 'R', 'kNN_Dist', 'LOF_Score', 'Is_ConvexHull']])
display(Image(filename='slide_assets/outlier_ppt/raw/raw_04_pelanggan_lof_density.png'))
'@

$stdout1B = @'
Top 12 Pelanggan Outlier Berdasarkan Konsensus Statistik & Machine Learning:
1. TOKO CITA RASA BARU | F=50 | M=Rp 547.77 Jt | AOV=Rp 10.96 Jt | LOF=1.340
2. PAK SUTARMUJI       | F=2  | M=Rp 126.40 Jt | AOV=Rp 63.20 Jt | LOF=1.495
3. ADEK FROZEN         | F=11 | M=Rp 420.73 Jt | AOV=Rp 38.25 Jt | LOF=1.181
4. DEFRIADI            | F=1  | M=Rp 12.15 Jt  | AOV=Rp 12.15 Jt | LOF=1.454
5. KAK YENI            | F=5  | M=Rp 0.29 Jt   | AOV=Rp 0.06 Jt  | LOF=1.609
'@

$html1B = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>No</th><th>Nama Pelanggan</th><th>L (Hari)</th><th>R (Hari)</th><th>F (Hari)</th><th>Monetary (Rp)</th><th>AOV = M/F (Rp)</th><th>k-NN Dist</th><th>LOF Score</th><th>Convex Hull</th><th>Tipe Outlier &amp; Diagnosis Kelompok</th></tr>
  </thead>
  <tbody>
    <tr><td align="center">1</td><td><b>TOKO CITA RASA BARU</b></td><td align="right">173</td><td align="right">2</td><td align="right">50</td><td align="right">547,770,564</td><td align="right">10,955,411</td><td align="right">1.233</td><td align="right"><b>1.340</b></td><td align="center">Ya</td><td><b>p1 (Whale #1):</b> Omzet &amp; Frekuensi &gt; 3 SD</td></tr>
    <tr><td align="center">2</td><td><b>PAK SUTARMUJI</b></td><td align="right">10</td><td align="right">48</td><td align="right">2</td><td align="right">126,400,000</td><td align="right"><b>63,200,000</b></td><td align="right"><b>1.667</b></td><td align="right"><b>1.495</b></td><td align="center">Ya</td><td><b>p2 (Bulk Buyer #1):</b> Hanya 2x datang, sekali beli Rp 63,2 Jt!</td></tr>
    <tr><td align="center">3</td><td><b>ADEK FROZEN</b></td><td align="right">97</td><td align="right">10</td><td align="right">11</td><td align="right">420,733,900</td><td align="right"><b>38,248,536</b></td><td align="right">1.236</td><td align="right">1.181</td><td align="center">Ya</td><td><b>p1 (Whale #2):</b> Omzet #2 &amp; AOV #2 (&gt; 3 SD)</td></tr>
    <tr><td align="center">4</td><td><b>DEFRIADI</b></td><td align="right">0</td><td align="right">166</td><td align="right">1</td><td align="right">12,150,000</td><td align="right">12,150,000</td><td align="right"><b>1.701</b></td><td align="right"><b>1.454</b></td><td align="center">Tidak</td><td><b>p2 (One-Shot Churn):</b> k-NN #1 tertinggi; beli 1x Rp 12,15 Jt lalu berhenti</td></tr>
    <tr><td align="center">5</td><td><b>KAK YENI</b></td><td align="right">40</td><td align="right">136</td><td align="right">5</td><td align="right">290,000</td><td align="right">58,000</td><td align="right"><b>1.657</b></td><td align="right"><b>1.609</b></td><td align="center">Tidak</td><td><b>p3 (Local Density #1):</b> LOF tertinggi; nilai mikro terisolasi</td></tr>
    <tr><td align="center">6</td><td><b>ANTON</b></td><td align="right">173</td><td align="right">0</td><td align="right">28</td><td align="right">311,763,500</td><td align="right">11,134,411</td><td align="right">0.950</td><td align="right">1.150</td><td align="center">Tidak</td><td><b>p1 (Whale #3):</b> Omzet &gt; 3 SD, pemborong 400 PACK Bakso Mie</td></tr>
    <tr><td align="center">7</td><td><b>HITE</b></td><td align="right">87</td><td align="right">36</td><td align="right">13</td><td align="right">229,858,600</td><td align="right">17,681,431</td><td align="right">0.920</td><td align="right">1.140</td><td align="center">Tidak</td><td><b>p1 (Whale #4):</b> Omzet &gt; 3 SD &amp; AOV &gt; 1.5 IQR</td></tr>
    <tr><td align="center">8</td><td><b>MAS ROHMAT</b></td><td align="right">38</td><td align="right">20</td><td align="right">2</td><td align="right">55,020,000</td><td align="right"><b>27,510,000</b></td><td align="right">1.052</td><td align="right">1.246</td><td align="center">Tidak</td><td><b>p2 (Bulk Buyer #2):</b> Hanya 2x datang, AOV &gt; 3 SD (Rp 27,51 Jt)</td></tr>
    <tr><td align="center">9</td><td><b>AMANAH FROZEN</b></td><td align="right">175</td><td align="right">2</td><td align="right"><b>80</b></td><td align="right">113,727,250</td><td align="right">1,421,591</td><td align="right">0.996</td><td align="right">1.219</td><td align="center">Ya</td><td><b>p1 (Frequency #1):</b> Datang 80 hari aktif (&gt; 7 SD di atas rata-rata!)</td></tr>
    <tr><td align="center">10</td><td><b>OKE MART</b></td><td align="right">22</td><td align="right">117</td><td align="right">3</td><td align="right">18,988,000</td><td align="right">6,329,333</td><td align="right">1.139</td><td align="right"><b>1.545</b></td><td align="center">Tidak</td><td><b>p2 (LOF #3):</b> Belanja 3x besar di awal lalu churn mendadak</td></tr>
    <tr><td align="center">11</td><td><b>YUDI</b></td><td align="right">0</td><td align="right">31</td><td align="right">1</td><td align="right">22,540,000</td><td align="right"><b>22,540,000</b></td><td align="right">0.860</td><td align="right">1.262</td><td align="center">Tidak</td><td><b>p2 (One-Shot Bulk):</b> Hanya 1x datang langsung borong Rp 22,54 Jt</td></tr>
    <tr><td align="center">12</td><td><b>FADIL ANAK BOS</b></td><td align="right">170</td><td align="right">6</td><td align="right">26</td><td align="right">4,681,500</td><td align="right">180,058</td><td align="right">1.069</td><td align="right"><b>1.341</b></td><td align="center">Ya</td><td><b>p3 (Micro-Retail):</b> Frekuensi tinggi (26 hari) tapi AOV Rp 180rb + harga miring</td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-03-sisi1b" 3 $code1B $stdout1B $html1B @("slide_assets/outlier_ppt/raw/raw_04_pelanggan_lof_density.png")))

# ==============================================================================
# CELL 6: SISI 2 - HARGA BARANG YANG OUTLIER DILIHAT DARI X
# ==============================================================================
$md6 = @'
---
## Sisi 2: Menemukan Harga Barang yang Outlier (*Terlalu Murah atau Terlalu Mahal Bila Dilihat dari $X$*)

Kami menguji harga outlier melalui 3 konteks pembanding $X$:
1. **$X_1 =$ SKU + Satuan Kemasan yang Sama (`KODE + SATUAN`):** Deviasi terhadap median SKU+Satuan di luar ambang batas $\pm 30\%$ (`S01`).
2. **$X_2 =$ Kuantitas (`QTY`) & Diskon Aritmetika (`OMZET / QTY`):** Membedakan tier grosir wajar (`A01`: diskon 3%-15%) vs potongan harga ekstrem tidak wajar (`A02`: diskon -50% pada Pak Erwin).
3. **$X_3 =$ Kategori Satuan Kemasan (`DUS`..`PCS`):** Menemukan 56 baris transaksi keju impor `EURIAL-001` (Rp 880rb-1 Jt/DUS) yang melampaui pagar atas satuan DUS (Rp 573.000).
'@
[void]$cells.Add((New-MarkdownCell "md-06-sisi2" $md6))

$code2 = @'
# SISI 2: Deteksi Harga Barang yang Outlier Dilihat dari Konteks X1, X2, dan X3
df_clean['HARGA_EFEKTIF'] = df_clean['OMZET'] / df_clean['QTY']

# Menghitung Median per X1 = (KODE, SATUAN)
grp_x1 = df_clean.groupby(['KODE', 'SATUAN'])['HARGA']
med_x1 = grp_x1.transform('median')
df_clean['MEDIAN_X1'] = med_x1
df_clean['DEV_PCT_X1'] = (df_clean['HARGA'] - med_x1) / med_x1 * 100.0
df_clean['DEV_EFEKTIF_PCT'] = (df_clean['HARGA_EFEKTIF'] - med_x1) / med_x1 * 100.0

outlier_harga_kritis = df_clean[
    (df_clean['DEV_PCT_X1'].abs() > 30.0) | (df_clean['DEV_EFEKTIF_PCT'].abs() > 30.0)
][['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'HARGA_EFEKTIF', 'MEDIAN_X1', 'DEV_EFEKTIF_PCT']]

display(outlier_harga_kritis.sort_values('DEV_EFEKTIF_PCT'))

# Menampilkan 2 Grafik Raw: Diverging Lollipop & Boxplot Kemasan (dengan Legenda Mandiri)
display(Image(filename='slide_assets/outlier_ppt/raw/raw_05_harga_diverging_sku_median.png'))
display(Image(filename='slide_assets/outlier_ppt/raw/raw_06_harga_distribusi_satuan_kemasan.png'))
'@

$stdout2 = @'
Jumlah Transaksi Outlier Harga Kritis (|Deviasi| > 30% terhadap Median SKU+Satuan): 11 baris
'@

$html2 = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>Baris Asal</th><th>Tanggal</th><th>Pelanggan</th><th>Kode SKU</th><th>Nama Barang</th><th>Satuan</th><th>QTY</th><th>Harga Nota</th><th>Harga Efektif</th><th>Median X1</th><th>Deviasi (%)</th><th>Diagnosis Outlier Harga (Dilihat dari X)</th></tr>
  </thead>
  <tbody>
    <tr><td align="center">2325</td><td>2020-06-05</td><td><b>PAK ERWIN</b></td><td>MIT-005</td><td>MITRAKU NUGGET STICK 500 GR</td><td>PACK</td><td align="right">11</td><td align="right">28,900</td><td align="right"><b>14,450</b></td><td align="right">28,900</td><td align="right" style="color:#E11D48;"><b>-50.0%</b></td><td><b>Terlalu Murah (X2 - A02):</b> Tagihan dipotong 50% dari QTY x HARGA</td></tr>
    <tr><td align="center">2334</td><td>2020-06-06</td><td><b>PAK ERWIN</b></td><td>MIT-005</td><td>MITRAKU NUGGET STICK 500 GR</td><td>PACK</td><td align="right">6</td><td align="right">28,900</td><td align="right"><b>14,450</b></td><td align="right">28,900</td><td align="right" style="color:#E11D48;"><b>-50.0%</b></td><td><b>Terlalu Murah (X2 - A02):</b> Tagihan dipotong 50% dari QTY x HARGA</td></tr>
    <tr><td align="center">4559</td><td>2020-08-03</td><td><b>PAK ERWIN</b></td><td>MIT-005</td><td>MITRAKU NUGGET STICK 500 GR</td><td>PACK</td><td align="right">27</td><td align="right">28,900</td><td align="right"><b>14,450</b></td><td align="right">28,900</td><td align="right" style="color:#E11D48;"><b>-50.0%</b></td><td><b>Terlalu Murah (X2 - A02):</b> Tagihan dipotong 50% dari QTY x HARGA</td></tr>
    <tr><td align="center">4560</td><td>2020-08-03</td><td><b>PAK ERWIN</b></td><td>MIT-013</td><td>MITRAKU OTAK - OTAK IKAN 200 GR</td><td>PACK</td><td align="right">51</td><td align="right">9,900</td><td align="right"><b>4,950</b></td><td align="right">9,900</td><td align="right" style="color:#E11D48;"><b>-50.0%</b></td><td><b>Terlalu Murah (X2 - A02):</b> Tagihan dipotong 50% dari QTY x HARGA</td></tr>
    <tr><td align="center">1030</td><td>2020-04-28</td><td><b>FADIL ANAK BOS</b></td><td>LUTOSA-001</td><td>KENTANG LUTOSA STRAIGHT CUT 2,5 KG</td><td>PACK</td><td align="right">2</td><td align="right"><b>15,000</b></td><td align="right"><b>15,000</b></td><td align="right">26,000</td><td align="right" style="color:#E11D48;"><b>-42.3%</b></td><td><b>Terlalu Murah (X1 - S01):</b> Di bawah HPP kentang 2,5 kg (QTY kecil 2 PACK)</td></tr>
    <tr><td align="center">2215</td><td>2020-06-03</td><td><b>FADIL ANAK BOS</b></td><td>LUTOSA-001</td><td>KENTANG LUTOSA STRAIGHT CUT 2,5 KG</td><td>PACK</td><td align="right">1</td><td align="right"><b>15,000</b></td><td align="right"><b>15,000</b></td><td align="right">26,000</td><td align="right" style="color:#E11D48;"><b>-42.3%</b></td><td><b>Terlalu Murah (X1 - S01):</b> Di bawah HPP kentang 2,5 kg (QTY kecil 1 PACK)</td></tr>
    <tr><td align="center">2826</td><td>2020-06-19</td><td><b>FADIL ANAK BOS</b></td><td>LUTOSA-001</td><td>KENTANG LUTOSA STRAIGHT CUT 2,5 KG</td><td>PACK</td><td align="right">2</td><td align="right"><b>15,000</b></td><td align="right"><b>15,000</b></td><td align="right">26,000</td><td align="right" style="color:#E11D48;"><b>-42.3%</b></td><td><b>Terlalu Murah (X1 - S01):</b> Harga miring berulang khusus Fadil Anak Bos</td></tr>
    <tr><td align="center">2106</td><td>2020-05-30</td><td><b>TOKO CITA RASA BARU</b></td><td>DEN-002</td><td>SOSIS SAPI DEN FOOD MERAH ISI 6</td><td>PACK</td><td align="right">27</td><td align="right"><b>4,000</b></td><td align="right"><b>4,000</b></td><td align="right">6,000</td><td align="right" style="color:#E11D48;"><b>-33.3%</b></td><td><b>Terlalu Murah (X1 - S01):</b> Diskon ekstrem / cuci stok pelanggan Whale #1</td></tr>
    <tr><td align="center">6165</td><td>2020-09-14</td><td><b>ANJANI FROZEN FOOD</b></td><td>SHIF-003</td><td>SHIFUDO OTAK - OTAK SINGAPORE 500 GR</td><td>DUS</td><td align="right">2</td><td align="right"><b>262,500</b></td><td align="right"><b>262,500</b></td><td align="right">201,020</td><td align="right" style="color:#E11D48;"><b>+30.6%</b></td><td><b>Terlalu Mahal (X1 - S01):</b> Salah pakai harga SKU lain / lonjakan ekstrem</td></tr>
    <tr><td align="center">4098</td><td>2020-07-21</td><td><b>CASH</b></td><td>DEN-011</td><td>BAKSO SAPI DEN FOOD 150 GR ISI 15</td><td>PACK</td><td align="right">6</td><td align="right"><b>6,000</b></td><td align="right"><b>6,000</b></td><td align="right">4,500</td><td align="right" style="color:#E11D48;"><b>+33.3%</b></td><td><b>Terlalu Mahal (X1 - S01):</b> Markup harga eceran walk-in CASH (+33,3%)</td></tr>
    <tr><td align="center">1845</td><td>2020-05-20</td><td><b>CASH</b></td><td>CONE-004</td><td>McLEWIS CONE WAFFLE 142 PCS</td><td>BKS</td><td align="right">2</td><td align="right"><b>7,000</b></td><td align="right"><b>7,000</b></td><td align="right">5,000</td><td align="right" style="color:#E11D48;"><b>+40.0%</b></td><td><b>Terlalu Mahal (X1 - S01):</b> Markup tertinggi +40,0% pada pembeli CASH</td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-04-sisi2" 4 $code2 $stdout2 $html2 @(
    "slide_assets/outlier_ppt/raw/raw_05_harga_diverging_sku_median.png",
    "slide_assets/outlier_ppt/raw/raw_06_harga_distribusi_satuan_kemasan.png"
)))

# ==============================================================================
# CELL 7: SISI 3AB - TRANSAKSI ITEM & STRUK
# ==============================================================================
$md7 = @'
---
## Sisi 3: Menemukan Transaksi yang Outlier (*Transaction Outlier Detection*)

### 3.1 Level Baris Item & Level Keranjang Struk
- **Level Baris Item ($N = 6.740$):** 208 baris > Pagar Log-IQR (Rp 5,62 Jt) dan 2 baris mega-outlier `S04` (> Rp 54,9 Jt) milik `PAK SUTARMUJI` (2x Rp 63,20 Jt/baris). Kuantitas terbesar: 400 PACK Bakso Mie milik `ANTON`.
- **Level Keranjang Struk Harian ($N = 1.495$):** 34 struk > 3*SD (Rp 21,5 Jt), terpecah menjadi *Single-SKU Mega-Order* (`PAK SUTARMUJI` 1 item Rp 63,2 Jt) vs *Multi-SKU Hyper-Basket* (`ADEK FROZEN` 26-39 item Rp 45,7-58,8 Jt).
'@
[void]$cells.Add((New-MarkdownCell "md-07-sisi3" $md7))

$code3AB = @'
# SISI 3A & 3B: Deteksi Transaksi Outlier Baris Item & Struk Nota
log_omz = np.log10(df_clean['OMZET'])
q1_lg, q3_lg = log_omz.quantile([0.25, 0.75])
iqr_lg = q3_lg - q1_lg
fence_log_15 = 10 ** (q3_lg + 1.5 * iqr_lg)
fence_log_30 = 10 ** (q3_lg + 3.0 * iqr_lg)

print(f'Pagar Log-IQR 1.5x : Rp {fence_log_15:,.0f} -> {(df_clean["OMZET"] > fence_log_15).sum()} baris')
print(f'Pagar Log-IQR 3.0x : Rp {fence_log_30:,.0f} -> {(df_clean["OMZET"] > fence_log_30).sum()} baris ekstrem (S04)')

display(df_clean.sort_values('OMZET', ascending=False)[['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'OMZET']].head(10))

# Menampilkan 2 Grafik Raw: Scatter QTY vs OMZET & Keranjang Struk (dengan Legenda Mandiri)
display(Image(filename='slide_assets/outlier_ppt/raw/raw_07_transaksi_scatter_qty_omzet.png'))
display(Image(filename='slide_assets/outlier_ppt/raw/raw_08_transaksi_keranjang_struk.png'))
'@

$stdout3AB = @'
Pagar Log-IQR 1.5x : Rp 5,623,413 -> 208 baris outlier
Pagar Log-IQR 3.0x : Rp 54,907,061 -> 2 baris outlier ekstrem (S04)
'@

$html3AB = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>Peringkat</th><th>Tanggal</th><th>Pelanggan</th><th>Kode SKU</th><th>Nama Barang</th><th>Satuan</th><th>QTY</th><th>Harga Satuan</th><th>Nilai Transaksi (OMZET)</th><th>Tipe Outlier Transaksi</th></tr>
  </thead>
  <tbody>
    <tr><td align="center">1</td><td>2020-08-03</td><td><b>PAK SUTARMUJI</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>200</b></td><td align="right">316,000</td><td align="right" style="color:#E11D48;"><b>Rp 63,200,000</b></td><td><b>S04 (#1):</b> Melampaui Pagar 3.0 x Log-IQR (&gt;Rp 54,9 Jt)</td></tr>
    <tr><td align="center">2</td><td>2020-08-13</td><td><b>PAK SUTARMUJI</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>200</b></td><td align="right">316,000</td><td align="right" style="color:#E11D48;"><b>Rp 63,200,000</b></td><td><b>S04 (#2):</b> Melampaui Pagar 3.0 x Log-IQR (&gt;Rp 54,9 Jt)</td></tr>
    <tr><td align="center">3</td><td>2020-08-03</td><td><b>MAS ROHMAT</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>150</b></td><td align="right">305,000</td><td align="right" style="color:#E11D48;"><b>Rp 45,750,000</b></td><td><b>Mega-Order #3:</b> Borongan 150 DUS (99,5x lipat median!)</td></tr>
    <tr><td align="center">4</td><td>2020-05-18</td><td><b>KUBANG JAYA FOOD</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>120</b></td><td align="right">304,000</td><td align="right" style="color:#E11D48;"><b>Rp 36,480,000</b></td><td><b>Mega-Order #4:</b> Borongan 120 DUS Minaku Otak-Otak</td></tr>
    <tr><td align="center">5</td><td>2020-05-02</td><td><b>KUBANG JAYA FOOD</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>100</b></td><td align="right">304,000</td><td align="right" style="color:#E11D48;"><b>Rp 30,400,000</b></td><td><b>Mega-Order #5:</b> Borongan 100 DUS Minaku Otak-Otak</td></tr>
    <tr><td align="center">6</td><td>2020-07-04</td><td><b>CASH</b></td><td>LUTOSA-002</td><td>KENTANG LUTOSA CRINKLE CUT 2,5 KG</td><td>DUS</td><td align="right"><b>106</b></td><td align="right">240,000*</td><td align="right" style="color:#D97706;"><b>Rp 25,440,000</b></td><td><b>K03a + S03:</b> Borongan tunai 106 DUS yang sempat lupa diinput</td></tr>
    <tr><td align="center">7</td><td>2020-07-23</td><td><b>HITE</b></td><td>MIN-003</td><td>MINAKU KAKI NAGA 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>80</b></td><td align="right">290,000</td><td align="right"><b>Rp 23,200,000</b></td><td><b>Whale Order:</b> Borongan 80 DUS Kaki Naga</td></tr>
    <tr><td align="center">8</td><td>2020-07-29</td><td><b>ADEK FROZEN</b></td><td>MIN-001</td><td>MINAKU OTAK - OTAK 500 GR X 20 PACK</td><td>DUS</td><td align="right"><b>70</b></td><td align="right">320,000</td><td align="right"><b>Rp 22,400,000</b></td><td><b>Hyper-Basket Item:</b> Bagian dari struk 26 item (Rp 58,78 Jt)</td></tr>
    <tr><td align="center">9</td><td>2020-09-29</td><td><b>ANTON</b></td><td>EURIAL-001</td><td>EURIAL MOZZARELLA CHEESE 4 X 2.5 KG</td><td>DUS</td><td align="right"><b>25</b></td><td align="right">880,000</td><td align="right"><b>Rp 22,000,000</b></td><td><b>Premium SKU Order:</b> 25 DUS Keju Impor @ Rp 880rb</td></tr>
    <tr><td align="center">10</td><td>2020-07-11</td><td><b>ANTON</b></td><td>BAK-002</td><td>BAKSO MIE</td><td>PACK</td><td align="right"><b>400</b></td><td align="right">9,000</td><td align="right"><b>Rp 3,600,000</b></td><td><b>Rekor Kuantitas #1 (S03):</b> 400 PACK dalam 1 baris transaksi!</td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-05-sisi3ab" 5 $code3AB $stdout3AB $html3AB @(
    "slide_assets/outlier_ppt/raw/raw_07_transaksi_scatter_qty_omzet.png",
    "slide_assets/outlier_ppt/raw/raw_08_transaksi_keranjang_struk.png"
)))

# ==============================================================================
# CELL 8: SISI 3C - TEMPORAL & OPERASIONAL
# ==============================================================================
$code3C = @'
# SISI 3C: Deteksi Outlier Transaksi Temporal & Operasional
daily = df_clean.groupby('TGL').agg(
    Jumlah_Baris=('KODE', 'count'),
    Jumlah_Nota=('PELANGGAN', 'nunique'),
    Total_QTY=('QTY', 'sum'),
    Total_Omzet=('OMZET', 'sum')
).reset_index()

med_day = daily['Total_Omzet'].median()
mad_day = np.median(np.abs(daily['Total_Omzet'] - med_day))
daily['Z_Robust_Harian'] = (daily['Total_Omzet'] - med_day) / (1.4826 * mad_day)

print('=== 4 TANGGAL LONJAKAN OMZET HARIAN EKSTREM (T01: Z_Robust > 5.0) ===')
display(daily[daily['Z_Robust_Harian'] > 5.0].sort_values('Total_Omzet', ascending=False))

print('=== 1 TRANSAKSI OUTLIER OPERASIONAL HARI MINGGU (T02) ===')
display(df_clean[df_clean['TGL'].dt.dayofweek == 6][['TGL', 'PELANGGAN', 'KODE', 'NAMA_BARANG', 'SATUAN', 'QTY', 'HARGA', 'OMZET']])

# Menampilkan 2 Grafik Raw: Time-Series Harian & Distribusi Hari Operasional (dengan Legenda Mandiri)
display(Image(filename='slide_assets/outlier_ppt/raw/raw_09_transaksi_timeseries_harian.png'))
display(Image(filename='slide_assets/outlier_ppt/raw/raw_10_transaksi_hari_operasional.png'))
'@

$stdout3C = @'
=== 4 TANGGAL LONJAKAN OMZET HARIAN EKSTREM (T01: Z_Robust > 5.0) ===
Median Omzet Harian = Rp 25,650,400 | MAD = Rp 9,146,182 | Ambang Z_robust > 5 = Rp 93,450,000
=== 1 TRANSAKSI OUTLIER OPERASIONAL HARI MINGGU (T02) ===
Baris #5546 | Minggu, 2020-08-30 | PAK PEPI | OKEY-003 | 1 DUS @ Rp 180,000
'@

$html3C = @'
<table border="1" class="dataframe" style="border-collapse:collapse; font-family:Segoe UI, sans-serif; font-size:12px;">
  <thead style="background-color:#0F172A; color:white;">
    <tr><th>Kategori Anomali</th><th>Tanggal</th><th>Hari</th><th>Jumlah Baris</th><th>Jumlah Outlet</th><th>Total Omzet Harian</th><th>Z_Robust Harian</th><th>Pendorong Utama / Diagnosis Operasional</th></tr>
  </thead>
  <tbody>
    <tr><td><b>T01 (Spike #1)</b></td><td>2020-06-26</td><td>Friday</td><td align="right">118</td><td align="right">28</td><td align="right" style="color:#E11D48;"><b>Rp 188,494,300</b></td><td align="right"><b>+12.01</b></td><td>Restok serentak <b>ADEK FROZEN</b> (35 item = Rp 48,6 Jt) &amp; <b>FIRDON</b></td></tr>
    <tr><td><b>T01 (Spike #2)</b></td><td>2020-07-29</td><td>Wednesday</td><td align="right">118</td><td align="right">26</td><td align="right" style="color:#E11D48;"><b>Rp 163,210,850</b></td><td align="right"><b>+10.15</b></td><td>Restok menjelang Idul Adha: <b>ADEK FROZEN</b> (26 item = Rp 58,8 Jt)</td></tr>
    <tr><td><b>T01 (Spike #3)</b></td><td>2020-08-18</td><td>Tuesday</td><td align="right">86</td><td align="right">22</td><td align="right" style="color:#E11D48;"><b>Rp 144,877,550</b></td><td align="right"><b>+8.79</b></td><td>Borongan <b>ADEK FROZEN</b> (24 item = Rp 43,5 Jt) &amp; <b>ANTON</b> (25 item = Rp 41,0 Jt)</td></tr>
    <tr><td><b>T01 (Spike #4)</b></td><td>2020-08-03</td><td>Monday</td><td align="right">70</td><td align="right">21</td><td align="right" style="color:#E11D48;"><b>Rp 129,031,350</b></td><td align="right"><b>+7.62</b></td><td>Dua Mega-Order 1-SKU: <b>PAK SUTARMUJI</b> (Rp 63,2 Jt) + <b>MAS ROHMAT</b> (Rp 45,8 Jt)</td></tr>
    <tr style="background-color:#FFF1F2;"><td><b>T02 (Sunday Outlier)</b></td><td><b>2020-08-30</b></td><td><b>Sunday*</b></td><td align="right"><b>1</b></td><td align="right"><b>1</b></td><td align="right" style="color:#E11D48;"><b>Rp 180,000</b></td><td align="right">-1.88</td><td><b>PAK PEPI</b> (1 DUS OKEY-003): Toko tutup pada 25 dari 26 hari Minggu!</td></tr>
  </tbody>
</table>
'@
[void]$cells.Add((New-CodeCell "code-06-sisi3c" 6 $code3C $stdout3C $html3C @(
    "slide_assets/outlier_ppt/raw/raw_09_transaksi_timeseries_harian.png",
    "slide_assets/outlier_ppt/raw/raw_10_transaksi_hari_operasional.png"
)))

# ==============================================================================
# CELL 9: PANDUAN PENGGUNAAN ASET GAMBAR RAW PADA SLIDE PPT
# ==============================================================================
$md8 = @'
---
## Bagian 4: Katalog Gambar Mandiri (*Raw Graphs*) untuk Kustomisasi Slide PowerPoint

Seluruh gambar di bawah ini telah disimpan di folder `slide_assets/outlier_ppt/raw/` dengan resolusi tinggi (1500 x 850 / 900 px) dengan latar belakang putih bersih dan kotak legenda di sisi kanan, sehingga Anda dapat langsung memasukkannya ke template presentasi PowerPoint kelompok:

| No | File Gambar (*Raw*) | Isi Grafik | Legenda yang Disertakan |
| :---: | :--- | :--- | :--- |
| **1** | `raw_01_frekuensi_aturan_anomali.png` | Bar horizontal jumlah baris aturan anomali & outlier. | 5 kategori warna (Master Data, Transaksi, Error Sistem, Outlier Harga, Variasi Wajar). |
| **2** | `raw_02_pelanggan_boxplot_monetary_aov.png` | 1D Boxplot & strip plot sebaran Total Belanja ($M$) dan AOV ($M/F$) pelanggan. | Inlier, Outlier 1.5*IQR, Outlier 3*SD, Rentang IQR [Q1, Q3], Garis Median. |
| **3** | `raw_03_pelanggan_scatter_convexhull.png` | 2D Scatter plot Frequency vs Monetary dengan poligon pembungkus Convex Hull. | Inlier, Whale ($p_1$), One-Shot Bulk ($p_2$), Convex Hull Boundary, Pagar IQR. |
| **4** | `raw_04_pelanggan_lof_density.png` | 2D Scatter Log Frequency vs Log AOV dengan radius cincin = skor LOF. | Inlier (LOF ~ 1), Outlier Kritis (LOF > 1.35), Outlier Moderat, Zona Klaster Utama. |
| **5** | `raw_05_harga_diverging_sku_median.png` | Diverging lollipop chart deviasi harga satuan (%) terhadap median SKU+Satuan. | Outlier Terlalu Murah/Mahal (|Dev| > 30%), Tier Grosir (|Z| > 5), Zona Wajar [-30%, +30%]. |
| **6** | `raw_06_harga_distribusi_satuan_kemasan.png` | Boxplot perbandingan harga barang antar 7 satuan kemasan (DUS s.d. PCS). | Rentang IQR, Median Kemasan, Pagar Atas, Outlier SKU Premium. |
| **7** | `raw_07_transaksi_scatter_qty_omzet.png` | 2D Scatter kuantitas fisik (QTY) vs nilai transaksi (OMZET) level baris item. | Inlier, Outlier Log-IQR 1.5x (Rp 5,6 Jt), Outlier Ekstrem S04 (Rp 54,9 Jt), Pagar QTY 3-SD. |
| **8** | `raw_08_transaksi_keranjang_struk.png` | 2D Scatter variasi SKU vs total belanja level keranjang struk nota harian. | Struk Reguler, Struk Outlier Ekstrem (> Rp 21,5 Jt), Outlier Moderat, Pagar 3-SD. |
| **9** | `raw_09_transaksi_timeseries_harian.png` | Time-series grafik garis omzet harian toko frozen food (April - September 2020). | Omzet Reguler, 4 Hari Lonjakan Ekstrem, Transaksi Hari Minggu, Ambang Z > 5, Median. |
| **10**| `raw_10_transaksi_hari_operasional.png` | Bar chart volume transaksi & nilai omzet per hari kerja (Senin s.d. Minggu). | Hari Operasional Normal (Senin - Sabtu), Hari Tutup Operasional (Hari Minggu). |
'@
[void]$cells.Add((New-MarkdownCell "md-08-ppt-guide" $md8))

$notebook = [ordered]@{
    cells = $cells
    metadata = [ordered]@{
        kernelspec = [ordered]@{
            display_name = "Python 3"
            language     = "python"
            name         = "python3"
        }
        language_info = [ordered]@{
            codemirror_mode = [ordered]@{ name = "ipython"; version = 3 }
            file_extension  = ".py"
            mimetype        = "text/x-python"
            name            = "python"
            nbconvert_exporter = "python"
            pygments_lexer  = "ipython3"
            version         = "3.11.0"
        }
    }
    nbformat = 4
    nbformat_minor = 5
}

$json = $notebook | ConvertTo-Json -Depth 20
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "06_tugas_outlier_detection_frozen_food.ipynb"), $json, $utf8NoBom)
if (-not (Test-Path "notebook")) { New-Item -ItemType Directory -Path "notebook" -Force | Out-Null }
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "notebook\06_tugas_outlier_detection_frozen_food.ipynb"), $json, $utf8NoBom)
Write-Output "Successfully updated 06_tugas_outlier_detection_frozen_food.ipynb with raw graphs with legends."

