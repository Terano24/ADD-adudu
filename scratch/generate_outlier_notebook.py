import json
import os

notebook = {
    'cells': [],
    'metadata': {
        'kernelspec': {
            'display_name': 'Python 3',
            'language': 'python',
            'name': 'python3'
        },
        'language_info': {
            'name': 'python',
            'version': '3.9.6'
        }
    },
    'nbformat': 4,
    'nbformat_minor': 5
}

def add_md(source):
    notebook['cells'].append({
        'cell_type': 'markdown',
        'metadata': {},
        'source': [line + '\n' for line in source.strip().split('\n')]
    })

def add_code(source):
    notebook['cells'].append({
        'cell_type': 'code',
        'execution_count': None,
        'metadata': {},
        'outputs': [],
        'source': [line + '\n' for line in source.strip().split('\n')]
    })

# ==============================================================================
# CELL 1: HEADER & INTRO
# ==============================================================================
add_md('''# Analisis Deteksi Outlier Multi-Dimensi (Dataset Frozen Food)
### Mata Kuliah: Analisis Data Diskrit (ADD) — Institut Teknologi Sepuluh Nopember (ITS)

---

## 📌 Latar Belakang & Instruksi Tugas
Berdasarkan arahan eksplorasi data penjualan produk *frozen food*:
1. **Bukalah data frozen food yang pertama kali diberikan** (`Data Penjualan April - Sep 2020.xlsx`).
2. **Lakukan outlier detection pada data tersebut dalam beberapa sisi/dimensi**:
   - **Pelanggan yang outlier** (definisi *abnormality* ditentukan oleh diskusi kelompok).
   - **Harga barang yang outlier** (terlalu murah atau terlalu mahal bila dilihat dari dimensi $X$).
   - **Transaksi yang outlier** (definisi *abnormality* ditentukan oleh diskusi kelompok).

Notebook ini menyajikan deteksi outlier multi-dimensi secara komprehensif menggunakan kombinasi metode statistik (Tukey's Fences IQR, Robust Z-Score berbasis Median/MAD, Pagar Logaritmik) serta analisis perilaku bisnis (*domain knowledge* pergudangan & distribusi ritel).
''')

# ==============================================================================
# CELL 2: IMPORTS & CONFIGURATION
# ==============================================================================
add_code('''import os
import zipfile
import datetime
import math
from collections import defaultdict, Counter
from xml.etree import ElementTree as ET

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Konfigurasi Tampilan Pandas & Grafik
pd.set_option('display.max_columns', 30)
pd.set_option('display.width', 1000)
pd.set_option('display.float_format', lambda v: f'{v:,.2f}')

plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
plt.rcParams['font.sans-serif'] = 'DejaVu Sans, Arial, Helvetica'
plt.rcParams['font.size'] = 9.5
plt.rcParams['figure.dpi'] = 110

# Palet warna visualisasi
C_PRIMARY = '#1f77b4'
C_ALERT = '#d62728'
C_WARN = '#ff7f0e'
C_SUCCESS = '#2ca02c'
C_PURPLE = '#9467bd'

FILE_MENTAH = 'Data Penjualan April - Sep 2020.xlsx'
print(f"File data mentah yang akan dibuka: '{FILE_MENTAH}'")
''')

# ==============================================================================
# CELL 3: DATA LOADING (ROBUST EXCEL / XML READER)
# ==============================================================================
add_md('''---
## 1. Membaca Data Mentah Pertama Kali Diberikan (`Data Penjualan April - Sep 2020.xlsx`)

Data mentah berformat `.xlsx` dibaca secara langsung. Disediakan modul pembaca berbasis *Standard Library* (`zipfile` + `xml.etree`) sebagai *fallback* otomatis apabila lingkungan eksekusi belum memiliki pustaka pembaca khusus (`openpyxl`).
''')

