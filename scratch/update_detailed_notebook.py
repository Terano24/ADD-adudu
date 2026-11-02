import json
import os
import shutil

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
# CELL 0: TITLE & EXECUTIVE SUMMARY
# ==============================================================================
add_md(r'''# Analisis Deteksi Outlier Multi-Dimensi (Dataset Frozen Food)
### Mata Kuliah: Analisis Data Diskrit (ADD) — Institut Teknologi Sepuluh Nopember (ITS)
**Dataset Sumber:** `Data Penjualan April - Sep 2020.xlsx` (Data Penjualan Mentah Pertama Kali Diberikan, $N = 6.779$ baris)

---

## 📌 Latar Belakang & Instruksi Tugas
Berdasarkan arahan eksplorasi data transaksi penjualan *frozen food*:
1. **Bukalah data frozen food yang pertama kali diberikan** (`Data Penjualan April - Sep 2020.xlsx`).
2. **Lakukan outlier detection pada data tersebut dalam beberapa sisi/dimensi**:
   - **Temukan pelanggan yang outlier** (definisi *abnormality* ditentukan oleh diskusi kelompok).
   - **Temukan harga barang yang outlier** (terlalu murah atau terlalu mahal bila dilihat dari dimensi $X$).
   - **Temukan transaksi yang outlier** (definisi *abnormality* ditentukan oleh diskusi kelompok).

---

## 🏛️ Kerangka Teori: Tiga Definisi *Abnormality* General (Payung Konseptual)

Agar deteksi outlier tidak terfragmentasi menjadi aturan-aturan parsial yang terpisah, kelompok kami merumuskan **tiga definisi abnormality general (payung konseptual)** yang secara komprehensif mencakup dan memayungi seluruh manifestasi pencilan di setiap dimensi:

```
                                  TIGA DEFINISI ABNORMALITY GENERAL
                                                  │
         ┌────────────────────────────────────────┼────────────────────────────────────────┐
         ▼                                        ▼                                        ▼
┌─────────────────────────────────┐      ┌─────────────────────────────────┐      ┌─────────────────────────────────┐
│     1. GENERAL PELANGGAN        │      │       2. GENERAL HARGA          │      │     3. GENERAL TRANSAKSI        │
├─────────────────────────────────┤      ├─────────────────────────────────┤      ├─────────────────────────────────┤
│ Kegagalan representasi profil   │      │ Deviasi harga unit/efektif dari │      │ Pelanggaran proses bisnis &     │
│ belanja individu wajar pada     │      │ nilai ekspektasi pasar terhadap │      │ integritas sistem POS: guncangan│
│ manifold perilaku LRFM atau     │      │ basis pembanding X: distorsi    │      │ skala agregat, anomali waktu    │
│ cacat integritas identitas toko.│      │ nilai, disparitas, diskriminasi.│      │ operasional, & salah kalkulasi. │
└─────────────────────────────────┘      └─────────────────────────────────┘      └─────────────────────────────────┘
```
''')

# ==============================================================================
# CELL 1: SETUP & IMPORTS
# ==============================================================================
add_code(r'''import os
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

# Konfigurasi Tampilan Pandas
pd.set_option('display.max_columns', 35)
pd.set_option('display.max_colwidth', None)
pd.set_option('display.width', 1000)
pd.set_option('display.float_format', lambda v: f'{v:,.2f}')

# Konfigurasi Visualisasi
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
print(f"File data mentah siap dianalisis: '{FILE_MENTAH}'")
''')

# ==============================================================================
# CELL 2: DATA LOADING
# ==============================================================================
add_md(r'''---
## 1. Pemuatan Data Mentah Pertama Kali Diberikan (`Data Penjualan April - Sep 2020.xlsx`)

Data mentah berformat `.xlsx` dibaca secara utuh tanpa modifikasi awal. Disediakan parser berbasis *Standard Library* (`zipfile` + `xml.etree`) sebagai *fallback* otomatis apabila modul `openpyxl` belum terpasang di kernel.
''')

add_code(r'''def baca_excel_frozen_food(path):
    """Membaca file Excel mentah dengan fallback xml/zipfile otomatis."""
    try:
        df = pd.read_excel(path, sheet_name='Sheet1')
        print("-> Sukses membaca via pd.read_excel.")
    except Exception as e:
        print(f"-> Menggunakan pembaca zip/xml bawaan python ({e})...")
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
    
    # Hapus baris yang seluruhnya kosong (seperti baris 6780 di Excel mentah)
    df = df.dropna(how='all').reset_index(drop=True)
    # Catat nomor baris asli Excel (header = baris 1, data baris 2 s/d 6779)
    df.insert(0, 'BARIS_ASLI', df.index + 2)
    
    # Konversi serial date Excel ke format string YYYY-MM-DD
    def format_tgl(v):
        if pd.isna(v): return None
        if isinstance(v, (datetime.datetime, pd.Timestamp)):
            return v.strftime('%Y-%m-%d')
        if isinstance(v, (int, float)):
            return (datetime.datetime(1899, 12, 30) + datetime.timedelta(days=float(v))).strftime('%Y-%m-%d')
        return str(v)[:10]

    df['TGL_STR'] = df['TGL'].apply(format_tgl)
    df['TGL_DT'] = pd.to_datetime(df['TGL_STR'], errors='coerce')
    
    # Konversi numerik
    for col in ['QTY', 'HARGA', 'JUMLAH']:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
            
    return df

df_mentah = baca_excel_frozen_food(FILE_MENTAH)
print(f"Data Mentah Dimuat: {df_mentah.shape[0]:,} baris data, {df_mentah.shape[1]} kolom.")
print(f"Periode Waktu     : {df_mentah['TGL_STR'].min()} s/d {df_mentah['TGL_STR'].max()}")
print(f"Total Omzet Mentah: Rp {df_mentah['JUMLAH'].sum():,.2f}")
df_mentah.head(5)
''')

