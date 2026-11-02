import asyncio
from playwright.async_api import async_playwright
import os
import fitz

def build_html():
    return """<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan UTS Kelompok ADD - Analisis Asosiasi & Regresi Nominal</title>
<style>
  @page {
    size: A4 portrait;
    margin: 8mm 10mm 8mm 10mm;
  }
  * {
    box-sizing: border-box;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  body {
    font-family: "Times New Roman", Times, Georgia, serif;
    font-size: 8.5pt;
    line-height: 1.25;
    color: #000000;
    margin: 0;
    padding: 0;
    background: #ffffff;
  }
  .page {
    width: 100%;
    height: 281mm;
    max-height: 281mm;
    page-break-after: always;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    overflow: hidden;
  }
  .page:last-child {
    page-break-after: avoid;
  }
  .header-box {
    border-bottom: 2px solid #000000;
    padding-bottom: 4px;
    margin-bottom: 6px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
  }
  .header-title h1 {
    font-size: 13pt;
    font-weight: 800;
    color: #000000;
    margin: 0 0 2px 0;
    letter-spacing: -0.2px;
    text-transform: uppercase;
  }
  .header-title p {
    font-size: 8.2pt;
    color: #111111;
    margin: 0;
    font-weight: 600;
  }
  .header-meta {
    text-align: right;
    font-size: 8pt;
    color: #000000;
    line-height: 1.25;
  }
  .metod-box {
    background: #fafafa;
    border: 1px solid #444444;
    border-radius: 2px;
    padding: 4px 8px;
    margin-bottom: 7px;
    font-size: 7.4pt;
    color: #111111;
    line-height: 1.22;
  }
  .section-card {
    border: 1px solid #000000;
    border-radius: 2px;
    padding: 7px 9px;
    background: #ffffff;
  }
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #333333;
    padding-bottom: 3px;
    margin-bottom: 5px;
  }
  .section-title {
    font-size: 9pt;
    font-weight: 800;
    color: #000000;
  }
  .stat-pill {
    background: #f2f2f2;
    border: 1px solid #555555;
    color: #000000;
    padding: 1px 5px;
    border-radius: 2px;
    font-size: 7.2pt;
    font-weight: bold;
    margin-left: 4px;
  }
  .badge-confirmed {
    background: #000000;
    color: #ffffff;
    padding: 1px 5px;
    border-radius: 2px;
    font-size: 7.2pt;
    font-weight: bold;
  }
  .content-grid {
    display: grid;
    grid-template-columns: 1.14fr 0.86fr;
    gap: 8px;
    align-items: center;
  }
  table.data-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 7.2pt;
    margin-top: 2px;
  }
  table.data-table th, table.data-table td {
    border: 1px solid #000000;
    padding: 3px 4px;
    text-align: right;
    color: #000000;
  }
  table.data-table th {
    background: #e8e8e8;
    color: #000000;
    font-weight: 800;
    text-align: center;
  }
  table.data-table td:first-child {
    text-align: left;
    font-weight: bold;
  }
  .highlight-cell {
    background: #dcdcdc;
    font-weight: bold;
  }
  .equation-box {
    background: #fafafa;
    border: 1px solid #555555;
    border-left: 3.5px solid #000000;
    padding: 4px 6px;
    margin: 0;
    font-size: 7.6pt;
    border-radius: 0 2px 2px 0;
  }
  .eq-title {
    font-weight: 800;
    color: #000000;
    margin-bottom: 2px;
    font-size: 7.7pt;
  }
  .eq-formula {
    font-family: "Courier New", Courier, monospace;
    font-weight: 700;
    color: #000000;
    background: #f0f0f0;
    padding: 2.5px 5px;
    border-radius: 2px;
    border: 1px solid #777777;
    display: block;
    margin: 2px 0;
    font-size: 7.4pt;
  }
  .eq-desc {
    color: #111111;
    font-size: 7.1pt;
    margin: 1.5px 0 0 0;
    line-height: 1.18;
  }
  .figure-box {
    text-align: center;
    background: #ffffff;
    border: 1px solid #666666;
    border-radius: 2px;
    padding: 2px;
  }
  .figure-box img {
    width: 100%;
    height: auto;
    max-height: 104px;
    display: block;
    margin: 0 auto;
    object-fit: contain;
  }
  .footer-box {
    border-top: 1px solid #000000;
    padding-top: 3px;
    font-size: 7.2pt;
    color: #111111;
    display: flex;
    justify-content: space-between;
  }
</style>
</head>
<body>

<!-- ==================== HALAMAN 1: SOAL 3 & SOAL 6 ==================== -->
<div class="page">
  <!-- Header & Metodologi -->
  <div>
    <div class="header-box">
      <div class="header-title">
        <h1>LAPORAN UTS — ANALISIS DATA DISKRIT (ADD)</h1>
        <p>Analisis Asosiasi Multivariat & Pemodelan Regresi Nominal (N = 6.740 Transaksi Penjualan Frozen Food)</p>
      </div>
      <div class="header-meta">
        <div><b>Institut Teknologi Sepuluh Nopember</b></div>
        <div>Departemen Sistem Informasi</div>
      </div>
    </div>

    <div class="metod-box">
      <b>Metodologi Ringkas:</b> Uji independensi kategorik menggunakan <i>Chi-Square Test of Independence</i> (χ²) pada taraf signifikansi α = 0,05 dan derajat kekuatan asosiasi dengan <i>Cramér's V</i>. Pemodelan regresi nominal dilakukan dalam 2 arah matematis (Arah 1: Prediksi variabel B saat A diketahui, dan Arah 2: Prediksi variabel A saat B diketahui) untuk mengestimasi koefisien bobot bersyarat dan serapan volume komoditas riil.
    </div>
  </div>

  <!-- SOAL 3 -->
  <div class="section-card">
    <div class="section-header">
      <span class="section-title">SOAL 3: Asosiasi antara Merk Tertentu (BRAND) dengan Satuan Barang yang Dijual (SATUAN)</span>
      <div>
        <span class="stat-pill">χ² = 22.941,68 | df = 438 | p &lt; 0,0001 | Cramér's V = 0,7532</span>
        <span class="badge-confirmed">CONFIRMED (YA)</span>
      </div>
    </div>
    
    <div class="content-grid">
      <div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Merk (BRAND)</th>
              <th>DUS</th>
              <th>PACK</th>
              <th>PAIL</th>
              <th>BAL</th>
              <th>BKS</th>
              <th>JRG</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>JOFRANS</td><td class="highlight-cell">747 (64%)</td><td>425 (36%)</td><td>0</td><td>0</td><td>0</td><td>0</td><td>1.172</td></tr>
            <tr><td>OKEY</td><td class="highlight-cell">591 (77%)</td><td>179 (23%)</td><td>0</td><td>0</td><td>0</td><td>0</td><td>770</td></tr>
            <tr><td>MINAKU</td><td class="highlight-cell">368 (69%)</td><td>165 (31%)</td><td>0</td><td>0</td><td>0</td><td>0</td><td>533</td></tr>
            <tr><td>MIAMI</td><td>0</td><td>0</td><td class="highlight-cell">410 (100%)</td><td>0</td><td>0</td><td>0</td><td>410</td></tr>
            <tr><td>DEN</td><td>0</td><td>226 (63%)</td><td>0</td><td class="highlight-cell">134 (37%)</td><td>0</td><td>0</td><td>360</td></tr>
            <tr><td>DELMONTE</td><td>6 (24%)</td><td>6 (24%)</td><td>0</td><td>0</td><td>0</td><td class="highlight-cell">11 (44%)</td><td>25</td></tr>
          </tbody>
        </table>
        <p style="font-size:7.1pt; color:#111111; margin:3px 0 0 0; line-height:1.2;">
          <b>Bukti Asosiasi:</b> Terbukti signifikan secara statistik (Cramér's V = 0,7532, sangat kuat). Satuan kemasan sangat terikat pada merk: Miami 100% PAIL, Den hanya PACK/BAL tanpa DUS, Delmonte jerigen JRG.
        </p>
      </div>
      <div>
        <div class="figure-box">
          <img src="figures/fig_no3_brand_satuan.png" alt="Grafik Soal 3">
        </div>
      </div>
    </div>

    <!-- 2 Persamaan Regresi Soal 3 -->
    <div style="margin-top:5px; display:grid; grid-template-columns:1fr 1fr; gap:7px;">
      <div class="equation-box">
        <div class="eq-title">Jawaban 1: Bila Merk JOFRANS dijual, satuan apa yang kemungkinan besar keluar?</div>
        <span class="eq-formula">Merk (JOFRANS) = 3,65 × [DUS] + 2,10 × [PACK] + 0,00 × [PAIL] + ε</span>
        <div class="eq-desc"><b>Probabilitas Kemunculan:</b> P(Satuan | JOFRANS) = 0,637 [DUS] + 0,363 [PACK]. Rata-rata transaksi keluar dalam 3,65 dus atau 2,10 pack, mustahil berbentuk pail/bal.</div>
      </div>
      <div class="equation-box">
        <div class="eq-title">Jawaban 2: Bila satuan PAIL (Ember) dijual, merk apa yang kemungkinan besar keluar?</div>
        <span class="eq-formula">Satuan (PAIL) = 0,804 × [MIAMI] + 0,169 × [INDOESKRIM] + 0,027 × [DIAMOND] + ε</span>
        <div class="eq-desc"><b>Interpretasi:</b> Pengeluaran satuan PAIL 80,4% dipastikan es krim MIAMI dan 16,9% INDOESKRIM. Bila satuan BAL: BAL = 0,838 DEN + 0,138 PK + ε.</div>
      </div>
    </div>
  </div>

  <!-- SOAL 6 -->
  <div class="section-card">
    <div class="section-header">
      <span class="section-title">SOAL 6: Asosiasi antara Merk Tertentu (BRAND) dengan Produk yang Dijual (NAMA_BARANG)</span>
      <div>
        <span class="stat-pill">χ² = 492.020,00 | df = 19.491 | p &lt; 0,0001 | Cramér's V = 1,0000</span>
        <span class="badge-confirmed">CONFIRMED (YA)</span>
      </div>
    </div>
    
    <div class="content-grid">
      <div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Produk (NAMA_BARANG)</th>
              <th>JOFRANS</th>
              <th>MINAKU</th>
              <th>OKEY</th>
              <th>MIAMI</th>
              <th>DELMONTE</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>MINAKU OTAK OTAK 500 GR X 20 PACK</td><td>0</td><td class="highlight-cell">378 (100%)</td><td>0</td><td>0</td><td>0</td></tr>
            <tr><td>OKEY SOSIS 500 GR X 20 PACK</td><td>0</td><td>0</td><td class="highlight-cell">288 (100%)</td><td>0</td><td>0</td></tr>
            <tr><td>JOFRANS NUGGET AYAM HATI 500 GR</td><td class="highlight-cell">244 (100%)</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>
            <tr><td>MIAMI ICE CREAM REG. NEAPOLITAN 8 LT</td><td>0</td><td>0</td><td>0</td><td class="highlight-cell">174 (100%)</td><td>0</td></tr>
            <tr><td>DELMONTE EXT HOT JRG 5.7 KG</td><td>0</td><td>0</td><td>0</td><td>0</td><td class="highlight-cell">10 (100%)</td></tr>
          </tbody>
        </table>
        <p style="font-size:7.1pt; color:#111111; margin:3px 0 0 0; line-height:1.2;">
          <b>Bukti Asosiasi:</b> Hubungan bersifat deterministik mutlak (Cramér's V = 1,0000). Setiap produk unik secara eksklusif diproduksi oleh 1 merk tunggal (struktur blok ortogonal sempurna).
        </p>
      </div>
      <div>
        <div class="figure-box">
          <img src="figures/fig_no6_brand_produk.png" alt="Grafik Soal 6">
        </div>
      </div>
    </div>

    <!-- 2 Persamaan Regresi Soal 6 -->
    <div style="margin-top:5px; display:grid; grid-template-columns:1fr 1fr; gap:7px;">
      <div class="equation-box">
        <div class="eq-title">Jawaban 1: Bila Merk MINAKU dijual, produk apa yang kemungkinan besar menyumbang?</div>
        <span class="eq-formula">Merk (MINAKU) = 5,2 × [Otak-Otak] + 2,1 × [Kentang 7x7] + 1,0 × [Sisik Naga] + ε</span>
        <div class="eq-desc"><b>Proporsi Kontribusi:</b> Minaku Otak-Otak menyumbang 70,9% transaksi total merk Minaku dengan rata-rata 5,2 pack per transaksi, disusul olahan seafood lainnya.</div>
      </div>
      <div class="equation-box">
        <div class="eq-title">Jawaban 2: Bila produk kategori NUGGET masuk katalog, kemungkinan besar merk apa?</div>
        <span class="eq-formula">Produk (Kategori Nugget) = 0,951 × [JOFRANS] + 0,018 × [FOODY] + 0,014 × [OKEY] + ε</span>
        <div class="eq-desc"><b>Interpretasi Deterministik:</b> 95,1% produk nugget dinaungi merk JOFRANS. Untuk produk tunggal spesifik: Produk (Minaku Otak-Otak) = 1,00 × [MINAKU] + 0,00 × [JOFRANS] + ε.</div>
      </div>
    </div>
  </div>

  <!-- Footer Halaman 1 -->
  <div class="footer-box">
    <span>Departemen Sistem Informasi — Institut Teknologi Sepuluh Nopember</span>
    <span>Halaman 1</span>
  </div>
</div>

<!-- ==================== HALAMAN 2: SOAL 8, SOAL 10, & MATRIKS ==================== -->
<div class="page">
  <!-- SOAL 8 -->
  <div class="section-card">
    <div class="section-header">
      <span class="section-title">SOAL 8: Asosiasi antara Produk Tertentu (NAMA_BARANG) dengan Satuan Barang yang Dibeli (SATUAN)</span>
      <div>
        <span class="stat-pill">χ² = 28.986,89 | df = 1.602 | p &lt; 0,0001 | Cramér's V = 0,8466</span>
        <span class="badge-confirmed">CONFIRMED (YA)</span>
      </div>
    </div>
    
    <div class="content-grid">
      <div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Produk (NAMA_BARANG)</th>
              <th>DUS</th>
              <th>PACK</th>
              <th>PAIL</th>
              <th>BAL</th>
              <th>BKS</th>
              <th>JRG</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>MINAKU OTAK OTAK 500 GR</td><td class="highlight-cell">267 (71%)</td><td>111 (29%)</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>
            <tr><td>OKEY SOSIS 500 GR X 20 PACK</td><td class="highlight-cell">239 (83%)</td><td>49 (17%)</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>
            <tr><td>MIAMI ICE CREAM REG. NEAPOLITAN 8 LT</td><td>0</td><td>0</td><td class="highlight-cell">174 (100%)</td><td>0</td><td>0</td><td>0</td></tr>
            <tr><td>CONE TP 17 ISI 20 (SEDANG)</td><td>0</td><td>0</td><td>0</td><td>0</td><td class="highlight-cell">35 (100%)</td><td>0</td></tr>
            <tr><td>DELMONTE EXT HOT JRG 5.7 KG</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td class="highlight-cell">10 (100%)</td></tr>
          </tbody>
        </table>
        <p style="font-size:7.1pt; color:#111111; margin:3px 0 0 0; line-height:1.2;">
          <b>Bukti Asosiasi:</b> Sangat kuat (Cramér's V = 0,8466). Satuan kemasan melekat kaku pada bentuk fisik produk: es krim ember dalam PAIL, cone es krim dalam BKS, saus dalam jerigen JRG, sosis/nugget dalam DUS dan PACK.
        </p>
      </div>
      <div>
        <div class="figure-box">
          <img src="figures/fig_no8_produk_satuan.png" alt="Grafik Soal 8">
        </div>
      </div>
    </div>

    <!-- 2 Persamaan Regresi Soal 8 -->
    <div style="margin-top:5px; display:grid; grid-template-columns:1fr 1fr; gap:7px;">
      <div class="equation-box">
        <div class="eq-title">Jawaban 1: Bila produk Minaku Otak-Otak 500g dibeli, satuan apa yang digunakan?</div>
        <span class="eq-formula">Produk (Minaku Otak-Otak) = 0,706 × [DUS] + 0,294 × [PACK] + 0,00 × [PAIL] + ε</span>
        <div class="eq-desc"><b>Preferensi Kulakan:</b> Pembelian Minaku Otak-Otak didominasi satuan grosir DUS (70,6%) dan eceran PACK (29,4%). Untuk produk es krim: Produk (Miami 8L) = 1,00 × [PAIL] + ε.</div>
      </div>
      <div class="equation-box">
        <div class="eq-title">Jawaban 2: Bila satuan kemasan JRG (Jerigen) keluar, produk apa di dalamnya?</div>
        <span class="eq-formula">Satuan (JRG) = 0,909 × [Delmonte Pedas] + 0,091 × [Delmonte Tomat] + ε</span>
        <div class="eq-desc"><b>Satuan BKS:</b> Satuan (BKS) = 0,402 × [Cone TP17] + 0,230 × [Cone TP13] + 0,207 × [Kentang 500g] + ε. JRG 100% saus curah Delmonte, BKS didominasi perlengkapan es krim cone.</div>
      </div>
    </div>
  </div>

  <!-- SOAL 10 -->
  <div class="section-card">
    <div class="section-header">
      <span class="section-title">SOAL 10: Asosiasi antara Pembeli Tertentu (PELANGGAN) dengan Produk yang Dibeli (NAMA_BARANG)</span>
      <div>
        <span class="stat-pill">χ² = 57.866,01 | df = 48.060 | p = 3,36e-194 | Cramér's V = 0,2184</span>
        <span class="badge-confirmed">CONFIRMED (YA)</span>
      </div>
    </div>
    
    <div class="content-grid">
      <div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Pelanggan</th>
              <th>Otak-Otak</th>
              <th>Baso Sapi</th>
              <th>Nugget Hati</th>
              <th>Kentang</th>
              <th>Fish Tofu</th>
              <th>Total Trx</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>ADEK FROZEN</td><td class="highlight-cell">12 (4,2%)</td><td class="highlight-cell">11 (3,9%)</td><td class="highlight-cell">12 (4,2%)</td><td class="highlight-cell">12 (4,2%)</td><td>8 (2,8%)</td><td>285</td></tr>
            <tr><td>AMANAH FROZEN</td><td>19 (5,4%)</td><td>2 (0,6%)</td><td>9 (2,5%)</td><td>0</td><td>11 (3,1%)</td><td>354</td></tr>
            <tr><td>TOKO CITA RASA BARU</td><td class="highlight-cell">42 (8,0%)</td><td>0</td><td>15 (2,8%)</td><td>1 (0,2%)</td><td>14 (2,7%)</td><td>528</td></tr>
            <tr><td>ACHEN / VINCENT</td><td>5 (3,8%)</td><td>4 (3,1%)</td><td>0</td><td>2 (1,5%)</td><td>3 (2,3%)</td><td>130</td></tr>
            <tr><td>ANTON</td><td>3 (4,3%)</td><td>6 (8,6%)</td><td>0</td><td>0</td><td>1 (1,4%)</td><td>70</td></tr>
          </tbody>
        </table>
        <p style="font-size:7.1pt; color:#111111; margin:3px 0 0 0; line-height:1.2;">
          <b>Bukti Asosiasi:</b> Signifikan secara statistik (p = 3,36e-194). Setiap gerai memiliki segmentasi keranjang belanja unik: Adek Frozen fokus kulakan varian Jofrans Nugget, Baso Sapi, dan Otak-Otak.
        </p>
      </div>
      <div>
        <div class="figure-box">
          <img src="figures/fig_no10_pelanggan_produk.png" alt="Grafik Soal 10">
        </div>
      </div>
    </div>

    <!-- 2 Persamaan Regresi Soal 10 (Sesuai Contoh Dosen) -->
    <div style="margin-top:5px; display:grid; grid-template-columns:1fr 1fr; gap:7px;">
      <div class="equation-box">
        <div class="eq-title">Jawaban 1: Bila Pembeli ADEK FROZEN datang, produk apa yang kemungkinan besar dibeli?</div>
        <span class="eq-formula">Pembeli (Adek Frozen) = 2,4 × [Nugget] + 1,8 × [Otak-otak] + 1,2 × [Kentang] + 0,9 × [Baso Sapi] + ε</span>
        <div class="eq-desc"><b>Rata-rata QTY Pembelian Riil:</b> Pembeli (Adek Frozen) = 16,7 × [Otak-Otak] + 12,9 × [Nugget Hati] + 7,3 × [Kentang] + 5,6 × [Baso Sapi] + ε. Keranjang belanja Adek Frozen sangat khas didominasi nugget dan otak-otak.</div>
      </div>
      <div class="equation-box">
        <div class="eq-title">Jawaban 2: Bila ada produk datang (Jofrans Baso Sapi), kemungkinan besar dibeli oleh siapa?</div>
        <span class="eq-formula">Produk (Jofrans Baso Sapi) = 3,2 × [Adek Frozen] + 2,1 × [Anton] + 1,8 × [Rumah Sosis] + ε</span>
        <div class="eq-desc"><b>Produk Minaku Otak-Otak:</b> Produk (Otak-Otak) = 4,5 × [Cita Rasa Baru] + 3,2 × [Amanah Frozen] + 2,4 × [Adek Frozen] + ε. Menggambarkan daya serap kuantitas pelanggan terhadap stok komoditas.</div>
      </div>
    </div>
  </div>

  <!-- RANGKUMAN MATRIKS PERSAMAAN REGRESI -->
  <div style="background:#fafafa; border:1px solid #000000; border-radius:2px; padding:6px 9px;">
    <div style="font-weight:800; color:#000000; font-size:8pt; margin-bottom:3px; text-transform:uppercase;">
      Rangkuman Matriks 8 Persamaan Regresi Nominal (Analisis Data Diskrit)
    </div>
    <table style="width:100%; border-collapse:collapse; font-size:7.2pt;">
      <thead>
        <tr style="background:#e8e8e8; color:#000000;">
          <th style="padding:2.5px; border:1px solid #000000; width:5%; text-align:center;">No</th>
          <th style="padding:2.5px; border:1px solid #000000; width:20%; text-align:left;">Pasangan Asosiasi</th>
          <th style="padding:2.5px; border:1px solid #000000; width:37%; text-align:left;">Persamaan Regresi 1 (Arah A → B)</th>
          <th style="padding:2.5px; border:1px solid #000000; width:38%; text-align:left;">Persamaan Regresi 2 (Arah B → A)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td style="text-align:center; font-weight:bold; border:1px solid #000000;">3</td>
          <td style="font-weight:bold; border:1px solid #000000;">Merk ↔ Satuan</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Merk(JOFRANS) = 3,65 × [DUS] + 2,10 × [PACK] + ε</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Satuan(PAIL) = 0,804 × [MIAMI] + 0,169 × [INDOESKRIM] + ε</td>
        </tr>
        <tr>
          <td style="text-align:center; font-weight:bold; border:1px solid #000000;">6</td>
          <td style="font-weight:bold; border:1px solid #000000;">Merk ↔ Produk</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Merk(MINAKU) = 5,2 × [Otak-Otak] + 2,1 × [Kentang] + ε</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Produk(Nugget) = 0,951 × [JOFRANS] + 0,018 × [FOODY] + ε</td>
        </tr>
        <tr>
          <td style="text-align:center; font-weight:bold; border:1px solid #000000;">8</td>
          <td style="font-weight:bold; border:1px solid #000000;">Produk ↔ Satuan</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Produk(Otak-Otak) = 0,706 × [DUS] + 0,294 × [PACK] + ε</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Satuan(JRG) = 0,909 × [Delmonte Pedas] + 0,091 × [Tomat] + ε</td>
        </tr>
        <tr>
          <td style="text-align:center; font-weight:bold; border:1px solid #000000;">10</td>
          <td style="font-weight:bold; border:1px solid #000000;">Pembeli ↔ Produk</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Pembeli(Adek Frozen) = 2,4 × [Nugget] + 1,8 × [Otak-Otak] + ε</td>
          <td style="border:1px solid #000000; font-family:'Courier New', monospace;">Produk(Baso Sapi) = 3,2 × [Adek Frozen] + 2,1 × [Anton] + ε</td>
        </tr>
      </tbody>
    </table>
  </div>

  <!-- Footer Halaman 2 -->
  <div class="footer-box">
    <span>Departemen Sistem Informasi — Institut Teknologi Sepuluh Nopember</span>
    <span>Halaman 2</span>
  </div>
</div>

</body>
</html>
"""

async def main():
    html_content = build_html()
    with open('laporan_uts/laporan_uts_2_halaman.html', 'w', encoding='utf-8') as f:
        f.write(html_content)
    print('Updated laporan_uts_2_halaman.html successfully!')
    
    html_path = os.path.abspath('laporan_uts/laporan_uts_2_halaman.html')
    pdf_path = os.path.abspath('laporan_uts/Laporan_UTS_ADD_Kelompok_2_Halaman.pdf')
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        await page.goto(f'file:///{html_path}')
        await page.pdf(path=pdf_path, format='A4', print_background=True, margin={'top': '8mm', 'bottom': '8mm', 'left': '10mm', 'right': '10mm'})
        await browser.close()
    
    doc = fitz.open(pdf_path)
    print('PDF Compiled. TOTAL PAGES:', len(doc))
    for i, p in enumerate(doc):
        pix = p.get_pixmap(dpi=150)
        pix.save(f'scratch/pdf_page_{i+1}.png')
    print('Rendered scratch/pdf_page_1.png and scratch/pdf_page_2.png')

asyncio.run(main())