add_code('''def baca_excel_frozen_food(path):
    """Membaca file Excel mentah dengan fallback xml/zipfile otomatis."""
    try:
        df = pd.read_excel(path, sheet_name='Sheet1')
        print("-> Berhasil dimuat via pd.read_excel.")
    except Exception as e:
        print(f"-> Fallback membaca struktur XML zip mentah ({e})...")
        ns = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
        z = zipfile.ZipFile(path)
        shared = [''.join(t.text or '' for t in si.iter(ns + 't'))
                  for si in ET.fromstring(z.read('xl/sharedStrings.xml'))]

        def col_idx(ref):
            letters = ''.join(c for c in ref if c.isalpha())
            n = 0
            for c in letters:
                n = n * 26 + (ord(c) - 64)
            return n - 1

        rows = []
        for r_elem in ET.fromstring(z.read('xl/worksheets/sheet1.xml')).find(ns + 'sheetData').findall(ns + 'row'):
            row_dict = {}
            for c in r_elem.findall(ns + 'c'):
                v = c.find(ns + 'v')
                if v is None or v.text is None:
                    continue
                row_dict[col_idx(c.get('r'))] = shared[int(v.text)] if c.get('t') == 's' else float(v.text)
            rows.append(row_dict)

        lebar = max(max(r.keys()) for r in rows if r) + 1
        tabel = [[r.get(i) for i in range(lebar)] for r in rows]
        df = pd.DataFrame(tabel[1:], columns=tabel[0])
    
    # Hapus baris yang seluruhnya kosong jika ada
    df = df.dropna(how='all').reset_index(drop=True)
    # Catat nomor baris asli Excel (header = baris 1, data mulai baris 2)
    df.insert(0, 'BARIS_ASLI', df.index + 2)
    
    # Konversi tanggal Excel serial jika masih berupa float/numerik
    def format_tgl(v):
        if pd.isna(v): return None
        if isinstance(v, (int, float)):
            return (datetime.datetime(1899, 12, 30) + datetime.timedelta(days=float(v))).strftime('%Y-%m-%d')
        return str(v)[:10]

    df['TGL_STR'] = df['TGL'].apply(format_tgl)
    df['TGL_DATETIME'] = pd.to_datetime(df['TGL_STR'], errors='coerce')
    
    # Konversi kolom numerik
    for col in ['QTY', 'HARGA', 'JUMLAH']:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
            
    return df

df_mentah = baca_excel_frozen_food(FILE_MENTAH)
print(f"Data Mentah Dimuat: {df_mentah.shape[0]:,} baris, {df_mentah.shape[1]} kolom.")
print(f"Rentang Waktu     : {df_mentah['TGL_STR'].min()} s/d {df_mentah['TGL_STR'].max()}")
print(f"Total Omzet Mentah: Rp {df_mentah['JUMLAH'].sum():,.2f}")
df_mentah.head(5)
''')

# ==============================================================================
# CELL 4: DIMENSI 1 - PELANGGAN OUTLIER
# ==============================================================================
add_md('''---
## 2. Dimensi 1: Outlier Detection pada Pelanggan (`PELANGGAN`)

### 🧠 Diskusi Kelompok Mengenai Definisi *Abnormality* Pelanggan
Pelanggan dalam bisnis distribusi B2B tidak homogen. Berdasarkan diskusi kelompok, *abnormality* pelanggan dipetakan ke dalam beberapa dimensi perilaku:
1. **Outlier Nilai Belanja Moneter (*Monetary Value*)**: Pelanggan "Paus" (*Super-Wholesaler*) yang kontribusi omzetnya menembus pagar atas ekstrem ($> Q_3 + 3 \times \text{IQR}$) vs Pelanggan Mikro terbawah.
2. **Outlier Ukuran Keranjang per Kedatangan (*Shock Buyer*)**: Pelanggan dengan frekuensi belanja sangat minim ($F \le 2$), namun memiliki rata-rata belanja per transaksi (*Average Order Value* / AOV) luar biasa kolosal (puluhan juta rupiah).
3. **Outlier Frekuensi Interaksi (*Hyper-Active* vs *One-Time Churned*)**: Pelanggan yang bertransaksi hampir setiap hari vs pelanggan yang hanya beli 1 kali lalu hilang permanen.
4. **Outlier Agregasi Identitas Anonim (`CASH`)**: Akun semu (*catch-all*) penampung pembeli walk-in non-member yang mendistorsi pemodelan pelanggan.
5. **Outlier Non-Komersial (Penerima Sampel Rp 0)**: Entitas promosi internal yang terdaftar di kolom pelanggan namun bersaldo Rp 0.
6. **Outlier Fragmentasi Ejaan / Prefiks Kanal**: Outlet yang terpecah identitasnya akibat kode kasir (`C -`, `F -`, dll.).
''')

add_code('''# Standardisasi nama pelanggan untuk membedakan entitas riil vs varian penulisan
def bersihkan_nama_pelanggan(nama):
    if pd.isna(nama) or str(nama).strip() == '':
        return 'TIDAK DIKETAHUI'
    s = str(nama).strip().upper()
    # Bersihkan prefiks kanal umum: "C - ", "F - ", "E - ", "I - ", "(MITRAKU) ", "MIAMI - "
    for prefix in ['C - ', 'F - ', 'E - ', 'I - ', 'MIAMI - ', 'M - ']:
        if s.startswith(prefix):
            s = s[len(prefix):].strip()
    s = s.replace('(MITRAKU)', '').strip()
    # Rapikan spasi ganda
    return ' '.join(s.split())

df_mentah['PELANGGAN_BERSIH'] = df_mentah['NAMA'].apply(bersihkan_nama_pelanggan)

# Agregasi metrik LRFM & Perilaku Pelanggan
tgl_maks = df_mentah['TGL_DATETIME'].max()
agg_pelanggan = df_mentah.groupby('PELANGGAN_BERSIH').agg(
    total_omzet=('JUMLAH', 'sum'),
    total_qty=('QTY', 'sum'),
    total_baris=('JUMLAH', 'count'),
    hari_aktif=('TGL_STR', 'nunique'),
    tgl_pertama=('TGL_DATETIME', 'min'),
    tgl_terakhir=('TGL_DATETIME', 'max'),
    nama_mentah_varian=('NAMA', lambda x: list(set(x)))
).reset_index()

# Hitung Average Order Value per baris transaksi (AOV)
agg_pelanggan['AOV_per_baris'] = agg_pelanggan['total_omzet'] / agg_pelanggan['total_baris']
agg_pelanggan['recency_hari'] = (tgl_maks - agg_pelanggan['tgl_terakhir']).dt.days
agg_pelanggan['persen_omzet'] = (agg_pelanggan['total_omzet'] / df_mentah['JUMLAH'].sum()) * 100

print(f"Total Pelanggan Terdaftar (Mentah) : {df_mentah['NAMA'].nunique()} entitas")
print(f"Total Pelanggan Terdaftar (Bersih) : {agg_pelanggan.shape[0]} entitas riil")
print(f"Jumlah Pelanggan yang Terfragmentasi: {df_mentah['NAMA'].nunique() - agg_pelanggan.shape[0]} varian")
''')