# ==============================================================================
# CELL 3: DIMENSI 1 - PELANGGAN OUTLIER INTRO (GENERAL DEFINITION)
# ==============================================================================
add_md(r'''---
## 2. Dimensi 1: Outlier Detection pada Pelanggan (`PELANGGAN`)

### 🌟 Definisi *Abnormality* General untuk Pelanggan
Berdasarkan hasil diskusi kelompok, kami merumuskan satu **definisi payung (general)** yang berlaku untuk seluruh fenomena pencilan pelanggan:

> ### 📢 **Definisi *Abnormality* General Pelanggan:**
> **"Suatu entitas pelanggan diklasifikasikan sebagai *outlier/abnormal* apabila entitas tersebut mengalami kegagalan representasi profil belanja individu wajar (*violation of homogeneous individual customer behavior*), yang terjadi ketika entitas tersebut menyimpang secara ekstrem pada manifold ruang perilaku LRFM (Panjang relasi, Kebaruan, Frekuensi, Moneter/AOV) melampaui batas dispersi populasi ritel normal, ATAU mengalami cacat integritas identitas entitas (berupa agregasi anonimitas kolektif, ketiadaan nilai komersial/omzet nol, maupun fragmentasi penamaan struktural) yang menyebabkan entitas tersebut tidak dapat diperlakukan sebagai satu unit bisnis pembeli reguler tunggal yang valid."**

---

### 🔍 Pemetaan Manifestasi Outlier Pelanggan di Bawah Definisi General
Definisi general di atas memayungi dua pilar penyimpangan dengan 6 manifestasi konkret di dataset:

#### Pilar A: Penyimpangan Ekstrem pada Manifold Perilaku LRFM / Dispersi Populasi
1. **Manifestasi 1.1 — Super-Wholesaler (Paus Moneter Ekstrem):**  
   *Menyimpang pada dimensi Moneter ($M$)*. Omzet akumulatif menembus pagar luar Tukey ($Q_3 + 3 \times \text{IQR}$) atau menyumbang $> 5\%$ total toko.
   - *Fakta Data:* `TOKO CITA RASA BARU` (Rp 547,7M, $\sim 12\%$ perputaran toko) dan `ADEK FROZEN` (Rp 420,7M, $\sim 9.1\%$).
2. **Manifestasi 1.2 — Shock Buyer (Keranjang Raksasa Spontan / AOV Kolosal):**  
   *Menyimpang pada relasi Frekuensi-Moneter ($F$ vs $M$ / AOV)*. Kunjungan belanja sangat minim ($F \le 2$), namun rata-rata nilai transaksi per baris $> 50\times$ rata-rata normal toko ($\text{AOV} > \text{Rp } 10\text{M}$).
   - *Fakta Data:* `PAK SUTARMUJI` (hanya 2 transaksi, menghasilkan Rp 126,4M, AOV = Rp 63,2M/baris) dan `MAS ROHMAT` (1 transaksi borongan Rp 45,75M).
3. **Manifestasi 1.3 — Frekuensi Ekstrem (Hyper-Active vs One-Time Churned):**  
   *Menyimpang pada dimensi Frekuensi ($F$) dan Kebaruan ($R$)*. Menempati ujung ekstrem distribusi frekuensi: $F > 150$ baris transaksi dengan keaktifan $> 40$ hari kerja vs $F = 1$ baris lalu hilang selamanya.
   - *Fakta Data:* `PT. DINAMIKA BUAH N.` (190 baris di 46 hari kerja) vs 32 outlet terdaftar yang hanya belanja 1 kali sepanjang 6 bulan (misal `MIAMI - WANDI` Rp 125rb, `F - REHAN` Rp 154rb).

#### Pilar B: Cacat Integritas Identitas Entitas Pelanggan
4. **Manifestasi 1.4 — Agregasi Anonimitas Kolektif (`CASH` Walk-in Bucket):**  
   *Cacat identitas karena agregasi semu*. Label kasir tunggal yang sebenarnya menampung ratusan pembeli tunai tanpa ID member.
   - *Fakta Data:* 656 baris transaksi senilai Rp 167,4M. Mencampur belanja eceran 1 bungkus cone Rp 5rb dengan borongan grosir 106 dus kentang Rp 25,4M.
5. **Manifestasi 1.5 — Ketiadaan Nilai Komersial (Pelanggan Saldo Rp 0):**  
   *Cacat entitas karena tidak menghasilkan omzet*. Entitas promosi internal yang salah kamar dicatat sebagai akun pelanggan.
   - *Fakta Data:* `SAMPLING MITRAKU` (2 transaksi, Rp 0) dan `SAMPEL CRB` (10 transaksi, Rp 0).
6. **Manifestasi 1.6 — Fragmentasi Penamaan Struktural (Prefiks Kanal Ganda):**  
   *Cacat entitas akibat duplikasi penamaan*. Satu toko fisik terpecah menjadi beberapa profil berbeda akibat kode sales kasir (`C -`, `F -`, dll.).
   - *Fakta Data:* 46 outlet terpecah (misal `ADEK FROZEN` Rp 288M dan `C - ADEK FROZEN` Rp 132M). Menyebabkan jumlah pelanggan menggelembung semu dari 183 menjadi 229.
''')

# ==============================================================================
# CELL 4: CODE - AGREGASI PELANGGAN & DETAIL OUTLIER PELANGGAN
# ==============================================================================
add_code(r'''# Standardisasi nama pelanggan untuk membedakan entitas riil vs varian prefiks
def bersihkan_nama_pelanggan(nama):
    if pd.isna(nama) or str(nama).strip() == '':
        return 'TIDAK DIKETAHUI'
    s = str(nama).strip().upper()
    for prefix in ['C - ', 'F - ', 'E - ', 'I - ', 'MIAMI - ', 'M - ']:
        if s.startswith(prefix):
            s = s[len(prefix):].strip()
    s = s.replace('(MITRAKU)', '').strip()
    return ' '.join(s.split())

df_mentah['PELANGGAN_BERSIH'] = df_mentah['NAMA'].apply(bersihkan_nama_pelanggan)

# Agregasi metrik perilaku pelanggan
tgl_maks = df_mentah['TGL_DT'].max()
total_omzet_toko = df_mentah['JUMLAH'].sum()

agg_cust = df_mentah.groupby('PELANGGAN_BERSIH').agg(
    total_omzet=('JUMLAH', 'sum'),
    total_qty=('QTY', 'sum'),
    total_baris=('JUMLAH', 'count'),
    hari_aktif=('TGL_STR', 'nunique'),
    tgl_pertama=('TGL_DT', 'min'),
    tgl_terakhir=('TGL_DT', 'max'),
    varian_ejaan_mentah=('NAMA', lambda x: sorted(list(set(str(v).strip() for v in x))))
).reset_index()

agg_cust['AOV_per_baris'] = agg_cust['total_omzet'] / agg_cust['total_baris']
agg_cust['persen_omzet'] = (agg_cust['total_omzet'] / total_omzet_toko) * 100
agg_cust['recency_hari'] = (tgl_maks - agg_cust['tgl_terakhir']).dt.days

# Pagar Tukey untuk omzet pelanggan
q1_m = agg_cust['total_omzet'].quantile(0.25)
q3_m = agg_cust['total_omzet'].quantile(0.75)
iqr_m = q3_m - q1_m
pagar_luar_omzet = q3_m + 3.0 * iqr_m

print("=== STATISTIK SEBARAN PELANGGAN ===")
print(f"Median Omzet Pelanggan : Rp {agg_cust['total_omzet'].median():,.2f}")
print(f"Pagar Luar Tukey (Ekstrem): Rp {pagar_luar_omzet:,.2f}")
print(f"Rata-rata Baris Belanja: {agg_cust['total_baris'].mean():.1f} baris")
''')