# ==============================================================================
# CELL 5: CODE - DETAIL TEMUAN OUTLIER PELANGGAN
# ==============================================================================
add_code('''# 1. Pagar Statistik IQR untuk Monetary & AOV
q1_m = agg_pelanggan['total_omzet'].quantile(0.25)
q3_m = agg_pelanggan['total_omzet'].quantile(0.75)
iqr_m = q3_m - q1_m
pagar_atas_monetary = q3_m + 3.0 * iqr_m  # Pagar luar (Extreme Outlier)

q1_aov = agg_pelanggan['AOV_per_baris'].quantile(0.25)
q3_aov = agg_pelanggan['AOV_per_baris'].quantile(0.75)
iqr_aov = q3_aov - q1_aov
pagar_atas_aov = q3_aov + 3.0 * iqr_aov

print("=== STATISTIK PAGAR TUKEY (EXTREME OUTLIER) ===")
print(f"Pagar Atas Monetary Ekstrem: Rp {pagar_atas_monetary:,.2f}")
print(f"Pagar Atas AOV Ekstrem     : Rp {pagar_atas_aov:,.2f}\\n")

# A. Outlier Super-Wholesaler (Paus)
paus = agg_pelanggan[agg_pelanggan['total_omzet'] > pagar_atas_monetary].sort_values(by='total_omzet', ascending=False)
print("=== 1. TOP OUTLIER MONETER (SUPER-WHOLESALER / PAUS) ===")
print(paus[['PELANGGAN_BERSIH', 'total_omzet', 'persen_omzet', 'total_baris', 'hari_aktif']].head(10).to_string(index=False))

# B. Outlier Shock Buyer (Kunjungan Sangat Sedikit, Nilai Transaksi Masif)
shock_buyer = agg_pelanggan[(agg_pelanggan['hari_aktif'] <= 2) & (agg_pelanggan['AOV_per_baris'] > 10_000_000)].sort_values(by='AOV_per_baris', ascending=False)
print("\\n=== 2. OUTLIER SHOCK BUYER (AOV PER BARIS SANGAT BESAR, FREKUENSI <= 2) ===")
print(shock_buyer[['PELANGGAN_BERSIH', 'total_omzet', 'total_baris', 'hari_aktif', 'AOV_per_baris']].to_string(index=False))

# C. Outlier Pelanggan Non-Komersial (Saldo Omzet Rp 0)
non_komersial = agg_pelanggan[agg_pelanggan['total_omzet'] == 0]
print("\\n=== 3. OUTLIER PELANGGAN NON-KOMERSIAL (OMZET = RP 0) ===")
print(non_komersial[['PELANGGAN_BERSIH', 'total_omzet', 'total_qty', 'total_baris']].to_string(index=False))

# D. Outlier Anomali Anonim CASH
cash_info = agg_pelanggan[agg_pelanggan['PELANGGAN_BERSIH'] == 'CASH']
print("\\n=== 4. PROFIL ANOMALI IDENTITAS CASH ===")
print(cash_info[['PELANGGAN_BERSIH', 'total_omzet', 'persen_omzet', 'total_baris', 'hari_aktif']].to_string(index=False))
''')

# ==============================================================================
# CELL 6: VISUALISASI OUTLIER PELANGGAN
# ==============================================================================
add_code('''fig, axes = plt.subplots(1, 2, figsize=(15, 6))

# Plot 1: Scatter Frekuensi vs Omzet (Skala Log)
df_plot = agg_pelanggan[agg_pelanggan['total_omzet'] > 0].copy()
sns.scatterplot(
    data=df_plot,
    x='total_baris',
    y='total_omzet',
    alpha=0.6,
    color=C_PRIMARY,
    s=60,
    ax=axes[0]
)

# Highlight Outlier Khusus
outlier_highlight = ['TOKO CITA RASA BARU', 'ADEK FROZEN', 'ANTON', 'PAK SUTARMUJI', 'MAS ROHMAT', 'CASH']
for _, r in df_plot[df_plot['PELANGGAN_BERSIH'].isin(outlier_highlight)].iterrows():
    axes[0].scatter(r['total_baris'], r['total_omzet'], color=C_ALERT, s=120, zorder=5)
    axes[0].annotate(
        r['PELANGGAN_BERSIH'],
        (r['total_baris'], r['total_omzet']),
        textcoords="offset points",
        xytext=(5, 5),
        fontweight='bold',
        fontsize=8.5,
        color='#900C3F'
    )

axes[0].set_xscale('log')
axes[0].set_yscale('log')
axes[0].set_title('Peta Sebaran Pelanggan: Frekuensi vs Omzet (Skala Log)', fontweight='bold')
axes[0].set_xlabel('Frekuensi Baris Transaksi (Log Scale)')
axes[0].set_ylabel('Total Omzet Belanja (Rp, Log Scale)')
axes[0].grid(True, which='both', linestyle='--', alpha=0.5)

# Plot 2: Top 10 Pelanggan Penyumbang Omzet Terbesar
top10 = agg_pelanggan.sort_values(by='total_omzet', ascending=True).tail(10)
bars = axes[1].barh(top10['PELANGGAN_BERSIH'], top10['total_omzet'] / 1e6, color='#2b5c8f')
axes[1].set_title('Top 10 Pelanggan dengan Nilai Belanja Tertinggi (Juta Rp)', fontweight='bold')
axes[1].set_xlabel('Total Omzet (Juta Rupiah)')

for bar in bars:
    w = bar.get_width()
    axes[1].text(w + 5, bar.get_y() + bar.get_height()/2, f'Rp {w:,.1f}M', va='center', fontsize=8.5)

axes[1].set_xlim(0, top10['total_omzet'].max() / 1e6 * 1.15)
plt.tight_layout()
plt.show()
''')

# ==============================================================================
# CELL 7: DIMENSI 2 - HARGA BARANG OUTLIER
# ==============================================================================
add_md('''---
## 3. Dimensi 2: Outlier Detection pada Harga Barang (`HARGA`) Dilihat dari Dimensi $X$

### 🧠 Diskusi Kelompok Mengenai Sudut Pandang $X$
Instruksi tugas menyatakan: *"Temukan harga barang yang outlier (terlalu murah atau terlalu mahal bila dilihat dari X)"*. Diskusi kelompok kami merumuskan 5 sudut pandang $X$ konkret:
1. **$X_1 = \text{Harga Nol (Rp 0)}$**: Outlier karena barang komersial wajib bernilai $> 0$. Dipecah menjadi dua pola fundamental: **Missing Price (Kelalaian Kasir pada transaksi tunai bervolume besar)** vs **Tester / Promosi Kuantitas Kecil**.
2. **$X_2 = \text{Median Harga SKU pada Satuan yang Sama}$**: Mendeteksi penyimpangan $> 30\%$ dari harga wajar pasar (misal diskon kekeluargaan *"Fadil Anak Bos"* vs markup ritel/kafe).
3. **$X_3 = \text{Satuan Kemasan (DUS vs PACK vs Kemasan Khusus)}$**: Membandingkan rasio kelipatan harga antara grosir kardus vs kemasan eceran serta satuan khusus (`BKS` cone murah, `PAIL` es krim bulk, `JRG` saus).
4. **$X_4 = \text{Kelompok / Bahan Komoditas Produk}$**: Perbedaan rentang harga daging sapi premium vs olahan singkong/cireng.
5. **$X_5 = \text{Rasio Diskon Aritmetika}$**: Diskon ekstrem yang memotong lebih dari separuh nilai normal ($\text{JUMLAH} < 80\% \times \text{QTY} \times \text{HARGA}$).
''')

add_code('''# Hitung Median Harga per SKU dan Satuan
sku_sat_valid = df_mentah[df_mentah['HARGA'] > 0].copy()
median_sku_sat = sku_sat_valid.groupby(['KODEBARA', 'SATUAN'])['HARGA'].agg(
    median_harga='median',
    mean_harga='mean',
    std_harga='std',
    count_trx='count'
).reset_index()

# Gabungkan ke dataframe transaksi untuk analisis deviasi
df_harga = df_mentah.merge(median_sku_sat, on=['KODEBARA', 'SATUAN'], how='left')
df_harga['deviasi_persen'] = ((df_harga['HARGA'] - df_harga['median_harga']) / df_harga['median_harga']) * 100

# Hitung Rasio Aritmetika Diskon: JUMLAH / (QTY * HARGA)
df_harga['nominal_kotor'] = df_harga['QTY'] * df_harga['HARGA']
df_harga['rasio_diskon'] = np.where(df_harga['nominal_kotor'] > 0, df_harga['JUMLAH'] / df_harga['nominal_kotor'], 1.0)

print(f"Total Baris dengan HARGA = 0: {(df_harga['HARGA'] == 0).sum()} baris")
print(f"Total Baris dengan Deviasi Harga > 30% dari Median: {(df_harga['deviasi_persen'].abs() > 30).sum()} baris")
print(f"Total Baris dengan Diskon Ekstrem (Rasio < 0.80)   : {(df_harga['rasio_diskon'] < 0.80).sum()} baris")
''')