# ==============================================================================
# CELL 5: CODE - TABEL FORMAL OUTLIER PELANGGAN BERDASARKAN DEFINISI GENERAL
# ==============================================================================
add_code(r'''DEFINISI_GENERAL_PELANGGAN = (
    "Kegagalan representasi profil belanja individu wajar (violation of homogeneous individual customer behavior): "
    "menyimpang ekstrem pada manifold LRFM melampaui dispersi populasi normal, atau mengalami cacat integritas identitas entitas."
)

daftar_outlier_pelanggan = []

# 1. Super-Wholesaler (Paus)
for _, r in agg_cust[agg_cust['total_omzet'] > pagar_luar_omzet].iterrows():
    if r['PELANGGAN_BERSIH'] == 'CASH': continue
    daftar_outlier_pelanggan.append({
        'KATEGORI_OUTLIER': '1.1 Super-Wholesaler (Paus)',
        'ENTITAS': r['PELANGGAN_BERSIH'],
        'NILAI_AKTUAL': f"Omzet: Rp {r['total_omzet']:,.0f} ({r['persen_omzet']:.2f}% toko)",
        'NILAI_ACUAN_NORMAL': f"Pagar Tukey: Rp {pagar_luar_omzet:,.0f} (Median: Rp {agg_cust['total_omzet'].median():,.0f})",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_PELANGGAN,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar A (Penyimpangan Manifold LRFM): Lonjakan ekstrem pada dimensi Moneter (M > Q3 + 3*IQR).',
        'PENJELASAN_KONKRET': f"Menyerap tonase masif ({r['persen_omzet']:.1f}% omzet toko, {r['total_baris']} transaksi). Merupakan sub-distributor regional, bukan ritel biasa."
    })

# 2. Shock Buyer
for _, r in agg_cust[(agg_cust['hari_aktif'] <= 2) & (agg_cust['AOV_per_baris'] > 10_000_000)].iterrows():
    daftar_outlier_pelanggan.append({
        'KATEGORI_OUTLIER': '1.2 Shock Buyer (AOV Kolosal)',
        'ENTITAS': r['PELANGGAN_BERSIH'],
        'NILAI_AKTUAL': f"AOV/baris: Rp {r['AOV_per_baris']:,.0f} (Hari Aktif: {r['hari_aktif']})",
        'NILAI_ACUAN_NORMAL': "AOV Normal Toko: Rp 670,000/baris (F wajar: 10-50x)",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_PELANGGAN,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar A (Penyimpangan Manifold LRFM): Anomali relasi F-M (Frekuensi minim F<=2, namun AOV > 50x rata-rata).',
        'PENJELASAN_KONKRET': f"Membeli kuantitas borongan masif tiba-tiba (Total Rp {r['total_omzet']:,.0f} dari {r['total_baris']} baris). Spekulan borongan, bukan pelanggan relasional."
    })

# 3. CASH Anonim
cash_r = agg_cust[agg_cust['PELANGGAN_BERSIH'] == 'CASH'].iloc[0]
daftar_outlier_pelanggan.append({
    'KATEGORI_OUTLIER': '1.4 Akun Anonim Kolektif',
    'ENTITAS': 'CASH (Walk-in Buyer)',
    'NILAI_AKTUAL': f"656 transaksi, Total Rp {cash_r['total_omzet']:,.0f}",
    'NILAI_ACUAN_NORMAL': '1 Pelanggan = 1 Entitas Toko/Individu Unik Riil',
    'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_PELANGGAN,
    'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar B (Cacat Integritas Identitas): Agregasi semu penampung seluruh pembeli tunai tanpa nomor member.',
    'ABNORMALITY_NYA_APA': 'Bukan 1 individu riil! Mencampur pembelian ritel Rp 5rb dengan borongan 106 dus kentang Rp 25,4M. Merusak clustering RFM jika diikutkan.'
})

# 4. Pelanggan Non-Komersial
for _, r in agg_cust[agg_cust['total_omzet'] == 0].iterrows():
    daftar_outlier_pelanggan.append({
        'KATEGORI_OUTLIER': '1.5 Non-Komersial (Sampel Rp 0)',
        'ENTITAS': r['PELANGGAN_BERSIH'],
        'NILAI_AKTUAL': f"Omzet: Rp 0 (Baris: {r['total_baris']}, QTY: {r['total_qty']:.0f})",
        'NILAI_ACUAN_NORMAL': 'Omzet Pelanggan Komersial > Rp 0',
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_PELANGGAN,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar B (Cacat Integritas Identitas): Ketiadaan nilai komersial (Monetary = Rp 0).',
        'PENJELASAN_KONKRET': 'Pos pencatatan barang tester/sampel promosi pabrik yang salah kamar masuk ke master pelanggan.'
    })

# 5. Fragmentasi Ejaan
fragmented = agg_cust[agg_cust['varian_ejaan_mentah'].apply(len) > 1].sort_values(by='total_omzet', ascending=False)
for _, r in fragmented.head(3).iterrows():
    daftar_outlier_pelanggan.append({
        'KATEGORI_OUTLIER': '1.6 Fragmentasi Ejaan / Kanal',
        'ENTITAS': r['PELANGGAN_BERSIH'],
        'NILAI_AKTUAL': f"{len(r['varian_ejaan_mentah'])} varian: {r['varian_ejaan_mentah']}",
        'NILAI_ACUAN_NORMAL': '1 Toko Fisik = 1 ID / String Nama Tunggal',
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_PELANGGAN,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar B (Cacat Integritas Identitas): Fragmentasi penamaan toko fisik akibat penambahan kode sales.',
        'PENJELASAN_KONKRET': f"Memecah riwayat belanja toko. Contoh: ADEK FROZEN terpecah Rp 288M dan C - ADEK FROZEN Rp 132M. Jumlah pelanggan menggelembung semu dari 183 jadi 229."
    })

df_outlier_cust_summary = pd.DataFrame(daftar_outlier_pelanggan)
print(f"Total Kasus Outlier Pelanggan Terdokumentasi: {len(df_outlier_cust_summary)}")
df_outlier_cust_summary[['KATEGORI_OUTLIER', 'ENTITAS', 'NILAI_AKTUAL', 'MANIFESTASI_DARI_DEFINISI_GENERAL', 'PENJELASAN_KONKRET']]
''')

# ==============================================================================
# CELL 6: VISUALISASI OUTLIER PELANGGAN
# ==============================================================================
add_code(r'''fig, axes = plt.subplots(1, 2, figsize=(15, 6))

# Plot 1: Scatter Frekuensi vs Omzet (Log-Log)
df_plot_cust = agg_cust[agg_cust['total_omzet'] > 0].copy()
sns.scatterplot(
    data=df_plot_cust,
    x='total_baris',
    y='total_omzet',
    alpha=0.6,
    color=C_PRIMARY,
    s=65,
    ax=axes[0]
)

# Highlight Pelanggan Outlier Utama
high_labels = ['TOKO CITA RASA BARU', 'ADEK FROZEN', 'ANTON', 'PAK SUTARMUJI', 'MAS ROHMAT', 'CASH']
for _, r in df_plot_cust[df_plot_cust['PELANGGAN_BERSIH'].isin(high_labels)].iterrows():
    axes[0].scatter(r['total_baris'], r['total_omzet'], color=C_ALERT, s=130, zorder=5)
    axes[0].annotate(
        r['PELANGGAN_BERSIH'],
        (r['total_baris'], r['total_omzet']),
        textcoords="offset points",
        xytext=(6, 5),
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

# Plot 2: Pareto Top 10 Pelanggan
top10_c = agg_cust.sort_values(by='total_omzet', ascending=True).tail(10)
bars = axes[1].barh(top10_c['PELANGGAN_BERSIH'], top10_c['total_omzet'] / 1e6, color='#2b5c8f')
axes[1].set_title('Top 10 Pelanggan dengan Akumulasi Omzet Tertinggi (Juta Rp)', fontweight='bold')
axes[1].set_xlabel('Total Omzet (Juta Rupiah)')

for bar in bars:
    w = bar.get_width()
    axes[1].text(w + 4, bar.get_y() + bar.get_height()/2, f'Rp {w:,.1f}M', va='center', fontsize=8.5)

axes[1].set_xlim(0, top10_c['total_omzet'].max() / 1e6 * 1.15)
plt.tight_layout()
plt.show()
''')