# ==============================================================================
# CELL 8: DETAIL OUTLIER HARGA DARI BERBAGAI SUDUT PANDANG X
# ==============================================================================
add_code('''# A. Sudut Pandang X1: Harga Nol (Rp 0)
zero_prices = df_harga[df_harga['HARGA'] == 0].copy()
zero_cash = zero_prices[zero_prices['PELANGGAN_BERSIH'] == 'CASH']
zero_promo = zero_prices[zero_prices['PELANGGAN_BERSIH'] != 'CASH']

print("=== SUDUT PANDANG X1: HARGA NOL (RP 0) ===")
print(f"1. Missing Price Kasir Tunai (Omzet Hilang) : {len(zero_cash)} baris")
print(f"2. Barang Tester / Sampling Promosi Murni   : {len(zero_promo)} baris")

print("\\nContoh Kasir Lupa Input Harga pada Transaksi Borongan CASH:")
print(zero_cash[['BARIS_ASLI', 'TGL_STR', 'KODEBARA', 'NAMABARA', 'QTY', 'SATUAN', 'NAMA']].head(4).to_string(index=False))

print("\\nContoh Barang Tester Promosi ke Mitra Toko:")
print(zero_promo[['BARIS_ASLI', 'TGL_STR', 'KODEBARA', 'NAMABARA', 'QTY', 'SATUAN', 'NAMA']].head(4).to_string(index=False))

# B. Sudut Pandang X2: Deviasi dari Median SKU Sejenis
outlier_deviasi = df_harga[df_harga['deviasi_persen'].abs() > 25].sort_values(by='deviasi_persen', ascending=True)
print("\\n=== SUDUT PANDANG X2: DEVIASI HARGA DARI MEDIAN SKU SEJENIS ===")
print("Top 5 Terlalu Murah:")
print(outlier_deviasi[['BARIS_ASLI', 'NAMABARA', 'SATUAN', 'HARGA', 'median_harga', 'deviasi_persen', 'NAMA']].head(5).to_string(index=False))
print("\\nTop 5 Terlalu Mahal:")
print(outlier_deviasi[['BARIS_ASLI', 'NAMABARA', 'SATUAN', 'HARGA', 'median_harga', 'deviasi_persen', 'NAMA']].tail(5).to_string(index=False))

# C. Sudut Pandang X5: Diskon Ekstrem (Rasio < 0.80)
diskon_ekstrem = df_harga[df_harga['rasio_diskon'] < 0.80]
print("\\n=== SUDUT PANDANG X5: POTONGAN HARGA EKSTREM (DISKON 50%) ===")
print(diskon_ekstrem[['BARIS_ASLI', 'TGL_STR', 'NAMABARA', 'QTY', 'SATUAN', 'HARGA', 'JUMLAH', 'rasio_diskon', 'NAMA']].to_string(index=False))
''')

# ==============================================================================
# CELL 9: VISUALISASI OUTLIER HARGA
# ==============================================================================
add_code('''fig, axes = plt.subplots(1, 2, figsize=(15, 5.5))

# Plot 1: Sebaran Deviasi Persentase Harga terhadap Median SKU
dev_data = df_harga[df_harga['HARGA'] > 0]['deviasi_persen'].dropna()
sns.histplot(dev_data, bins=60, kde=True, color=C_PRIMARY, ax=axes[0])
axes[0].axvline(-30, color=C_ALERT, linestyle='--', linewidth=1.5, label='Batas Terlalu Murah (-30%)')
axes[0].axvline(30, color=C_ALERT, linestyle='--', linewidth=1.5, label='Batas Terlalu Mahal (+30%)')
axes[0].set_title('Distribusi Deviasi Harga terhadap Median SKU (%)', fontweight='bold')
axes[0].set_xlabel('Deviasi dari Median (%)')
axes[0].set_ylabel('Jumlah Transaksi')
axes[0].legend()
axes[0].set_xlim(-60, 60)

# Plot 2: Perbandingan Harga Produk Dijual dalam DUS vs PACK
produk_dua_satuan = ['MIN-001', 'JOF-002', 'OKEY-001', 'LUTOSA-002', 'MIT-010']
sample_sat = df_harga[(df_harga['KODEBARA'].isin(produk_dua_satuan)) & (df_harga['SATUAN'].isin(['DUS', 'PACK'])) & (df_harga['HARGA'] > 0)]

sns.boxplot(
    data=sample_sat,
    x='KODEBARA',
    y='HARGA',
    hue='SATUAN',
    palette={'DUS': '#e74c3c', 'PACK': '#3498db'},
    ax=axes[1]
)
axes[1].set_yscale('log')
axes[1].set_title('Perbandingan Harga Kemasan Grosir (DUS) vs Eceran (PACK)', fontweight='bold')
axes[1].set_xlabel('Kode Produk')
axes[1].set_ylabel('Harga Satuan (Rp, Skala Log)')
axes[1].grid(True, which='both', linestyle='--', alpha=0.5)

plt.tight_layout()
plt.show()
''')