# ==============================================================================
# CELL 7: DIMENSI 2 - HARGA BARANG OUTLIER INTRO (GENERAL DEFINITION)
# ==============================================================================
add_md(r'''---
## 3. Dimensi 2: Outlier Detection pada Harga Barang (`HARGA`) Dilihat dari Dimensi $X$

### 🌟 Definisi *Abnormality* General untuk Harga Barang (Dilihat dari $X$)
Instruksi tugas menyatakan: *"Temukan harga barang yang outlier (terlalu murah atau terlalu mahal bila dilihat dari X)"*. Kelompok kami merumuskan satu **definisi payung (general)** berbasis ekspektasi bersyarat terhadap variabel jangkar $X$:

> ### 📢 **Definisi *Abnormality* General Harga Barang (Dilihat dari $X$):**
> **"Suatu harga barang diklasifikasikan sebagai *outlier/abnormal* apabila nilai nominal harga per unit atau harga efektif realisasinya menyimpang secara signifikan dari nilai ekuilibrium pasar yang diharapkan terhadap suatu titik acuan atau basis pembanding $X$ ($\text{Expected Value } E[\text{Price} \mid X]$), baik akibat distorsi pencatatan/omisi nilai ($\text{HARGA} = 0$), disparitas kemasan dan kelas komoditas fisik, maupun diskriminasi harga non-standar (diskon kekeluargaan, perlakuan khusus pihak tertentu, atau promo separuh harga ekstrem) yang melanggar batas kewajaran struktur penetapan harga katalog."**

---

### 🔍 Pemetaan Manifestasi Outlier Harga di Bawah Definisi General
Di bawah definisi general ini, variabel jangkar $X$ dioperasionalkan menjadi **5 sudut pandang pembanding**:

1. **Sudut Pandang $X_1$: $X = \text{Eksistensi Nilai Dasar Komersial ($X > 0$ vs $X = 0$)} \rightarrow$ Distorsi Nilai Nol**
   - *Manifestasi:* Komoditas komersial wajib bernilai $E[\text{Price} \mid \text{Komersial}] > 0$. Ditemukan 59 baris berharga Rp 0 yang terbelah menjadi:
     * **Missing Price (Kasir Lupa Input — 20 baris):** Transaksi tunai borongan `CASH` volume besar (hingga 106 DUS kentang beku di baris 860). Kasir lupa menginput harga sehingga omzet toko lenyap Rp 90.720.700.
     * **Tester Promosi (39 baris):** Barang tester kuantitas kecil 1-2 pack ke toko mitra untuk promosi pabrik, sah bernilai Rp 0.
2. **Sudut Pandang $X_2$: $X = \text{Median Harga SKU Sejenis pada Satuan Sama} \rightarrow$ Diskriminasi & Markup**
   - *Manifestasi:* Harga transaksi menyimpang $> 30\%$ dari $E[\text{Price} \mid \text{SKU}, \text{Satuan}]$:
     * **Terlalu Murah (Fadil Anak Bos):** `LUTOSA SHOESTRING 1000 GR` (Baris 1030, 2215, 2826) dijual **Rp 15.000/pack** (median normal Rp 26.000, menyimpang **$-42.3\%$ lebih murah**) akibat perlakuan harga istimewa anak pemilik (*insider pricing*).
     * **Terlalu Mahal (Markup Ritel/Kafe):** `SHIFUDO FISH ROLL 250 GR` (Baris 6165) dijual **Rp 262.500/dus** (median Rp 201.020, menyimpang **$+30.6\%$ lebih mahal**); `AVIKO SHOESTRING` (Baris 98) dijual **Rp 270.000/dus** ke Indah Cafe (median Rp 210.000, menyimpang **$+28.6\%$ lebih mahal**).
3. **Sudut Pandang $X_3$: $X = \text{Satuan Kemasan Fisik} \rightarrow$ Disparitas Grosir vs Eceran**
   - *Manifestasi:* Ditinjau dari hierarki karton grosir vs eceran pack serta batas kemasan fisik ekstrem:
     * Rasio normal DUS : PACK berkisar $4\times - 40\times$ sesuai kapasitas pack per dus (misal Jofrans Nugget 225g isi 24 pack: 1 Dus Rp 240rb, 1 Pack Rp 10rb $\rightarrow$ rasio $24.0\times$).
     * *Kemasan Khusus:* `BKS` (Cone es krim Rp 5rb–Rp 7rb, batas bawah harga toko), `PAIL` (Miami 8L Rp 125rb, volume besar harga ekonomis $\sim\text{Rp } 15.600/\text{liter}$), `JRG` (Delmonte 5.7kg Rp 105rb, bulk horeka $\sim\text{Rp } 18.400/\text{kg}$).
4. **Sudut Pandang $X_4$: $X = \text{Tingkat Komoditas Bahan Baku} \rightarrow$ Hierarki Kelas Produk**
   - *Manifestasi:* Daging sapi impor premium menduduki batas atas katalog (Bratwurst Besto Rp 760.000/dus, Burger Sapi Jofrans Rp 576.000/dus), sedangkan produk singkong/cireng menduduki batas bawah (Singkong Keju Rp 8.750/pack, Cireng Bonju Rp 17.500/pack).
5. **Sudut Pandang $X_5$: $X = \text{Nilai Aritmetika Normal} \rightarrow$ Diskon Separuh Harga Ekstrem**
   - *Manifestasi:* Rasio realisasi transaksi $\text{JUMLAH} / (\text{QTY} \times \text{HARGA}) < 0.80$.
   - *Fakta Data:* Tepat **4 baris transaksi** yang semuanya jatuh pada **`PAK ERWIN`** (Baris 2325, 2334, 4559, 4560), di mana harga dipotong tepat **50.0% (Diskon Separuh Harga)** untuk produk Mitraku Fish Cake dan Scallop. Merupakan program promo *Buy 1 Get 1* / *Clearance Sale* prinsipal.
''')