# ==============================================================================
# CELL 10: DIMENSI 3 - TRANSAKSI OUTLIER
# ==============================================================================
add_md('''---
## 4. Dimensi 3: Outlier Detection pada Transaksi (`TRANSAKSI`)

### 🧠 Diskusi Kelompok Mengenai Definisi *Abnormality* Transaksi
Pada tingkat baris transaksi nota/struk kasir, *abnormality* terjadi ketika sifat transaksi melanggar distribusi umum atau logika operasional:
1. **Outlier Nilai Rupiah Transaksi (`JUMLAH` Ekstrem)**: Nilai total struk di atas pagar luar logaritmik ($> \text{Rp } 54.907.061$).
2. **Outlier Kuantitas Pemesanan (`QTY` Ekstrem)**: Jumlah fisik unit yang dipesan menyimpang sangat jauh dari kebiasaan normal ($z_{\text{robust}} > 8$).
3. **Outlier Duplikasi Transaksi Persis (*Exact Duplicates*)**: Rekaman kembar identik 100% pada semua kolom yang terjadi akibat kesalahan kasir menekan tombol kirim ganda.
4. **Outlier Anomali Temporal**:
   - **Transaksi di Hari Minggu**: Transaksi yang tercatat pada hari tutup operasional toko.
   - **Hari Lonjakan Omzet Harian (*Spike Days*)**: Hari dengan akumulasi omzet melonjak di atas $5\times$ median harian normal.
5. **Outlier Diskrepansi Aritmetika Transaksi**: Baris transaksi di mana $\text{JUMLAH} \neq \text{QTY} \times \text{HARGA}$.
''')

add_code('''# A. Deteksi Nilai Transaksi Rupiah Ekstrem (Pagar IQR Skala Log)
log_jumlah = np.log10(df_mentah[df_mentah['JUMLAH'] > 0]['JUMLAH'])
q1_lj = log_jumlah.quantile(0.25)
q3_lj = log_jumlah.quantile(0.75)
iqr_lj = q3_lj - q1_lj
pagar_atas_log_jumlah = 10 ** (q3_lj + 3.0 * iqr_lj)

trx_omzet_ekstrem = df_mentah[df_mentah['JUMLAH'] > pagar_atas_log_jumlah].sort_values(by='JUMLAH', ascending=False)
print(f"Pagar Atas Logaritmik Nilai Transaksi: Rp {pagar_atas_log_jumlah:,.2f}")
print(f"Total Transaksi Nilai Ekstrem (> Pagar): {len(trx_omzet_ekstrem)} transaksi\\n")
print(trx_omzet_ekstrem[['BARIS_ASLI', 'TGL_STR', 'KODEBARA', 'NAMABARA', 'QTY', 'SATUAN', 'HARGA', 'JUMLAH', 'NAMA']].to_string(index=False))

# B. Deteksi Kuantitas Ekstrem berbasis Z-Score Robust per SKU
def z_robust(s):
    med = s.median()
    mad = (s - med).abs().median()
    if mad == 0:
        return pd.Series(0, index=s.index)
    return 0.6745 * (s - med) / mad

df_mentah['z_qty_sku'] = df_mentah.groupby('KODEBARA')['QTY'].transform(z_robust)
trx_qty_ekstrem = df_mentah[df_mentah['z_qty_sku'] > 8].sort_values(by='QTY', ascending=False)
print(f"\\nTotal Transaksi Kuantitas Ekstrem (z_robust > 8): {len(trx_qty_ekstrem)} transaksi")
print("Top 5 Transaksi Kuantitas Tertinggi:")
print(trx_qty_ekstrem[['BARIS_ASLI', 'TGL_STR', 'NAMABARA', 'QTY', 'SATUAN', 'HARGA', 'JUMLAH', 'NAMA']].head(5).to_string(index=False))
''')

# ==============================================================================
# CELL 11: DUPLIKASI DAN ANOMALI TEMPORAL
# ==============================================================================
add_code('''# C. Duplikasi Transaksi Persis
KOLOM_IDENTITAS = ['TGL', 'KODEBARA', 'QTY', 'SATUAN', 'HARGA', 'JUMLAH', 'NAMA']
duplikat_mask = df_mentah.duplicated(subset=KOLOM_IDENTITAS, keep=False)
duplikat_salinan = df_mentah.duplicated(subset=KOLOM_IDENTITAS, keep='first')

print(f"Total Baris Terlibat Duplikasi Persis : {duplikat_mask.sum()} baris")
print(f"Total Salinan Berlebih (Redundant)    : {duplikat_salinan.sum()} baris\\n")
print("Contoh Pasangan Duplikat Persis:")
print(df_mentah[duplikat_mask][['BARIS_ASLI', 'TGL_STR', 'NAMABARA', 'QTY', 'SATUAN', 'JUMLAH', 'NAMA']].head(6).to_string(index=False))

# D. Anomali Temporal: Transaksi Hari Minggu
df_mentah['HARI_NAMA'] = df_mentah['TGL_DATETIME'].dt.day_name()
trx_minggu = df_mentah[df_mentah['HARI_NAMA'] == 'Sunday']
print(f"\\nTotal Transaksi Tercatat pada Hari Minggu: {len(trx_minggu)} transaksi")
print(trx_minggu[['BARIS_ASLI', 'TGL_STR', 'HARI_NAMA', 'NAMABARA', 'QTY', 'SATUAN', 'JUMLAH', 'NAMA']].to_string(index=False))

# E. Anomali Temporal: Hari Lonjakan Omzet Harian (Spike Days)
omzet_harian = df_mentah.groupby('TGL_STR').agg(
    total_omzet=('JUMLAH', 'sum'),
    jumlah_trx=('JUMLAH', 'count')
).reset_index()

omzet_harian['z_harian'] = z_robust(omzet_harian['total_omzet'])
hari_spike = omzet_harian[omzet_harian['z_harian'] > 5].sort_values(by='total_omzet', ascending=False)

print(f"\\nMedian Omzet Harian Normal: Rp {omzet_harian['total_omzet'].median():,.2f}")
print("Hari dengan Lonjakan Omzet Harian Ekstrem (z_robust > 5):")
print(hari_spike.to_string(index=False))
''')