# ==============================================================================
# CELL 8: CODE - HARGA MEDIAN & TABEL FORMAL OUTLIER HARGA
# ==============================================================================
add_code(r'''# Hitung Median Harga per SKU dan Satuan
sku_sat_valid = df_mentah[df_mentah['HARGA'] > 0].copy()
med_sku_sat = sku_sat_valid.groupby(['KODEBARA', 'SATUAN'])['HARGA'].agg(
    median_harga='median',
    mean_harga='mean',
    std_harga='std',
    count_trx='count'
).reset_index()

df_h = df_mentah.merge(med_sku_sat, on=['KODEBARA', 'SATUAN'], how='left')
df_h['deviasi_persen'] = ((df_h['HARGA'] - df_h['median_harga']) / df_h['median_harga']) * 100
df_h['nominal_kotor'] = df_h['QTY'] * df_h['HARGA']
df_h['rasio_diskon'] = np.where(df_h['nominal_kotor'] > 0, df_h['JUMLAH'] / df_h['nominal_kotor'], 1.0)

DEFINISI_GENERAL_HARGA = (
    "Penyimpangan signifikan nilai nominal atau harga efektif realisasi dari nilai ekuilibrium pasar yang diharapkan terhadap basis pembanding X: "
    "E[Price | X], baik akibat distorsi pencatatan/omisi nilai (HARGA = 0), disparitas kemasan dan kelas komoditas fisik, maupun diskriminasi harga non-standar."
)

daftar_outlier_harga = []

# X1: Harga Nol (Missing Price vs Tester)
zero_cash_rows = df_h[(df_h['HARGA'] == 0) & (df_h['PELANGGAN_BERSIH'] == 'CASH')]
for _, r in zero_cash_rows.head(2).iterrows():
    daftar_outlier_harga.append({
        'SUDUT_PANDANG_X': 'X1: Eksistensi Nilai (X > 0 vs X = 0)',
        'KASUS': 'Missing Price (Kasir Lupa Input)',
        'BARIS_SKU': f"Baris {r['BARIS_ASLI']}: {r['NAMABARA']}",
        'NILAI_AKTUAL': f"HARGA = Rp 0 (QTY: {r['QTY']} {r['SATUAN']})",
        'NILAI_ACUAN_NORMAL': f"E[Price | SKU] = Rp {r['median_harga']:,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_HARGA,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Distorsi pencatatan / omisi nilai: Transaksi komersial bernilai riil keluar dengan nominal HARGA = 0.',
        'PENJELASAN_KONKRET': f"Kelalaian kasir lupa menginput harga pesanan tunai cepat (omzet hilang Rp 90,7M dari 20 baris). Contoh baris {r['BARIS_ASLI']} QTY {r['QTY']:.0f} {r['SATUAN']} senilai puluhan juta."
    })

zero_promo_rows = df_h[(df_h['HARGA'] == 0) & (df_h['PELANGGAN_BERSIH'] != 'CASH')]
for _, r in zero_promo_rows.head(1).iterrows():
    daftar_outlier_harga.append({
        'SUDUT_PANDANG_X': 'X1: Eksistensi Nilai (X > 0 vs X = 0)',
        'KASUS': 'Tester Promosi Murni',
        'BARIS_SKU': f"Baris {r['BARIS_ASLI']}: {r['NAMABARA']}",
        'NILAI_AKTUAL': f"HARGA = Rp 0 (QTY: {r['QTY']} {r['SATUAN']})",
        'NILAI_ACUAN_NORMAL': f"E[Price | SKU] = Rp {r['median_harga']:,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_HARGA,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Distorsi pencatatan: Barang promosi pabrik bernilai komersial nol menyusup ke tabel penjualan.',
        'PENJELASAN_KONKRET': f"Sampel promosi gratis kuantitas 1 pack untuk pengenalan varian baru ke toko {r['NAMA']}. Sah bernilai Rp 0."
    })

# X2: Deviasi dari Median SKU Sejenis (Fadil Anak Bos & Markup)
fadil_rows = df_h[df_h['NAMA'].str.contains('FADIL ANAK BOS', na=False, case=False)]
for _, r in fadil_rows.head(2).iterrows():
    daftar_outlier_harga.append({
        'SUDUT_PANDANG_X': 'X2: Median SKU Sejenis',
        'KASUS': 'Terlalu Murah (Fadil Anak Bos)',
        'BARIS_SKU': f"Baris {r['BARIS_ASLI']}: {r['NAMABARA']}",
        'NILAI_AKTUAL': f"Rp {r['HARGA']:,.0f} (Deviasi: {r['deviasi_persen']:.1f}%)",
        'NILAI_ACUAN_NORMAL': f"E[Price | SKU, Satuan] = Rp {r['median_harga']:,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_HARGA,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Diskriminasi harga non-standar: Penyimpangan negatif ekstrem (>30% lebih murah) dari ekuilibrium pasar.',
        'PENJELASAN_KONKRET': f"Perlakuan diskon kekeluargaan / orang dalam ke pembeli '{r['NAMA']}'. Dijual Rp 15rb padahal pasar Rp 26rb (42.3% lebih murah)."
    })

markup_rows = df_h[df_h['deviasi_persen'] > 25].sort_values(by='deviasi_persen', ascending=False)
for _, r in markup_rows.head(2).iterrows():
    daftar_outlier_harga.append({
        'SUDUT_PANDANG_X': 'X2: Median SKU Sejenis',
        'KASUS': 'Terlalu Mahal (Markup Ritel/Kafe)',
        'BARIS_SKU': f"Baris {r['BARIS_ASLI']}: {r['NAMABARA']}",
        'NILAI_AKTUAL': f"Rp {r['HARGA']:,.0f} (Deviasi: +{r['deviasi_persen']:.1f}%)",
        'NILAI_ACUAN_NORMAL': f"E[Price | SKU, Satuan] = Rp {r['median_harga']:,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_HARGA,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Diskriminasi harga non-standar: Penyimpangan positif ekstrem (>25% lebih mahal) dari ekuilibrium pasar.',
        'PENJELASAN_KONKRET': f"Harga markup ritel/kafe ke pelanggan {r['NAMA']}. Lebih mahal {r['deviasi_persen']:.1f}% dari harga standar gudang."
    })

# X5: Diskon Ekstrem 50%
erwin_rows = df_h[df_h['rasio_diskon'] < 0.80]
for _, r in erwin_rows.head(2).iterrows():
    daftar_outlier_harga.append({
        'SUDUT_PANDANG_X': 'X5: Nilai Aritmetika Normal',
        'KASUS': 'Diskon Ekstrem Separuh Harga (50%)',
        'BARIS_SKU': f"Baris {r['BARIS_ASLI']}: {r['NAMABARA']}",
        'NILAI_AKTUAL': f"Ditagih Rp {r['JUMLAH']:,.0f} (Diskon {(1-r['rasio_diskon'])*100:.1f}%)",
        'NILAI_ACUAN_NORMAL': f"E[Nilai | QTY*HARGA] = Rp {r['nominal_kotor']:,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_HARGA,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Diskriminasi promo non-standar: Potongan harga melebihi batas toleransi wajar 20% (rasio diskon < 0.80).',
        'PENJELASAN_KONKRET': f"Diskon tepat 50.0% khusus pelanggan PAK ERWIN. Merupakan kesepakatan promo clearance pabrik / Buy 1 Get 1 Free."
    })

df_outlier_harga_summary = pd.DataFrame(daftar_outlier_harga)
print(f"Total Kasus Outlier Harga Terdokumentasi: {len(df_outlier_harga_summary)}")
df_outlier_harga_summary[['SUDUT_PANDANG_X', 'KASUS', 'BARIS_SKU', 'NILAI_AKTUAL', 'MANIFESTASI_DARI_DEFINISI_GENERAL', 'PENJELASAN_KONKRET']]
''')