# ==============================================================================
# CELL 12: VISUALISASI TRANSAKSI
# ==============================================================================
add_code('''fig, axes = plt.subplots(1, 2, figsize=(16, 5.5))

# Plot 1: Tren Omzet Harian & Penanda Hari Lonjakan
omzet_harian['TGL_DT'] = pd.to_datetime(omzet_harian['TGL_STR'])
omzet_harian_sorted = omzet_harian.sort_values(by='TGL_DT')

axes[0].plot(omzet_harian_sorted['TGL_DT'], omzet_harian_sorted['total_omzet'] / 1e6, color='#4a90e2', linewidth=1.5, label='Omzet Harian')
axes[0].axhline(omzet_harian['total_omzet'].median() / 1e6, color='gray', linestyle='--', label=f'Median: Rp {omzet_harian[\"total_omzet\"].median()/1e6:.1f}M')

# Titik lonjakan
spike_dt = pd.to_datetime(hari_spike['TGL_STR'])
axes[0].scatter(spike_dt, hari_spike['total_omzet'] / 1e6, color=C_ALERT, s=80, zorder=5, label='Hari Lonjakan Ekstrem')

for _, r in hari_spike.iterrows():
    axes[0].annotate(
        r['TGL_STR'],
        (pd.to_datetime(r['TGL_STR']), r['total_omzet'] / 1e6),
        textcoords="offset points",
        xytext=(0, 7),
        ha='center',
        fontsize=8,
        fontweight='bold',
        color='#900C3F'
    )

axes[0].set_title('Tren Omzet Penjualan Harian & Deteksi Lonjakan Anomali', fontweight='bold')
axes[0].set_xlabel('Tanggal')
axes[0].set_ylabel('Total Omzet (Juta Rupiah)')
axes[0].legend(loc='upper left')

# Plot 2: Scatter Plot Log(QTY) vs Log(JUMLAH)
df_valid_trx = df_mentah[(df_mentah['QTY'] > 0) & (df_mentah['JUMLAH'] > 0)].copy()
sns.scatterplot(
    data=df_valid_trx,
    x='QTY',
    y='JUMLAH',
    alpha=0.4,
    color='#34495e',
    s=30,
    ax=axes[1]
)

# Highlight transaksi bernilai > Rp 30 Juta
top_trx = df_valid_trx[df_valid_trx['JUMLAH'] >= 30_000_000]
axes[1].scatter(top_trx['QTY'], top_trx['JUMLAH'], color=C_ALERT, s=90, zorder=5, label='Trx Ekstrem (>= Rp 30M)')

for _, r in top_trx.iterrows():
    axes[1].annotate(
        f"{r['NAMA'].split()[-1]}\\nRp {r['JUMLAH']/1e6:.1f}M",
        (r['QTY'], r['JUMLAH']),
        textcoords="offset points",
        xytext=(5, -5),
        fontsize=7.5,
        fontweight='bold',
        color='#900C3F'
    )

axes[1].set_xscale('log')
axes[1].set_yscale('log')
axes[1].set_title('Sebaran Transaksi: Hubungan Log(QTY) vs Log(JUMLAH)', fontweight='bold')
axes[1].set_xlabel('Kuantitas (QTY, Skala Log)')
axes[1].set_ylabel('Total Nilai Transaksi (Rp, Skala Log)')
axes[1].legend()

plt.tight_layout()
plt.show()
''')

# ==============================================================================
# CELL 13: RANGKUMAN & MATRIKS REKOMENDASI KEBIJAKAN
# ==============================================================================
add_md('''---
## 5. Rangkuman Matriks Outlier & Rekomendasi Kebijakan Data Science

Berdasarkan seluruh temuan investigasi multi-dimensi di atas, berikut adalah matriks sintesis komprehensif beserta rekomendasi tindak lanjut bagi analisis data dan pemodelan statistik berikutnya:

| No | Dimensi Outlier | Sub-Kategori / Aturan | Tolok Ukur Statistik / Bisnis | Baris / Entitas Terdampak | Contoh Riil di Dataset | Tindakan Data Science (*Policy*) |
| :---: | :--- | :--- | :--- | :---: | :--- | :--- |
| **1** | **Pelanggan** | Super-Wholesaler (Paus) | Kontribusi Omzet $> 5\%$ total | 3 Pelanggan | `TOKO CITA RASA BARU` (Rp 547M), `ADEK FROZEN` (Rp 420M) | **Pertahankan & Segmentasi Khusus** (B2B Distributor) |
| **2** | **Pelanggan** | Shock Buyer (Pesanan Borongan) | $F \le 2$, $\text{AOV} > \text{Rp } 10\text{M}$ | 2 Pelanggan | `PAK SUTARMUJI` (2 trx, Rp 126,4M), `MAS ROHMAT` (Rp 45,7M) | **Tandai** sebagai pembeli spekulan / borongan |
| **3** | **Pelanggan** | Pelanggan Mikro / 1x Beli | $F = 1$, Omzet $< \text{Rp } 500\text{rb}$ | 32 Pelanggan | `MIAMI - WANDI` (Rp 125rb), `F - REHAN` (Rp 154rb) | **Masukkan ke Segmen Churned** |
| **4** | **Pelanggan** | Akun Anonim Walk-in | Label tag kasir `CASH` | 656 Baris (Rp 167M) | Keranjang pembeli tunai tanpa ID | **Keluarkan dari clustering pelanggan** (agar tidak bias) |
| **5** | **Pelanggan** | Pelanggan Non-Komersial | Total $\text{Monetary} = \text{Rp } 0$ | 2 Entitas | `SAMPLING MITRAKU`, `SAMPEL CRB` | **Keluarkan dari master pelanggan** |
| **6** | **Pelanggan** | Fragmentasi Ejaan / Kanal | Outlet punya $> 1$ bentuk nama | 46 Outlet | `ADEK FROZEN` vs `C - ADEK FROZEN` | **Satukan identitas** (*Entity Resolution*) |
| **7** | **Harga** | Harga Nol (Kasir Lupa Input) | $\text{HARGA} = 0$, $\text{QTY} \ge 10$ DUS, CASH | 20 Baris (Rp 90,7M) | Baris 860: Lutosa 106 DUS harga Rp 0 | **Imputasi Nilai Pasar Terdekat** (+Rp 90,7 Juta) |
| **8** | **Harga** | Harga Nol (Tester Promosi) | $\text{HARGA} = 0$, $\text{QTY} \le 3$, Mitra | 39 Baris | Baris 60 & 78: Mitraku tester 1 pack Rp 0 | **Keluarkan dari omzet komersial** |
| **9** | **Harga** | Deviasi Median SKU Sejenis | Deviasi $> 30\%$ dari median SKU | 7 Baris | `LUTOSA-001` Rp 15rb (Normal Rp 26rb) ke Fadil Anak Bos | **Tandai** sebagai transaksi diskon orang dalam / promo |
| **10** | **Harga** | Outlier Satuan Terendah | $X = \text{Satuan BKS}$ | 55 Baris | Cone es krim Rp 5.000 – Rp 7.000/bks | **Pertahankan** (karakteristik komoditas es krim) |
| **11** | **Harga** | Diskon Ekstrem Aritmetika | Rasio $\le 0.50$ dari nominal | 4 Baris | Baris 2325, 2334, 4559, 4560: Diskon 50% Pak Erwin | **Tandai** sebagai promo *clearance* pabrik |
| **12** | **Transaksi** | Nilai Moneter Ekstrem | $\text{JUMLAH} > \text{Rp } 54,9\text{ Juta}$ | 2 Baris | Baris 4566 & 4937: Masing-masing Rp 63,2 Juta | **Pertahankan** (transaksi grosir sah tervalidasi) |
| **13** | **Transaksi** | Kuantitas Ekstrem | $z_{\text{robust}} > 8$ per SKU | 237 Baris | Baris 5083: 400 Pack Bakso Mie ke Anton | **Pertahankan** (pesanan pasokan restoran) |
| **14** | **Transaksi** | Duplikasi Persis | Identik 100% semua kolom | 73 Salinan Berlebih | Baris 530 vs 531, Baris 658 vs 689 (Miami 8L) | **Tandai / Hapus Salinan** bila menganalisis frekuensi struk |
| **15** | **Transaksi** | Pelanggaran Operasional | Transaksi pada Hari Minggu | 1 Baris | Baris 5546: Minggu 30 Ags 2020 (Pak Pepi Rp 180rb) | **Tandai** transaksi darurat luar jam kerja |
| **16** | **Transaksi** | Hari Lonjakan Omzet | Omzet Harian $> 5\times$ Median | 4 Hari | 26 Juni, 29 Juli, 18 Ags, 03 Ags (s/d Rp 188 Juta) | **Korelasikan** dengan restock bulanan distributor |

---
**Kesimpulan Akhir**:
Outlier dalam dataset penjualan *frozen food* ini bukanlah sekadar "kesalahan data yang harus dihapus secara membabi-buta", melainkan memuat sinyal bisnis yang sangat kaya:
1. Sebagian outlier adalah **anomali integritas data** (kasir lupa input harga, duplikasi sistem, polusi kanal) yang harus **dibersihkan dan diperbaiki**.
2. Sebagian besar lainnya adalah **perilaku bisnis riil** (*Super-wholesaler*, pesanan borongan restoran, diskon orang dalam, promo *clearance*) yang justru menjadi landasan penting dalam perancangan strategi pemasaran, segmentasi LRFM, dan penataan katalog produk.
''')

# Simpan ke notebook file
OUTPUT_PATH = '06_deteksi_outlier_multidimensi.ipynb'
with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1, ensure_ascii=False)

print(f"File notebook berhasil dibuat: '{OUTPUT_PATH}' ({len(notebook['cells'])} sel).")

# Salin juga ke folder notebook/
os.makedirs('notebook', exist_ok=True)
import shutil
shutil.copyfile(OUTPUT_PATH, os.path.join('notebook', OUTPUT_PATH))
print(f"Salinan notebook berhasil disimpan ke 'notebook/{OUTPUT_PATH}'.")