# ==============================================================================
# CELL 9: VISUALISASI OUTLIER HARGA
# ==============================================================================
add_code(r'''fig, axes = plt.subplots(1, 2, figsize=(15, 5.5))

# Plot 1: Sebaran Deviasi Persentase Harga terhadap Median SKU
dev_valid = df_h[df_h['HARGA'] > 0]['deviasi_persen'].dropna()
sns.histplot(dev_valid, bins=50, kde=True, color=C_PRIMARY, ax=axes[0])
axes[0].axvline(-30, color=C_ALERT, linestyle='--', linewidth=1.5, label='Batas Terlalu Murah (-30%)')
axes[0].axvline(30, color=C_ALERT, linestyle='--', linewidth=1.5, label='Batas Terlalu Mahal (+30%)')
axes[0].set_title('Distribusi Deviasi Harga terhadap Median SKU (%)', fontweight='bold')
axes[0].set_xlabel('Deviasi dari Median (%)')
axes[0].set_ylabel('Jumlah Transaksi')
axes[0].legend()
axes[0].set_xlim(-60, 60)

# Plot 2: Boxplot Perbandingan Harga DUS vs PACK
produk_dua_sat = ['MIN-001', 'JOF-002', 'OKEY-001', 'LUTOSA-002', 'MIT-010']
sample_box = df_h[(df_h['KODEBARA'].isin(produk_dua_sat)) & (df_h['SATUAN'].isin(['DUS', 'PACK'])) & (df_h['HARGA'] > 0)]

sns.boxplot(
    data=sample_box,
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
# CELL 10: DIMENSI 3 - TRANSAKSI OUTLIER INTRO (GENERAL DEFINITION)
# ==============================================================================
add_md(r'''---
## 4. Dimensi 3: Outlier Detection pada Transaksi (`TRANSAKSI`)

### 🌟 Definisi *Abnormality* General untuk Transaksi
Pada tingkat rekaman baris transaksi nota/struk kasir, kelompok kami merumuskan satu **definisi payung (general)** berbasis integritas proses bisnis penjualan:

> ### 📢 **Definisi *Abnormality* General Transaksi:**
> **"Suatu rekaman transaksi (baris nota kasir) diklasifikasikan sebagai *outlier/abnormal* apabila atribut internal transaksi tersebut (nilai rupiah, kuantitas volume, waktu kejadian, konsistensi aritmetika, atau keunikan rekaman) melanggar asumsi dasar operasional proses bisnis penjualan (*business process & data integrity violation*), baik berupa deviasi skala ekstrem yang memicu guncangan pada distribusi agregat toko, pelanggaran jadwal operasional resmi, maupun redundansi dan inkonsistensi kalkulasi akibat kegagalan mekanisme kontrol sistem POS."**

---

### 🔍 Pemetaan Manifestasi Outlier Transaksi di Bawah Definisi General
Definisi general transaksi di atas memayungi tiga pilar pelanggaran integritas dengan 5 manifestasi konkret di dataset:

#### Pilar A: Pelanggaran Skala Besaran Operasional (Guncangan Distribusi Toko)
1. **Manifestasi 3.1 — Nilai Transaksi Rupiah Ekstrem (`JUMLAH` Ekstrem):**  
   *Menyimpang pada skala moneter transaksi*. Melampaui pagar luar logaritmik Tukey ($> \text{Rp } 54.907.061$). Bernilai setara 50x hingga 95x rata-rata transaksi toko.
   - *Fakta Data:* Baris 4566 & 4937 (Pak Sutarmuji, masing-masing Rp 63.200.000 untuk 200 Dus Minaku Otak-Otak) dan Baris 4565 (Mas Rohmat, Rp 45.750.000).
2. **Manifestasi 3.2 — Kuantitas Pemesanan Ekstrem (`QTY` Outlier, $z_{\text{robust}} > 8$):**  
   *Menyimpang pada volume fisik barang*. Jumlah unit fisik dalam 1 baris menyimpang jauh dari kebiasaan normal SKU.
   - *Fakta Data:* Sebanyak 237 baris transaksi: Baris 5083 (400 PACK Bakso Mie ke Anton), Baris 2949 (240 PACK Bakso Ikan ke Putri), Baris 1681 (200 PACK Tortila ke Rumah Sosis).

#### Pilar B: Pelanggaran Jadwal Operasional Resmi (Temporal)
3. **Manifestasi 3.3 — Anomali Hari Operasional Tutup (Transaksi Hari Minggu):**  
   *Melanggar siklus kerja tetap toko*. Transaksi tercatat pada hari libur resmi di mana seluruh toko tutup.
   - *Fakta Data:* Baris 5546 pada Minggu 30 Agustus 2020 (Pak Pepi Rp 180rb). Sebanyak 25 dari 26 hari Minggu terbukti 100% tutup tanpa transaksi. Merupakan pengambilan stok darurat atau nota susulan.
4. **Manifestasi 3.4 — Hari Lonjakan Omzet Harian Ekstrem (*Spike Days*):**  
   *Guncangan agregat harian*. Akumulasi omzet satu hari melonjak di atas $5\times$ median harian normal ($z_{\text{robust}} > 5$).
   - *Fakta Data:* 4 hari spike: 26 Juni, 29 Juli, 18 Agustus, dan 3 Agustus (omzet melonjak s/d Rp 188 Juta/hari akibat restock serentak distributor awal bulan).

#### Pilar C: Kegagalan Mekanisme Kontrol & Konsistensi Sistem POS
5. **Manifestasi 3.5 — Duplikasi Transaksi Persis (*Exact Duplicates*):**  
   *Kegagalan integritas entitas nota*. Baris transaksi identik 100% pada semua kolom tanpa adanya *primary key* unik (nomor struk).
   - *Fakta Data:* 143 baris transaksi terlibat (73 salinan berlebih). Terjadi akibat kasir menekan tombol kirim dua kali saat sistem *lag*.
6. **Manifestasi 3.6 — Diskrepansi Aritmetika (`JUMLAH} \neq \text{QTY} \times \text{HARGA}`):**  
   *Kegagalan kalkulasi perkalian otomatis*. Sebanyak 77 baris memiliki nilai total tidak sesuai hasil kali kuantitas dan harga (73 diskon volume wajar dan 4 diskon separuh harga 50% ke Pak Erwin).
''')

# ==============================================================================
# CELL 11: CODE - DETEKSI TRANSAKSI OUTLIER & TABEL FORMAL
# ==============================================================================
add_code(r'''# Deteksi Nilai Transaksi Rupiah Ekstrem
log_j = np.log10(df_mentah[df_mentah['JUMLAH'] > 0]['JUMLAH'])
pagar_atas_trx_j = 10 ** (log_j.quantile(0.75) + 3.0 * (log_j.quantile(0.75) - log_j.quantile(0.25)))

# Deteksi Kuantitas Ekstrem
def hitung_z_robust(s):
    med = s.median()
    mad = (s - med).abs().median()
    return pd.Series(0, index=s.index) if mad == 0 else 0.6745 * (s - med) / mad

df_mentah['z_qty_sku'] = df_mentah.groupby('KODEBARA')['QTY'].transform(hitung_z_robust)

# Deteksi Duplikasi
KOLOM_ID = ['TGL', 'KODEBARA', 'QTY', 'SATUAN', 'HARGA', 'JUMLAH', 'NAMA']
duplikat_masker = df_mentah.duplicated(subset=KOLOM_ID, keep=False)

# Deteksi Temporal Hari Minggu
df_mentah['HARI_NAMA'] = df_mentah['TGL_DT'].dt.day_name()
trx_minggu = df_mentah[df_mentah['HARI_NAMA'] == 'Sunday']

# Deteksi Hari Lonjakan Omzet Harian
omzet_h = df_mentah.groupby('TGL_STR')['JUMLAH'].sum().reset_index()
omzet_h['z_omzet_h'] = hitung_z_robust(omzet_h['JUMLAH'])
hari_lonjakan = omzet_h[omzet_h['z_omzet_h'] > 5]

DEFINISI_GENERAL_TRANSAKSI = (
    "Pelanggaran asumsi dasar operasional proses bisnis penjualan (business process & data integrity violation): "
    "atribut internal transaksi melanggar distribusi umum (skala ekstrem yang memicu guncangan), melanggar jadwal operasional resmi, "
    "maupun redundansi dan inkonsistensi kalkulasi akibat kegagalan kontrol sistem POS."
)

daftar_outlier_transaksi = []

# 1. Nilai Rupiah Ekstrem
for _, r in df_mentah[df_mentah['JUMLAH'] > pagar_atas_trx_j].iterrows():
    daftar_outlier_transaksi.append({
        'KATEGORI_OUTLIER': '3.1 Nilai Rupiah Ekstrem',
        'ID_TRANSAKSI': f"Baris {r['BARIS_ASLI']} ({r['TGL_STR']})",
        'ENTITAS_BARANG': f"{r['NAMA']} — {r['NAMABARA']}",
        'NILAI_AKTUAL': f"JUMLAH: Rp {r['JUMLAH']:,.0f} (QTY: {r['QTY']} {r['SATUAN']})",
        'NILAI_ACUAN_NORMAL': f"Pagar Log: Rp {pagar_atas_trx_j:,.0f} (Rata-rata: Rp 670rb)",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_TRANSAKSI,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar A (Pelanggaran Skala): Nilai rupiah melampaui pagar luar logaritmik Tukey, bernilai 95x lipat rata-rata.',
        'PENJELASAN_KONKRET': f"Pesanan grosir kolosal dalam 1 transaksi (Pembelian 200 dus Minaku Otak-Otak sekaligus). Transaksi sah tervalidasi."
    })

# 2. Kuantitas Ekstrem
for _, r in df_mentah[df_mentah['z_qty_sku'] > 15].sort_values(by='QTY', ascending=False).head(3).iterrows():
    daftar_outlier_transaksi.append({
        'KATEGORI_OUTLIER': '3.2 Kuantitas Ekstrem',
        'ID_TRANSAKSI': f"Baris {r['BARIS_ASLI']} ({r['TGL_STR']})",
        'ENTITAS_BARANG': f"{r['NAMA']} — {r['NAMABARA']}",
        'NILAI_AKTUAL': f"QTY: {r['QTY']:,.0f} {r['SATUAN']} (z_robust: {r['z_qty_sku']:.1f})",
        'NILAI_ACUAN_NORMAL': "Normal per transaksi: 1 - 5 pack/dus",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_TRANSAKSI,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar A (Pelanggaran Skala): Kuantitas fisik pemesanan menyimpang ekstrem (z_robust > 8) dari distribusi SKU.',
        'PENJELASAN_KONKRET': f"Pesanan borongan pasokan restoran cepat saji / pedagang bakso. QTY {r['QTY']:.0f} {r['SATUAN']} jauh di atas batas normal."
    })

# 3. Duplikasi Persis
duplikat_sampel = df_mentah[duplikat_masker].head(2)
for _, r in duplikat_sampel.iterrows():
    daftar_outlier_transaksi.append({
        'KATEGORI_OUTLIER': '3.3 Duplikasi Persis',
        'ID_TRANSAKSI': f"Baris {r['BARIS_ASLI']} ({r['TGL_STR']})",
        'ENTITAS_BARANG': f"{r['NAMA']} — {r['NAMABARA']}",
        'NILAI_AKTUAL': f"QTY: {r['QTY']} {r['SATUAN']}, Total: Rp {r['JUMLAH']:,.0f}",
        'NILAI_ACUAN_NORMAL': '1 Struk / Transaksi Fisik = 1 Baris Tunggal di Database',
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_TRANSAKSI,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar C (Kegagalan Kontrol Sistem POS): Redundansi rekaman identik 100% tanpa primary key struk unik.',
        'PENJELASAN_KONKRET': 'Kasir menekan tombol kirim ganda saat sistem POS lag. Terdapat 73 salinan redundan yang mendistorsi frekuensi struk.'
    })

# 4. Transaksi Hari Minggu
for _, r in trx_minggu.iterrows():
    daftar_outlier_transaksi.append({
        'KATEGORI_OUTLIER': '3.4 Anomali Temporal Hari Minggu',
        'ID_TRANSAKSI': f"Baris {r['BARIS_ASLI']} ({r['TGL_STR']})",
        'ENTITAS_BARANG': f"{r['NAMA']} — {r['NAMABARA']}",
        'NILAI_AKTUAL': f"Hari: {r['HARI_NAMA']}, Total: Rp {r['JUMLAH']:,.0f}",
        'NILAI_ACUAN_NORMAL': '25 dari 26 Hari Minggu TUTUP (0 transaksi)',
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_TRANSAKSI,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar B (Pelanggaran Jadwal Operasional): Transaksi terjadi di luar siklus jam buka resmi toko/gudang.',
        'PENJELASAN_KONKRET': 'Pengambilan stok darurat oleh pelanggan luar jam operasional atau nota susulan yang diinput di hari Minggu.'
    })

# 5. Hari Lonjakan Omzet
for _, r in hari_lonjakan.head(2).iterrows():
    daftar_outlier_transaksi.append({
        'KATEGORI_OUTLIER': '3.5 Hari Lonjakan Omzet Harian',
        'ID_TRANSAKSI': f"Tanggal {r['TGL_STR']}",
        'ENTITAS_BARANG': f"Seluruh Toko pada {r['TGL_STR']}",
        'NILAI_AKTUAL': f"Omzet Hari: Rp {r['JUMLAH']:,.0f} (z_robust: {r['z_omzet_h']:.1f})",
        'NILAI_ACUAN_NORMAL': f"Median Omzet Harian: Rp {omzet_h['JUMLAH'].median():,.0f}",
        'DEFINISI_GENERAL_PAYUNG': DEFINISI_GENERAL_TRANSAKSI,
        'MANIFESTASI_DARI_DEFINISI_GENERAL': 'Pilar B (Pelanggaran Pola Waktu): Guncangan akumulasi omzet harian melonjak > 5x lipat dari hari normal.',
        'PENJELASAN_KONKRET': f"Omzet harian mencapai {r['JUMLAH']/omzet_h['JUMLAH'].median():.1f}x lipat dari hari biasa akibat restock serentak distributor awal bulan."
    })

df_outlier_trx_summary = pd.DataFrame(daftar_outlier_transaksi)
print(f"Total Kasus Outlier Transaksi Terdokumentasi: {len(df_outlier_trx_summary)}")
df_outlier_trx_summary[['KATEGORI_OUTLIER', 'ID_TRANSAKSI', 'ENTITAS_BARANG', 'NILAI_AKTUAL', 'MANIFESTASI_DARI_DEFINISI_GENERAL', 'PENJELASAN_KONKRET']]
''')

# ==============================================================================
# CELL 12: VISUALISASI TRANSAKSI
# ==============================================================================
add_code(r'''fig, axes = plt.subplots(1, 2, figsize=(16, 5.5))

# Plot 1: Tren Omzet Harian & Titik Lonjakan
omzet_h['TGL_DTT'] = pd.to_datetime(omzet_h['TGL_STR'])
omzet_h_sorted = omzet_h.sort_values(by='TGL_DTT')

axes[0].plot(omzet_h_sorted['TGL_DTT'], omzet_h_sorted['JUMLAH'] / 1e6, color='#4a90e2', linewidth=1.5, label='Omzet Harian')
axes[0].axhline(omzet_h['JUMLAH'].median() / 1e6, color='gray', linestyle='--', label=f'Median: Rp {omzet_h[\"JUMLAH\"].median()/1e6:.1f}M')

spike_dtt = pd.to_datetime(hari_lonjakan['TGL_STR'])
axes[0].scatter(spike_dtt, hari_lonjakan['JUMLAH'] / 1e6, color=C_ALERT, s=85, zorder=5, label='Hari Lonjakan Ekstrem')

for _, r in hari_lonjakan.iterrows():
    axes[0].annotate(
        r['TGL_STR'],
        (pd.to_datetime(r['TGL_STR']), r['JUMLAH'] / 1e6),
        textcoords="offset points",
        xytext=(0, 7),
        ha='center',
        fontsize=8,
        fontweight='bold',
        color='#900C3F'
    )

axes[0].set_title('Tren Omzet Harian & Deteksi Hari Lonjakan Anomali', fontweight='bold')
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

top_trx_pts = df_valid_trx[df_valid_trx['JUMLAH'] >= 30_000_000]
axes[1].scatter(top_trx_pts['QTY'], top_trx_pts['JUMLAH'], color=C_ALERT, s=95, zorder=5, label='Trx Ekstrem (>= Rp 30M)')

for _, r in top_trx_pts.iterrows():
    axes[1].annotate(
        f"{r['NAMA'].split()[-1]}\nRp {r['JUMLAH']/1e6:.1f}M",
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
axes[1].set_xlabel('Kuantitas Pemesanan (QTY, Skala Log)')
axes[1].set_ylabel('Total Nilai Transaksi (Rp, Skala Log)')
axes[1].legend()

plt.tight_layout()
plt.show()
''')

# ==============================================================================
# CELL 13: SINTESIS MATRIKS KOMPREHENSIF SELURUH OUTLIER
# ==============================================================================
add_md(r'''---
## 5. Rangkuman Matriks Sintesis Seluruh Outlier & Rekomendasi Kebijakan

Tabel di bawah menyatukan seluruh investigasi outlier lintas 3 dimensi (Pelanggan, Harga, dan Transaksi) lengkap dengan **definisi abnormality general, manifestasi spesifiknya, dan kebijakan data science-nya**:

| No | Dimensi | Sub-Kategori Outlier | Definisi *Abnormality* General Payung | Manifestasi Spesifik (*Abnormality-nya Apa*) | Kebijakan Data Science (*Action*) |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **Pelanggan** | Super-Wholesaler (Paus) | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Lonjakan ekstrem pada dimensi Moneter ($M > Q_3 + 3\times\text{IQR}$). `TOKO CITA RASA BARU` (Rp 547,7M) dan `ADEK FROZEN` (Rp 420,7M) menguasai $> 21\%$ omzet toko. | **Pertahankan & Segmentasikan Khusus** (B2B Distributor) |
| **2** | **Pelanggan** | Shock Buyer (Borongan Spontan) | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Anomali relasi F-M: Kunjungan belanja $F \le 2$, namun AOV per baris $> 50\times$ rata-rata toko ($> \text{Rp } 10\text{M}$). `PAK SUTARMUJI` (2 transaksi, Rp 126,4M) dan `MAS ROHMAT` (Rp 45,7M). | **Tandai** sebagai pembeli borongan insidental |
| **3** | **Pelanggan** | Pelanggan Mikro / 1x Beli | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Ekor bawah ekstrem distribusi Frekuensi-Moneter: Tepat bertransaksi 1 baris sepanjang 6 bulan dengan belanja $< \text{Rp } 500\text{rb}$ (32 outlet). | **Kelompokkan ke Segmen Churned / At-Risk** |
| **4** | **Pelanggan** | Akun Anonim Walk-in | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Cacat identitas karena agregasi semu: Label `CASH` penampung 656 transaksi tunai senilai Rp 167,4M. Mencampur belanja cone Rp 5rb dengan 106 dus kentang Rp 25,4M. | **Keluarkan dari clustering RFM** (agar tidak membiaskan klaster) |
| **5** | **Pelanggan** | Pelanggan Non-Komersial | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Cacat identitas ketiadaan nilai komersial: Entitas saldo $\text{Monetary} = \text{Rp } 0$. `SAMPLING MITRAKU` dan `SAMPEL CRB` (pos tester internal). | **Keluarkan dari master data pelanggan** |
| **6** | **Pelanggan** | Fragmentasi Ejaan / Kanal | Kegagalan representasi profil belanja individu wajar: menyimpang ekstrem pada manifold LRFM atau cacat identitas. | Cacat identitas fragmentasi penamaan: Satu toko terpecah menjadi beberapa varian nama (`ADEK FROZEN` Rp 288M dan `C - ADEK FROZEN` Rp 132M). | **Standardisasi Identitas** (*Entity Resolution*) |
| **7** | **Harga** | Harga Nol (Kasir Lupa Input) | Penyimpangan nilai nominal/efektif dari ekspektasi ekuilibrium pasar terhadap basis pembanding $X$: $E[\text{Price} \mid X]$. | Distorsi pencatatan terhadap $X_1$ (Eksistensi Nilai Komersial): 20 baris transaksi CASH borongan keluar dengan $\text{HARGA} = 0$. Omzet toko hilang Rp 90,72 Juta. | **Imputasi Harga Pasar Terdekat** (+Rp 90,72 Juta) |
| **8** | **Harga** | Harga Nol (Tester Promosi) | Penyimpangan nilai nominal/efektif dari ekspektasi ekuilibrium pasar terhadap basis pembanding $X$: $E[\text{Price} \mid X]$. | Distorsi pencatatan terhadap $X_1$: 39 baris barang sampel promosi dari pabrik ke mitra ritel kuantitas 1-2 pack bernilai Rp 0. | **Keluarkan dari omzet komersial** |
| **9** | **Harga** | Deviasi Median SKU Sejenis | Penyimpangan nilai nominal/efektif dari ekspektasi ekuilibrium pasar terhadap basis pembanding $X$: $E[\text{Price} \mid X]$. | Diskriminasi harga terhadap $X_2$ (Median SKU): `LUTOSA-001` dijual Rp 15rb (median Rp 26rb, deviasi $-42.3\%$) ke `FADIL ANAK BOS` (diskon orang dalam / keluarga). | **Tandai** sebagai harga khusus keluarga/promo |
| **10** | **Harga** | Outlier Satuan Terendah | Penyimpangan nilai nominal/efektif dari ekspektasi ekuilibrium pasar terhadap basis pembanding $X$: $E[\text{Price} \mid X]$. | Disparitas kemasan terhadap $X_3$ (Satuan Fisik BKS): Cone es krim dijual hanya Rp 5.000 – Rp 7.000/bks. Batas bawah harga unit di katalog toko. | **Pertahankan** (karakteristik komoditas es krim) |
| **11** | **Harga** | Diskon Ekstrem Aritmetika | Penyimpangan nilai nominal/efektif dari ekspektasi ekuilibrium pasar terhadap basis pembanding $X$: $E[\text{Price} \mid X]$. | Diskriminasi promo terhadap $X_5$ (Nilai Aritmetika Normal): Rasio $\text{JUMLAH}/(\text{QTY}\times\text{HARGA}) \le 0.50$ (diskon tepat 50.0% khusus `PAK ERWIN`). | **Tandai** sebagai promo khusus *clearance* |
| **12** | **Transaksi** | Nilai Transaksi Rupiah Ekstrem | Pelanggaran asumsi dasar operasional proses bisnis penjualan: skala ekstrem, pelanggaran waktu, atau kegagalan sistem POS. | Pelanggaran Skala Operasional: $\text{JUMLAH} > \text{Rp } 54,9 \text{ Juta}$ (pagar luar logaritmik Tukey). Baris 4566 & 4937: Masing-masing Rp 63,2 Juta (Pak Sutarmuji). | **Pertahankan** (transaksi grosir riil tervalidasi) |
| **13** | **Transaksi** | Kuantitas Pemesanan Ekstrem | Pelanggaran asumsi dasar operasional proses bisnis penjualan: skala ekstrem, pelanggaran waktu, atau kegagalan sistem POS. | Pelanggaran Skala Operasional: $z_{\text{robust}} > 8$ per SKU. Baris 5083 (400 Pack Bakso Mie ke Anton), Baris 2949 (240 Pack ke Putri). | **Pertahankan** (pola konsumsi grosir) |
| **14** | **Transaksi** | Duplikasi Transaksi Persis | Pelanggaran asumsi dasar operasional proses bisnis penjualan: skala ekstrem, pelanggaran waktu, atau kegagalan sistem POS. | Kegagalan Sistem POS: Rekaman identik 100% pada seluruh kolom nota (143 baris transaksi / 73 salinan berlebih akibat kasir double klik saat lag). | **Tandai & Filter Salinan Berlebih** |
| **15** | **Transaksi** | Pelanggaran Hari Operasional | Pelanggaran asumsi dasar operasional proses bisnis penjualan: skala ekstrem, pelanggaran waktu, atau kegagalan sistem POS. | Pelanggaran Jadwal Operasional: Transaksi tercatat pada Hari Minggu (Baris 5546: Minggu 30 Agustus 2020, Pak Pepi Rp 180rb). 25 dari 26 Minggu tutup. | **Tandai** transaksi darurat luar jam operasional |
| **16** | **Transaksi** | Hari Lonjakan Omzet Harian | Pelanggaran asumsi dasar operasional proses bisnis penjualan: skala ekstrem, pelanggaran waktu, atau kegagalan sistem POS. | Pelanggaran Pola Waktu: Omzet harian melonjak $> 5\times$ median harian ($z_{\text{robust}} > 5$). 4 Hari Spike mencapai Rp 188 Juta/hari didorong restock distributor. | **Korelasikan** dengan tren musiman bulanan |

---

### 💡 Kesimpulan Strategis Data Science
1. **Outlier Tidak Boleh Dihapus Sembarangan**: Sebagian outlier memuat informasi bisnis yang paling bernilai (*Super-wholesaler*, *Shock buyer*, restock bulanan).
2. **Pembersihan Wajib Dilakukan pada Anomali Integritas**: Kasir lupa input harga (imputasi +Rp 90,7M), duplikasi sistem (eliminasi 73 salinan), dan penyatuan prefiks 46 outlet toko.
''')

# Simpan ke notebook file
OUTPUT_PATH = '06_deteksi_outlier_multidimensi.ipynb'
with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1, ensure_ascii=False)

print(f"File notebook baru berhasil digenerate: '{OUTPUT_PATH}' ({len(notebook['cells'])} sel).")

# Salin juga ke folder notebook/
os.makedirs('notebook', exist_ok=True)
shutil.copyfile(OUTPUT_PATH, os.path.join('notebook', OUTPUT_PATH))
print(f"Salinan notebook berhasil diperbarui ke 'notebook/{OUTPUT_PATH}'.")
