Add-Type -AssemblyName System.Drawing

$outDir = "slide_assets\outlier_ppt"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

function New-Color($hex, $alpha=255) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0,2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2,2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4,2), 16)
    return [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b)
}

function New-RoundedRect($x, $y, $w, $h, $r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    if ($d -le 0) {
        $path.AddRectangle((New-Object System.Drawing.RectangleF($x, $y, $w, $h)))
        return $path
    }
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-Card($g, $x, $y, $w, $h, $bgHex, $borderHex, $borderWidth=1.5, $radius=12) {
    $path = New-RoundedRect $x $y $w $h $radius
    $brush = New-Object System.Drawing.SolidBrush (New-Color $bgHex)
    $pen = New-Object System.Drawing.Pen ((New-Color $borderHex), $borderWidth)
    $g.FillPath($brush, $path)
    $g.DrawPath($pen, $path)
    $brush.Dispose(); $pen.Dispose(); $path.Dispose()
}

function Draw-Header($g, $kicker, $title, $subtitle) {
    $fKicker = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $fTitle  = New-Object System.Drawing.Font("Segoe UI", 19, [System.Drawing.FontStyle]::Bold)
    $fSub    = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Regular)
    $bKicker = New-Object System.Drawing.SolidBrush (New-Color "#0284C7")
    $bTitle  = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
    $bSub    = New-Object System.Drawing.SolidBrush (New-Color "#475569")
    $g.DrawString($kicker, $fKicker, $bKicker, 48, 24)
    $g.DrawString($title, $fTitle, $bTitle, 48, 46)
    $g.DrawString($subtitle, $fSub, $bSub, 48, 82)
    $penLine = New-Object System.Drawing.Pen ((New-Color "#CBD5E1"), 1.5)
    $g.DrawLine($penLine, 48, 108, 1552, 108)
    $fKicker.Dispose(); $fTitle.Dispose(); $fSub.Dispose()
    $bKicker.Dispose(); $bTitle.Dispose(); $bSub.Dispose(); $penLine.Dispose()
}

# ==============================================================================
# FIG 1: ANATOMI OUTLIER VS ANOMALI DATA MENTAH (N = 6.779 -> 6.740)
# ==============================================================================
$bmp1 = New-Object System.Drawing.Bitmap(1600, 900)
$g1 = [System.Drawing.Graphics]::FromImage($bmp1)
$g1.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g1.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g1.Clear((New-Color "#F8FAFC"))

Draw-Header $g1 "TAHAP 0  |  PEMETAAN MEKANISME OUTLIER VS DATA ERROR (MATERI WEEK 5 SLIDE 3 & 10)" `
    "Anatomi Penyimpangan Data Frozen Food: Memisahkan Error Pencatatan vs Outlier Bisnis Sah" `
    "Sumber: Data Penjualan April - Sep 2020.xlsx (N = 6.779 baris mentah -> 6.740 transaksi bersih)  |  Prinsip: Tandai dulu, pilah mekanismenya"

Draw-Card $g1 48 124 940 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g1 1012 124 540 730 "#FFFFFF" "#E2E8F0" 1.5 12

$fSec = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fSubSec = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fReg  = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fSm   = New-Object System.Drawing.Font("Segoe UI", 8.8, [System.Drawing.FontStyle]::Regular)
$fSmB  = New-Object System.Drawing.Font("Segoe UI", 8.8, [System.Drawing.FontStyle]::Bold)

$bDark = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
$bMuted = New-Object System.Drawing.SolidBrush (New-Color "#475569")
$bLight = New-Object System.Drawing.SolidBrush (New-Color "#64748B")

$g1.DrawString("Frekuensi Temuan Anomali & Pencilan Menurut Mekanisme Sumbernya", $fSec, $bDark, 72, 144)
$g1.DrawString("Diurutkan berdasarkan jumlah baris terdampak; warna menunjukkan taksonomi penyebab & kebijakan tindakan", $fSubSec, $bMuted, 72, 170)

$rules = @(
    @{ Label="R01: Kode SKU >1 Ejaan Nama"; Count=533; Pct="7,86%"; Cat="Master Data Error (Diseragamkan)"; Color="#64748B" },
    @{ Label="R03: Outlet Tercatat >1 Kode Kanal"; Count=402; Pct="5,93%"; Cat="Master Data Error (Diseragamkan)"; Color="#64748B" },
    @{ Label="T01: Hari Lonjakan Omzet (Z_harian > 5)"; Count=370; Pct="5,46%"; Cat="Outlier Transaksi Temporal (4 Hari)"; Color="#0284C7" },
    @{ Label="S03: Kuantitas Borongan Ekstrem (Z_QTY > 8)"; Count=237; Pct="3,50%"; Cat="Outlier Transaksi Bisnis Sah (Whale)"; Color="#0284C7" },
    @{ Label="R02: Nama Barang Sama Dipakai >1 Kode"; Count=172; Pct="2,54%"; Cat="Master Data Error (ARTHUR vs LUTOSA)"; Color="#64748B" },
    @{ Label="D01: Duplikat Baris Identik Persis"; Count=73;  Pct="1,08%"; Cat="Human/System Error (Salinan Ganda)"; Color="#E11D48" },
    @{ Label="A01: Diskon Grosir Wajar (Rasio 85-97%)"; Count=73; Pct="1,08%"; Cat="Variasi Bisnis Sah (Pakai JUMLAH)"; Color="#10B981" },
    @{ Label="K03b/K05: Barang Keluar Gratis (Sampling)"; Count=38; Pct="0,56%"; Cat="Mekanisme Non-Penjualan (Dikeluarkan)"; Color="#E11D48" },
    @{ Label="S02: Harga Menyimpang Statistik (|Z| > 5)"; Count=26; Pct="0,38%"; Cat="Outlier Harga Barang (Tier/Miring)"; Color="#F59E0B" },
    @{ Label="K03a: Harga Kosong pada CASH Volume Besar"; Count=20; Pct="0,30%"; Cat="Human Error Lupa Input (Dipulihkan)"; Color="#F59E0B" },
    @{ Label="S01: Harga Menyimpang Ekstrem (>30% Median)"; Count=7; Pct="0,10%"; Cat="Outlier Harga Kritis (Terlalu Murah/Mahal)"; Color="#E11D48" },
    @{ Label="A02: Potongan Harga Tak Wajar (Diskon 50%)"; Count=4; Pct="0,06%"; Cat="Outlier Harga Efektif (PAK ERWIN -50%)"; Color="#E11D48" },
    @{ Label="S04: Nilai Transaksi > Pagar Log-IQR (Rp 63,2 Jt)"; Count=2; Pct="0,03%"; Cat="Outlier Transaksi Ekstrem (200 DUS)"; Color="#0284C7" },
    @{ Label="T02: Transaksi Hari Minggu (Diluar Pola Tutup)"; Count=1; Pct="0,01%"; Cat="Outlier Temporal Operasional (PAK PEPI)"; Color="#E11D48" }
)

$startY = 212
$rowH = 42
$maxBarW = 260.0
$maxVal = 550.0

for ($i = 0; $i -lt $rules.Count; $i++) {
    $r = $rules[$i]
    $y = $startY + $i * $rowH
    if ($i % 2 -eq 0) {
        $bRow = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC")
        $g1.FillRectangle($bRow, 68, $y - 4, 900, $rowH - 2)
        $bRow.Dispose()
    }
    $g1.DrawString($r.Label, $fSmB, $bDark, 74, $y + 6)
    $barX = 365
    $barW = [math]::Max(6.0, ($r.Count / $maxVal) * $maxBarW)
    $bBar = New-Object System.Drawing.SolidBrush (New-Color $r.Color)
    $pathBar = New-RoundedRect $barX ($y + 5) $barW 22 4
    $g1.FillPath($bBar, $pathBar)
    $bBar.Dispose(); $pathBar.Dispose()

    $valTxt = "$($r.Count) ($($r.Pct))"
    $g1.DrawString($valTxt, $fSmB, $bDark, $barX + $barW + 8, $y + 6)

    $bTag = New-Object System.Drawing.SolidBrush (New-Color $r.Color)
    $g1.DrawString($r.Cat, $fSm, $bTag, 710, $y + 6)
    $bTag.Dispose()
}

# Right Panel: Taxonomy & Pipeline Impact
$g1.DrawString("Taksonomi Penyebab (Week 5 Slide 10)", $fSec, $bDark, 1036, 144)

$cards = @(
    @{ Title="1. Human Error (Wrong Data Entry)"; Color="#F59E0B"; Bg="#FFFBEB";
       Body="- K03a (20 baris CASH): Pembelian tunai hingga 106 DUS Lutosa tercatat Rp 0 karena kasir lupa isi harga. Dipulihkan via k-NN QTY terdekat (+Rp 90,72 Juta omzet).`n- S01/A02: Salah ketik harga miring (LUTOSA-001 Rp 15rb vs Rp 26rb) & diskon 50%." },
    @{ Title="2. Sampling / Heterogeneous Mechanism"; Color="#E11D48"; Bg="#FFF1F2";
       Body="- K03b/K05 (38 baris): Barang keluar 1-3 PACK bernilai Rp 0 untuk SAMPEL CRB / SAMPLING MITRAKU. Sesuai definisi Hawkins (Slide 3), ini dihasilkan oleh mekanisme non-penjualan sehingga wajib dipisahkan (6.778 -> 6.740 baris)." },
    @{ Title="3. Data Manipulation / Master Error"; Color="#64748B"; Bg="#F1F5F9";
       Body="- Pecahnya identitas pelanggan: 229 nama mentah (mis. 'ADEK FROZEN' vs 'C - ADEK FROZEN') dinormalisasi menjadi 181 entitas unik (180 outlet + CASH). Tanpa ini, deteksi outlier pelanggan akan bias parah!" },
    @{ Title="4. True Business Outliers (Fokus 3 Sisi Tugas)"; Color="#0284C7"; Bg="#F0F9FF";
       Body="- Sisi 1 (Pelanggan): Whale Grosir (p1) & One-Shot Bulk Buyers (p2: beli 1-2x langsung puluhan juta).`n- Sisi 2 (Harga): Terlalu murah (< -30%) atau mahal (> +30%) dilihat dari SKU+Satuan, QTY, dan Kemasan.`n- Sisi 3 (Transaksi): Borongan >200 DUS, Struk >Rp 45 Jt, & Transaksi Hari Minggu." }
)

$cy = 185
foreach ($c in $cards) {
    Draw-Card $g1 1036 $cy 492 150 $c.Bg $c.Color 1.5 10
    $bTitleC = New-Object System.Drawing.SolidBrush (New-Color $c.Color)
    $g1.DrawString($c.Title, $fBold, $bTitleC, 1052, $cy + 12)
    $rectF = New-Object System.Drawing.RectangleF(1052, ($cy + 36), 460, 106)
    $g1.DrawString($c.Body, $fSm, $bDark, $rectF)
    $bTitleC.Dispose()
    $cy += 164
}

$bmp1.Save("$outDir\fig1_overview_pipeline.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g1.Dispose(); $bmp1.Dispose()
Write-Output "Saved fig1_overview_pipeline.png"

# ==============================================================================
# FIG 2: SISI 1A - OUTLIER PELANGGAN SECARA GRAFIS & STATISTIK (N = 180 OUTLET)
# ==============================================================================
$lrfm = Import-Csv "bersih\lrfm_pelanggan.csv"
$bmp2 = New-Object System.Drawing.Bitmap(1600, 900)
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g2.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g2.Clear((New-Color "#F8FAFC"))

Draw-Header $g2 "SISI 1A  |  DETEKSI OUTLIER PELANGGAN: GRAFIS & STATISTIK DESKRIPTIF (WEEK 5 SLIDE 4-8 & WEEK 7)" `
    "19 Pelanggan Melampaui Pagar IQR Monetary (Rp 41,9 Jt) & 7 Pembeli Sekali/Jarang Berbelanja Raksasa" `
    "Kiri: 1D Boxplot + Distribusi Monetary & AOV (IQR vs 3-Sigma)  |  Kanan: 2D Scatter & Convex Hull (Frequency vs Monetary, N = 180 Outlet)"

Draw-Card $g2 48 124 680 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g2 752 124 800 730 "#FFFFFF" "#E2E8F0" 1.5 12

# Left Panel: 1D Boxplot + Strip Plot on Log10(Monetary) and Log10(AOV)
$g2.DrawString("1D Boxplot & Pagar Statistik: Monetary (M) vs Nilai per Kunjungan (AOV)", $fSec, $bDark, 72, 144)
$g2.DrawString("Distribusi miring kanan (right-skewed): Pagar Q3 + 1.5*IQR jauh lebih sensitif daripada Mean + 3*SD", $fSubSec, $bMuted, 72, 170)

# Draw Boxplot 1: Total Monetary (M) in Juta Rp (Log scale axis from 0.05 Jt to 700 Jt)
function Map-LogX($valJuta, $xLeft, $xRight, $minLog, $maxLog) {
    $lg = [math]::Log10([math]::Max($valJuta, 0.05))
    return [float]($xLeft + (($lg - $minLog) / ($maxLog - $minLog)) * ($xRight - $xLeft))
}

$bxL = 90.0; $bxR = 690.0
$minLg = -1.3; $maxLg = 2.85 # 0.05 Jt to 700 Jt

# Boxplot 1 frame (Monetary M)
$by1 = 260.0
$g2.DrawString("A. Distribusi Total Belanja Pelanggan (Monetary - Juta Rp)", $fBold, $bDark, 74, 205)
$g2.DrawString("Q1=2,38 Jt | Med=5,99 Jt | Q3=18,20 Jt | Pagar 1.5*IQR = Rp 41,93 Jt (19 Outlier) | 3*SD = Rp 215,79 Jt (4 Outlier)", $fSm, $bMuted, 74, 225)

# Grid ticks for Monetary
$ticksM = @(0.1, 0.5, 1, 2.38, 5.99, 18.2, 41.9, 100, 215.8, 547.8)
$penGrid = New-Object System.Drawing.Pen ((New-Color "#E2E8F0"), 1.0)
foreach ($tk in $ticksM) {
    $tx = Map-LogX $tk $bxL $bxR $minLg $maxLg
    $g2.DrawLine($penGrid, $tx, ($by1 - 15), $tx, ($by1 + 95))
    $lbl = if ($tk -ge 10) { "{0:N0}" -f $tk } else { "{0:N1}" -f $tk }
    $g2.DrawString($lbl, $fSm, $bLight, ($tx - 14), ($by1 + 98))
}
$g2.DrawString("Skala Logaritmik Monetary (Juta Rp)", $fSmB, $bMuted, 310, ($by1 + 118))

# Shaded normal zone [Q1, Q3 + 1.5*IQR]
$xQ1_M = Map-LogX 2.3835 $bxL $bxR $minLg $maxLg
$xMed_M = Map-LogX 5.9892 $bxL $bxR $minLg $maxLg
$xQ3_M = Map-LogX 18.204 $bxL $bxR $minLg $maxLg
$xIQR_M = Map-LogX 41.935 $bxL $bxR $minLg $maxLg
$x3SD_M = Map-LogX 215.79 $bxL $bxR $minLg $maxLg
$xMin_M = Map-LogX 0.08 $bxL $bxR $minLg $maxLg

$bBox = New-Object System.Drawing.SolidBrush (New-Color "#BAE6FD" 160)
$pBox = New-Object System.Drawing.Pen ((New-Color "#0284C7"), 2.0)
$g2.FillRectangle($bBox, $xQ1_M, ($by1 + 5), ($xQ3_M - $xQ1_M), 36)
$g2.DrawRectangle($pBox, $xQ1_M, ($by1 + 5), ($xQ3_M - $xQ1_M), 36)
$pMed = New-Object System.Drawing.Pen ((New-Color "#0F172A"), 3.0)
$g2.DrawLine($pMed, $xMed_M, ($by1 + 5), $xMed_M, ($by1 + 41))
$g2.DrawLine($pBox, $xMin_M, ($by1 + 23), $xQ1_M, ($by1 + 23))
$g2.DrawLine($pBox, $xQ3_M, ($by1 + 23), $xIQR_M, ($by1 + 23))

# Threshold vertical lines
$pDashW = New-Object System.Drawing.Pen ((New-Color "#F59E0B"), 2.0)
$pDashW.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$pDashC = New-Object System.Drawing.Pen ((New-Color "#E11D48"), 2.0)
$pDashC.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g2.DrawLine($pDashW, $xIQR_M, ($by1 - 15), $xIQR_M, ($by1 + 95))
$g2.DrawLine($pDashC, $x3SD_M, ($by1 - 15), $x3SD_M, ($by1 + 95))

# Plot Strip points for M
$rnd = New-Object System.Random(42)
foreach ($c in $lrfm) {
    $mJt = [double]$c.M / 1e6
    $px = Map-LogX $mJt $bxL $bxR $minLg $maxLg
    $py = $by1 + 68 + ($rnd.NextDouble() - 0.5) * 28
    $col = if ($mJt -gt 215.79) { "#E11D48" } elseif ($mJt -gt 41.935) { "#F59E0B" } else { "#64748B" }
    $al  = if ($mJt -gt 41.935) { 230 } else { 110 }
    $sz  = if ($mJt -gt 41.935) { 8 } else { 5 }
    $br  = New-Object System.Drawing.SolidBrush (New-Color $col $al)
    $g2.FillEllipse($br, ($px - $sz/2), ($py - $sz/2), $sz, $sz)
    $br.Dispose()
}

# Boxplot 2: AOV (Rata-rata Omzet per Hari Kunjungan = M / F)
$by2 = 460.0
$minLg2 = -1.3; $maxLg2 = 2.0 # 0.05 Jt to 100 Jt
$g2.DrawString("B. Distribusi Rata-Rata Nilai Belanja per Kunjungan (AOV = M / F - Juta Rp)", $fBold, $bDark, 74, 405)
$g2.DrawString("Q1=0,75 Jt | Med=1,62 Jt | Q3=3,04 Jt | Pagar 1.5*IQR = Rp 6,48 Jt (18 Outlier) | 3*SD = Rp 22,68 Jt (3 Outlier)", $fSm, $bMuted, 74, 425)

$ticksA = @(0.1, 0.3, 0.75, 1.62, 3.04, 6.48, 12.15, 22.68, 38.25, 63.2)
foreach ($tk in $ticksA) {
    $tx = Map-LogX $tk $bxL $bxR $minLg2 $maxLg2
    $g2.DrawLine($penGrid, $tx, ($by2 - 15), $tx, ($by2 + 95))
    $lbl = if ($tk -ge 10) { "{0:N1}" -f $tk } else { "{0:N2}" -f $tk }
    $g2.DrawString($lbl, $fSm, $bLight, ($tx - 14), ($by2 + 98))
}
$g2.DrawString("Skala Logaritmik AOV = Monetary / Frequency (Juta Rp / Kunjungan)", $fSmB, $bMuted, 240, ($by2 + 118))

$xQ1_A = Map-LogX 0.749 $bxL $bxR $minLg2 $maxLg2
$xMed_A = Map-LogX 1.622 $bxL $bxR $minLg2 $maxLg2
$xQ3_A = Map-LogX 3.041 $bxL $bxR $minLg2 $maxLg2
$xIQR_A = Map-LogX 6.479 $bxL $bxR $minLg2 $maxLg2
$x3SD_A = Map-LogX 22.677 $bxL $bxR $minLg2 $maxLg2
$xMin_A = Map-LogX 0.058 $bxL $bxR $minLg2 $maxLg2

$g2.FillRectangle($bBox, $xQ1_A, ($by2 + 5), ($xQ3_A - $xQ1_A), 36)
$g2.DrawRectangle($pBox, $xQ1_A, ($by2 + 5), ($xQ3_A - $xQ1_A), 36)
$g2.DrawLine($pMed, $xMed_A, ($by2 + 5), $xMed_A, ($by2 + 41))
$g2.DrawLine($pBox, $xMin_A, ($by2 + 23), $xQ1_A, ($by2 + 23))
$g2.DrawLine($pBox, $xQ3_A, ($by2 + 23), $xIQR_A, ($by2 + 23))
$g2.DrawLine($pDashW, $xIQR_A, ($by2 - 15), $xIQR_A, ($by2 + 95))
$g2.DrawLine($pDashC, $x3SD_A, ($by2 - 15), $x3SD_A, ($by2 + 95))

foreach ($c in $lrfm) {
    $aovJt = ([double]$c.M / [double]$c.F) / 1e6
    $px = Map-LogX $aovJt $bxL $bxR $minLg2 $maxLg2
    $py = $by2 + 68 + ($rnd.NextDouble() - 0.5) * 28
    $col = if ($aovJt -gt 22.677) { "#E11D48" } elseif ($aovJt -gt 6.479) { "#F59E0B" } else { "#64748B" }
    $al  = if ($aovJt -gt 6.479) { 230 } else { 110 }
    $sz  = if ($aovJt -gt 6.479) { 8 } else { 5 }
    $br  = New-Object System.Drawing.SolidBrush (New-Color $col $al)
    $g2.FillEllipse($br, ($px - $sz/2), ($py - $sz/2), $sz, $sz)
    $br.Dispose()
}

# Summary Callout Box in Left Panel bottom
Draw-Card $g2 74 610 628 220 "#FFFBEB" "#F59E0B" 1.5 10
$bTitleW = New-Object System.Drawing.SolidBrush (New-Color "#B45309")
$g2.DrawString("TEMUAN KUNCI SISI 1A (DEFINISI ABNORMALITY KELOMPOK):", $fBold, $bTitleW, 92, 624)
$summaryS1A = "1. Global Whale Outliers (M > Mean + 3*SD = Rp 215,8 Jt):`n   - TOKO CITA RASA BARU (Rp 547,77 Jt, F=50), ADEK FROZEN (Rp 420,73 Jt, F=11), ANTON (Rp 311,76 Jt, F=28), HITE (Rp 229,86 Jt, F=13), serta AMANAH FROZEN (Frekuensi tertinggi F=80 hari, M=Rp 113,73 Jt).`n2. One-Shot / Rare Bulk Buyer Outliers (Sesuai Contoh Purchasing Dosen di Week 5 Slide 4):`n   - Pembeli datang hanya 1-2 kali (F <= 2) namun langsung memborong puluhan juta rupiah:`n   - PAK SUTARMUJI (F=2, M=Rp 126,40 Jt -> AOV Rp 63,20 Jt/kunjungan, tertinggi #1!), MAS ROHMAT (F=2, AOV Rp 27,51 Jt), YUDI (F=1, Rp 22,54 Jt), FRESH SUN SWALAYAN (F=1, Rp 18,00 Jt), DEFRIADI (F=1, Rp 12,15 Jt)."
$g2.DrawString($summaryS1A, $fSm, $bDark, (New-Object System.Drawing.RectangleF(92, 648, 595, 175)))
$bTitleW.Dispose()

# Right Panel: 2D Scatter Plot + Convex Hull (Frequency F vs Monetary M)
$g2.DrawString("2D Scatter Plot & Convex Hull: Frequency (Hari) vs Monetary (Juta Rp)", $fSec, $bDark, 776, 144)
$g2.DrawString("Poligon merah putus-putus = Convex Hull (Week 7: titik ekstrem terluar). Warna membedakan tipe outlier.", $fSubSec, $bMuted, 776, 170)

$scL = 835.0; $scR = 1515.0; $scT = 215.0; $scB = 755.0
function Map-ScX($fVal) { return [float]($scL + ($fVal / 85.0) * ($scR - $scL)) }
function Map-ScY($mValJt) { return [float]($scB - ($mValJt / 580.0) * ($scB - $scT)) }

# Grid lines
for ($fv = 0; $fv -le 80; $fv += 10) {
    $gx = Map-ScX $fv
    $g2.DrawLine($penGrid, $gx, $scT, $gx, $scB)
    $g2.DrawString("$fv", $fSm, $bLight, ($gx - 8), ($scB + 8))
}
for ($mv = 0; $mv -le 550; $mv += 100) {
    $gy = Map-ScY $mv
    $g2.DrawLine($penGrid, $scL, $gy, $scR, $gy)
    $g2.DrawString("$mv Jt", $fSm, $bLight, ($scL - 52), ($gy - 8))
}
$pAxis = New-Object System.Drawing.Pen ((New-Color "#334155"), 1.5)
$g2.DrawLine($pAxis, $scL, $scB, $scR, $scB)
$g2.DrawLine($pAxis, $scL, $scT, $scL, $scB)
$g2.DrawString("Frequency (Jumlah Hari Kunjungan Berbeda Selama 6 Bulan)", $fSmB, $bDark, 1015, ($scB + 32))

# IQR fence lines on Scatter (F = 17, M = 41.935 Jt)
$gxIQR = Map-ScX 17.0
$gyIQR = Map-ScY 41.935
$g2.DrawLine($pDashW, $gxIQR, $scT, $gxIQR, $scB)
$g2.DrawLine($pDashW, $scL, $gyIQR, $scR, $gyIQR)
$g2.DrawString("Batas 1.5*IQR F (17 hr)", $fSm, $bMuted, ($gxIQR + 4), ($scT + 6))
$g2.DrawString("Batas 1.5*IQR M (Rp 41,9 Jt)", $fSm, $bMuted, ($scR - 175), ($gyIQR - 18))

# Convex Hull vertices: (F=1, M=0.06), (F=2, M=126.4 PAK SUTARMUJI), (F=11, M=420.73 ADEK FROZEN), (F=50, M=547.77 TOKO CITA RASA BARU), (F=80, M=113.73 AMANAH FROZEN), (F=46, M=23.98 SUCI), (F=26, M=4.68 FADIL ANAK BOS)
$hullPts = @(
    (New-Object System.Drawing.PointF((Map-ScX 1), (Map-ScY 0.06))),
    (New-Object System.Drawing.PointF((Map-ScX 2), (Map-ScY 126.4))),
    (New-Object System.Drawing.PointF((Map-ScX 11), (Map-ScY 420.73))),
    (New-Object System.Drawing.PointF((Map-ScX 50), (Map-ScY 547.77))),
    (New-Object System.Drawing.PointF((Map-ScX 80), (Map-ScY 113.73))),
    (New-Object System.Drawing.PointF((Map-ScX 46), (Map-ScY 23.98))),
    (New-Object System.Drawing.PointF((Map-ScX 26), (Map-ScY 4.68)))
)
$bHull = New-Object System.Drawing.SolidBrush (New-Color "#FFE4E6" 55)
$pHull = New-Object System.Drawing.Pen ((New-Color "#E11D48" 160), 1.8)
$pHull.DashStyle = [System.Drawing.Drawing2D.DashStyle]::DashDot
$g2.FillPolygon($bHull, $hullPts)
$g2.DrawPolygon($pHull, $hullPts)

# Plot all 180 customers
foreach ($c in $lrfm) {
    $fv = [double]$c.F
    $mv = [double]$c.M / 1e6
    $aov = $mv / $fv
    $px = Map-ScX $fv
    $py = Map-ScY $mv
    $isWhale = ($mv -gt 110.0) -or ($fv -ge 45)
    $isBulkOnce = ($fv -le 2) -and ($mv -ge 12.0)
    $isFreqLowM = ($fv -ge 25) -and ($mv -lt 10.0)
    if ($isWhale) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 230)
        $g2.FillEllipse($br, ($px - 6), ($py - 6), 12, 12)
        $br.Dispose()
    } elseif ($isBulkOnce) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#D97706" 240)
        $g2.FillEllipse($br, ($px - 6), ($py - 6), 12, 12)
        $br.Dispose()
    } elseif ($isFreqLowM -or $mv -gt 41.935 -or $fv -gt 17) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#0284C7" 210)
        $g2.FillEllipse($br, ($px - 4.5), ($py - 4.5), 9, 9)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 130)
        $g2.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    }
}

# Direct Labels for key outliers on Scatter
$annotations2 = @(
    @{ F=50; M=547.77; Text="TOKO CITA RASA BARU (F=50, Rp 547,8 Jt)"; dx=-140; dy=-22; Col="#E11D48" },
    @{ F=11; M=420.73; Text="ADEK FROZEN (F=11, Rp 420,7 Jt)"; dx=10; dy=-8; Col="#E11D48" },
    @{ F=28; M=311.76; Text="ANTON (F=28, Rp 311,8 Jt)"; dx=10; dy=-8; Col="#E11D48" },
    @{ F=13; M=229.86; Text="HITE (F=13, Rp 229,9 Jt)"; dx=10; dy=-8; Col="#E11D48" },
    @{ F=27; M=182.69; Text="RUMAH SOSIS (F=27, Rp 182,7 Jt)"; dx=10; dy=-6; Col="#0284C7" },
    @{ F=80; M=113.73; Text="AMANAH FROZEN (F=80 hr, Rp 113,7 Jt)"; dx=-195; dy=-22; Col="#E11D48" },
    @{ F=2;  M=126.40; Text="PAK SUTARMUJI (F=2, Rp 126,4 Jt! [p2])"; dx=10; dy=-10; Col="#B45309" },
    @{ F=2;  M=55.02;  Text="MAS ROHMAT (F=2, Rp 55,0 Jt [p2])"; dx=10; dy=-8; Col="#B45309" },
    @{ F=1;  M=22.54;  Text="YUDI (F=1, Rp 22,5 Jt) & FRESH SUN (F=1, Rp 18 Jt)"; dx=10; dy=-14; Col="#B45309" },
    @{ F=26; M=4.68;   Text="FADIL ANAK BOS (F=26, Rp 4,7 Jt - Eceran)"; dx=10; dy=-18; Col="#0284C7" }
)
foreach ($a in $annotations2) {
    $px = Map-ScX $a.F
    $py = Map-ScY $a.M
    $bTxt = New-Object System.Drawing.SolidBrush (New-Color $a.Col)
    $g2.DrawString($a.Text, $fSmB, $bTxt, ($px + $a.dx), ($py + $a.dy))
    $bTxt.Dispose()
}

$bmp2.Save("$outDir\fig2_pelanggan_statistik_grafis.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g2.Dispose(); $bmp2.Dispose()
Write-Output "Saved fig2_pelanggan_statistik_grafis.png"

# ==============================================================================
# FIG 3: SISI 1B - DETEKSI OUTLIER PELANGGAN ML (LOF, k-NN, CLUSTERING - WEEK 7)
# ==============================================================================
$bmp3 = New-Object System.Drawing.Bitmap(1600, 900)
$g3 = [System.Drawing.Graphics]::FromImage($bmp3)
$g3.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g3.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g3.Clear((New-Color "#F8FAFC"))

Draw-Header $g3 "SISI 1B  |  DETEKSI OUTLIER PELANGGAN MULTIVARIAT & ML: k-NN, LOF, & CLUSTERING (MATERI WEEK 7)" `
    "Mengapa LOF & k-NN Unggul: Menangkap Global Whale (p1) Sekaligus One-Shot Bulk Buyers (p2)" `
    "Kiri: Peta Kepadatan LOF (Log Frequency vs Log AOV; Radius Lingkaran = Skor LOF)  |  Kanan: Top 12 Pelanggan Outlier Konsensus Multi-Metode"

Draw-Card $g3 48 124 820 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g3 892 124 660 730 "#FFFFFF" "#E2E8F0" 1.5 12

$g3.DrawString("Peta 2D Local Outlier Factor (LOF): Frekuensi vs Nilai Belanja per Kunjungan (AOV)", $fSec, $bDark, 72, 144)
$g3.DrawString("Sesuai Slide Week 7: Titik dengan radius cincin merah besar memiliki kepadatan lokal rendah (LOF > 1.25)", $fSubSec, $bMuted, 72, 170)

$p3L = 130.0; $p3R = 830.0; $p3T = 215.0; $p3B = 755.0
function Map-P3X($fVal) {
    $lg = [math]::Log10([math]::Max($fVal, 1.0))
    return [float]($p3L + ($lg / 1.95) * ($p3R - $p3L))
}
function Map-P3Y($aovJt) {
    $lg = [math]::Log10([math]::Max($aovJt, 0.04))
    return [float]($p3B - (($lg - (-1.4)) / (1.9 - (-1.4))) * ($p3B - $p3T))
}

# Grid for P3
$fTicks3 = @(1, 2, 3, 5, 10, 20, 40, 80)
foreach ($ft in $fTicks3) {
    $gx = Map-P3X $ft
    $g3.DrawLine($penGrid, $gx, $p3T, $gx, $p3B)
    $g3.DrawString("$ft hr", $fSm, $bLight, ($gx - 12), ($p3B + 8))
}
$aTicks3 = @(0.06, 0.15, 0.5, 1.62, 5.0, 15.0, 38.0, 63.2)
foreach ($at in $aTicks3) {
    $gy = Map-P3Y $at
    $g3.DrawLine($penGrid, $p3L, $gy, $p3R, $gy)
    $lbl = if ($at -ge 1) { "{0:N1} Jt" -f $at } else { "{0:N2} Jt" -f $at }
    $g3.DrawString($lbl, $fSm, $bLight, ($p3L - 62), ($gy - 8))
}
$g3.DrawLine($pAxis, $p3L, $p3B, $p3R, $p3B)
$g3.DrawLine($pAxis, $p3L, $p3T, $p3L, $p3B)
$g3.DrawString("Frequency Kunjungan (Skala Logaritmik - Hari Aktif)", $fSmB, $bDark, 330, ($p3B + 32))

# Shaded Core Cluster Zone (Normal Inliers)
$cZone = New-RoundedRect (Map-P3X 1.5) (Map-P3Y 5.5) ((Map-P3X 22) - (Map-P3X 1.5)) ((Map-P3Y 0.35) - (Map-P3Y 5.5)) 25
$bCore = New-Object System.Drawing.SolidBrush (New-Color "#E0F2FE" 75)
$pCore = New-Object System.Drawing.Pen ((New-Color "#38BDF8" 150), 1.5)
$pCore.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g3.FillPath($bCore, $cZone)
$g3.DrawPath($pCore, $cZone)
$g3.DrawString("ZONA KLASTER UTAMA (INLIERS: F=2..20 hr, AOV=Rp 0,4..5,5 Jt)", $fSmB, (New-Object System.Drawing.SolidBrush (New-Color "#0369A1")), 210, 412)

# Plot points & LOF rings
$topOutliers3 = @{
    "PAK SUTARMUJI"      = @{ LOF=1.495; KNN=1.667; Type="p2: Bulk Buyer (F=2, AOV Rp 63,2 Jt)"; Col="#E11D48"; dx=14; dy=-8 }
    "ADEK FROZEN"        = @{ LOF=1.181; KNN=1.236; Type="p1: Whale Grosir (AOV Rp 38,3 Jt)"; Col="#E11D48"; dx=12; dy=-8 }
    "MAS ROHMAT"         = @{ LOF=1.246; KNN=1.052; Type="p2: Bulk Buyer (F=2, AOV Rp 27,5 Jt)"; Col="#D97706"; dx=12; dy=-8 }
    "YUDI"               = @{ LOF=1.262; KNN=0.860; Type="p2: One-Shot (F=1, AOV Rp 22,5 Jt)"; Col="#D97706"; dx=12; dy=-10 }
    "FRESH SUN SWALAYAN" = @{ LOF=1.210; KNN=0.820; Type="p2: One-Shot (F=1, AOV Rp 18,0 Jt)"; Col="#D97706"; dx=12; dy=2 }
    "DEFRIADI"           = @{ LOF=1.454; KNN=1.701; Type="p2: One-Shot Churn (F=1, R=166, Rp 12,2 Jt)"; Col="#E11D48"; dx=12; dy=4 }
    "TOKO CITA RASA BARU"= @{ LOF=1.340; KNN=1.233; Type="p1: Top #1 Omzet (F=50, Rp 547,8 Jt)"; Col="#E11D48"; dx=-230; dy=-20 }
    "ANTON"              = @{ LOF=1.150; KNN=0.950; Type="p1: Top #3 Omzet (F=28, Rp 311,8 Jt)"; Col="#0284C7"; dx=-185; dy=8 }
    "AMANAH FROZEN"      = @{ LOF=1.219; KNN=0.996; Type="p1: Top #1 Frekuensi (F=80 hr)"; Col="#E11D48"; dx=-205; dy=10 }
    "FADIL ANAK BOS"     = @{ LOF=1.341; KNN=1.069; Type="p3: Eceran Sering (F=26, AOV Rp 180rb)"; Col="#0284C7"; dx=-130; dy=12 }
    "KAK YENI"           = @{ LOF=1.609; KNN=1.657; Type="p3: LOF #1 Mikro (F=5, AOV Rp 58rb)"; Col="#E11D48"; dx=12; dy=-8 }
    "OKE MART"           = @{ LOF=1.545; KNN=1.139; Type="p2: LOF #3 Churn Besar (F=3, R=117)"; Col="#D97706"; dx=12; dy=-8 }
}

foreach ($c in $lrfm) {
    $p = $c.PELANGGAN
    $fv = [double]$c.F
    $aov = ([double]$c.M / $fv) / 1e6
    $px = Map-P3X $fv
    $py = Map-P3Y $aov
    if ($topOutliers3.ContainsKey($p)) {
        $info = $topOutliers3[$p]
        $ringR = [float](($info.LOF - 0.95) * 36.0)
        $pRing = New-Object System.Drawing.Pen ((New-Color $info.Col 180), 2.0)
        $bRing = New-Object System.Drawing.SolidBrush (New-Color $info.Col 35)
        $g3.FillEllipse($bRing, ($px - $ringR/2), ($py - $ringR/2), $ringR, $ringR)
        $g3.DrawEllipse($pRing, ($px - $ringR/2), ($py - $ringR/2), $ringR, $ringR)
        $bDot = New-Object System.Drawing.SolidBrush (New-Color $info.Col 255)
        $g3.FillEllipse($bDot, ($px - 5), ($py - 5), 10, 10)
        $g3.DrawString($info.Type, $fSmB, $bDot, ($px + $info.dx), ($py + $info.dy))
        $pRing.Dispose(); $bRing.Dispose(); $bDot.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 120)
        $g3.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    }
}

# Right Panel: Table / Ranking of Top 12 Consensus Customer Outliers
$g3.DrawString("Peringkat 12 Pelanggan Outlier Utama (Konsensus Statistik & ML)", $fSec, $bDark, 914, 144)
$g3.DrawString("Menggabungkan bukti IQR/3-Sigma (Week 5), k-NN Distance, LOF, & Klaster (Week 7)", $fSubSec, $bMuted, 914, 170)

$rankCust = @(
    @{ Name="1. TOKO CITA RASA BARU"; F="50"; M="547,77 Jt"; AOV="10,96 Jt"; KNN="1,23"; LOF="1,34"; Role="Whale #1 Omzet (>3 SD)"; Col="#E11D48" },
    @{ Name="2. PAK SUTARMUJI";       F="2";  M="126,40 Jt"; AOV="63,20 Jt"; KNN="1,67"; LOF="1,50"; Role="Bulk Buyer #1 AOV (>3 SD)"; Col="#E11D48" },
    @{ Name="3. ADEK FROZEN";         F="11"; M="420,73 Jt"; AOV="38,25 Jt"; KNN="1,24"; LOF="1,18"; Role="Whale #2 Omzet & AOV (>3 SD)"; Col="#E11D48" },
    @{ Name="4. DEFRIADI";            F="1";  M="12,15 Jt";  AOV="12,15 Jt"; KNN="1,70"; LOF="1,45"; Role="k-NN #1 One-Shot + Churn"; Col="#E11D48" },
    @{ Name="5. KAK YENI";            F="5";  M="0,29 Jt";   AOV="0,06 Jt";  KNN="1,66"; LOF="1,61"; Role="LOF #1 Anomali Nilai Mikro"; Col="#D97706" },
    @{ Name="6. ANTON";               F="28"; M="311,76 Jt"; AOV="11,13 Jt"; KNN="0,95"; LOF="1,15"; Role="Whale #3 Omzet (>3 SD)"; Col="#E11D48" },
    @{ Name="7. HITE";                F="13"; M="229,86 Jt"; AOV="17,68 Jt"; KNN="0,92"; LOF="1,14"; Role="Whale #4 Omzet (>3 SD)"; Col="#E11D48" },
    @{ Name="8. MAS ROHMAT";          F="2";  M="55,02 Jt";  AOV="27,51 Jt"; KNN="1,05"; LOF="1,25"; Role="Bulk Buyer #2 AOV (>3 SD)"; Col="#D97706" },
    @{ Name="9. AMANAH FROZEN";       F="80"; M="113,73 Jt"; AOV="1,42 Jt";  KNN="1,00"; LOF="1,22"; Role="Outlier Frekuensi #1 (80 hr)"; Col="#0284C7" },
    @{ Name="10. OKE MART";           F="3";  M="18,99 Jt";  AOV="6,33 Jt";  KNN="1,14"; LOF="1,55"; Role="LOF #3 Bulk Churn Mendadak"; Col="#D97706" },
    @{ Name="11. YUDI";               F="1";  M="22,54 Jt";  AOV="22,54 Jt"; KNN="0,86"; LOF="1,26"; Role="One-Shot Bulk Buyer (F=1)"; Col="#D97706" },
    @{ Name="12. FADIL ANAK BOS";     F="26"; M="4,68 Jt";   AOV="0,18 Jt";  KNN="1,07"; LOF="1,34"; Role="Eceran Sering + Harga Miring"; Col="#0284C7" }
)

# Table Header
$ty = 208
$bHdr = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
$g3.FillRectangle($bHdr, 912, $ty, 620, 30)
$bWhite = New-Object System.Drawing.SolidBrush (New-Color "#FFFFFF")
$g3.DrawString("Pelanggan", $fSmB, $bWhite, 918, ($ty + 6))
$g3.DrawString("F", $fSmB, $bWhite, 1088, ($ty + 6))
$g3.DrawString("Omzet (M)", $fSmB, $bWhite, 1118, ($ty + 6))
$g3.DrawString("AOV", $fSmB, $bWhite, 1192, ($ty + 6))
$g3.DrawString("k-NN", $fSmB, $bWhite, 1254, ($ty + 6))
$g3.DrawString("LOF", $fSmB, $bWhite, 1298, ($ty + 6))
$g3.DrawString("Diagnosis Abnormality", $fSmB, $bWhite, 1342, ($ty + 6))

$ty += 34
for ($i = 0; $i -lt $rankCust.Count; $i++) {
    $rc = $rankCust[$i]
    if ($i % 2 -eq 0) {
        $bAlt = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC")
        $g3.FillRectangle($bAlt, 912, ($ty - 2), 620, 36)
        $bAlt.Dispose()
    }
    $bCol = New-Object System.Drawing.SolidBrush (New-Color $rc.Col)
    $g3.DrawString($rc.Name, $fSmB, $bDark, 916, ($ty + 6))
    $g3.DrawString($rc.F, $fSm, $bDark, 1088, ($ty + 6))
    $g3.DrawString($rc.M, $fSmB, $bDark, 1118, ($ty + 6))
    $g3.DrawString($rc.AOV, $fSm, $bDark, 1192, ($ty + 6))
    $g3.DrawString($rc.KNN, $fSm, $bDark, 1254, ($ty + 6))
    $g3.DrawString($rc.LOF, $fSmB, $bCol, 1298, ($ty + 6))
    $g3.DrawString($rc.Role, $fSmB, $bCol, 1342, ($ty + 6))
    $bCol.Dispose()
    $ty += 37
}

Draw-Card $g3 912 695 620 140 "#F0F9FF" "#0284C7" 1.5 10
$g3.DrawString("IMPLIKASI BISNIS & MANAJEMEN PELANGGAN:", $fBold, (New-Object System.Drawing.SolidBrush (New-Color "#0369A1")), 928, 708)
$imp3 = "- Kelompok Whale (p1: Toko Cita Rasa Baru, Adek Frozen, Anton, Hite) menyumbang >32% total omzet toko -> wajib diberikan Account Manager & kontrak kredit khusus.`n- Kelompok One-Shot Bulk (p2: Pak Sutarmuji Rp 126,4 Jt, Mas Rohmat Rp 55 Jt, Yudi Rp 22,5 Jt) adalah pembeli partai besar insidental (sub-distributor/hajatan) -> prospek utama untuk dikonversi menjadi pelanggan kontrak rutin!`n- Entitas CASH (walk-in agregat) dipisahkan dari LRFM agar tidak mendistorsi rata-rata."
$g3.DrawString($imp3, $fSm, $bDark, (New-Object System.Drawing.RectangleF(928, 732, 592, 98)))

$bmp3.Save("$outDir\fig3_pelanggan_ml_lof_knn.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g3.Dispose(); $bmp3.Dispose()
Write-Output "Saved fig3_pelanggan_ml_lof_knn.png"

# ==============================================================================
# FIG 4: SISI 2 - DETEKSI HARGA BARANG YANG OUTLIER (DILIHAT DARI KONTEKS X)
# ==============================================================================
$bmp4 = New-Object System.Drawing.Bitmap(1600, 900)
$g4 = [System.Drawing.Graphics]::FromImage($bmp4)
$g4.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g4.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g4.Clear((New-Color "#F8FAFC"))

Draw-Header $g4 "SISI 2  |  DETEKSI HARGA BARANG YANG OUTLIER: TERLALU MURAH ATAU TERLALU MAHAL DILIHAT DARI X" `
    "11 Transaksi Menyimpang Ekstrem (>30% dari Median SKU+Satuan) & 56 Transaksi Melampaui Pagar Satuan DUS" `
    "Kiri: Konteks X1 = SKU + Satuan Kemasan & X2 = QTY (Deviasi Harga Efektif vs Median)  |  Kanan: Konteks X3 = Kategori Satuan Kemasan (DUS..BKS)"

Draw-Card $g4 48 124 850 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g4 922 124 630 730 "#FFFFFF" "#E2E8F0" 1.5 12

$g4.DrawString("Konteks X1 & X2: Penyimpangan Harga Efektif (%) Terhadap Median SKU + Satuan", $fSec, $bDark, 72, 144)
$g4.DrawString("Zona hijau [-20%, +20%] = variasi diskon/tier wajar; di luar [-30%, +30%] = Outlier Harga Kritis (S01 & A02)", $fSubSec, $bMuted, 72, 170)

# Diverging Horizontal Bar / Lollipop Chart of Price Deviations
$priceOutliers = @(
    @{ Label="MIT-005 (PACK) | Pak Erwin (3 tx, QTY 6-27)"; Harga="Rp 14.450*"; Med="Rp 28.900"; Dev=-50.0; Cat="Terlalu Murah (Diskon A02 -50%)"; Col="#E11D48" },
    @{ Label="MIT-013 (PACK) | Pak Erwin (1 tx, QTY 51)";   Harga="Rp 4.950*";  Med="Rp 9.900";  Dev=-50.0; Cat="Terlalu Murah (Diskon A02 -50%)"; Col="#E11D48" },
    @{ Label="LUTOSA-001 (PACK) | Fadil Anak Bos (3 tx, QTY 1-2)"; Harga="Rp 15.000"; Med="Rp 26.000"; Dev=-42.3; Cat="Terlalu Murah (S01: -42,3%)"; Col="#E11D48" },
    @{ Label="DEN-002 (PACK) | Toko Cita Rasa Baru (QTY 27)"; Harga="Rp 4.000"; Med="Rp 6.000"; Dev=-33.3; Cat="Terlalu Murah (S01: -33,3%)"; Col="#E11D48" },
    @{ Label="MIT-004 (PACK) | Adek Frozen (QTY 10)"; Harga="Rp 11.500"; Med="Rp 14.900"; Dev=-22.8; Cat="Murah Statistik (S02: |Z|>5)"; Col="#F59E0B" },
    @{ Label="MIN-002 (DUS) | Kubang Jaya Food (QTY 1)"; Harga="Rp 230.384"; Med="Rp 290.000"; Dev=-20.6; Cat="Murah Statistik (S02: |Z|>5)"; Col="#F59E0B" },
    @{ Label="MIT-009 (PACK) | Adek Frozen (2 tx, QTY 5)"; Harga="Rp 20.000"; Med="Rp 23.400"; Dev=-14.5; Cat="Diskon Tier Grosir (S02)"; Col="#F59E0B" },
    @{ Label="FOODY-001 (DUS) | Adek Frozen (QTY 2)"; Harga="Rp 285.000"; Med="Rp 330.000"; Dev=-13.6; Cat="Diskon Tier Grosir (S02)"; Col="#F59E0B" },
    @{ Label="FINNA-001 (DUS) | 4 Transaksi (QTY 1-5)"; Harga="Rp 362.916"; Med="Rp 324.000"; Dev=12.0; Cat="Mahal Statistik (S02: |Z|>5)"; Col="#F59E0B" },
    @{ Label="MIT-008 (PACK) | 3 Transaksi (QTY 5-20)"; Harga="Rp 32.000"; Med="Rp 28.000"; Dev=14.3; Cat="Mahal Statistik (S02: |Z|>5)"; Col="#F59E0B" },
    @{ Label="CHA-001 (PACK) | 2 Transaksi (QTY 2-4)"; Harga="Rp 30.000"; Med="Rp 25.500"; Dev=17.6; Cat="Mahal Statistik (S02: |Z|>5)"; Col="#F59E0B" },
    @{ Label="SHIF-003 (DUS) | Anjani Frozen Food (QTY 2)"; Harga="Rp 262.500"; Med="Rp 201.020"; Dev=30.6; Cat="Terlalu Mahal (S01: +30,6%)"; Col="#E11D48" },
    @{ Label="DEN-011 (PACK) | CASH Walk-in (QTY 6)"; Harga="Rp 6.000"; Med="Rp 4.500"; Dev=33.3; Cat="Terlalu Mahal (S01: +33,3%)"; Col="#E11D48" },
    @{ Label="CONE-004 (BKS) | CASH Walk-in (QTY 2)"; Harga="Rp 7.000"; Med="Rp 5.000"; Dev=40.0; Cat="Terlalu Mahal (S01: +40,0%)"; Col="#E11D48" }
)

$dvZeroX = 560.0
$dvScale = 2.4 # 1% = 2.4 px -> -50% = -120px (440), +50% = +120px (680)
$dvTop = 215.0; $dvBot = 755.0

# Shaded Normal Zone [-30%, +30%]
$xM30 = [float]($dvZeroX - 30.0 * $dvScale)
$xP30 = [float]($dvZeroX + 30.0 * $dvScale)
$bNorm4 = New-Object System.Drawing.SolidBrush (New-Color "#ECFDF5" 140)
$g4.FillRectangle($bNorm4, $xM30, $dvTop, ($xP30 - $xM30), ($dvBot - $dvTop))

# Grid lines at -50, -30, 0, +30, +50
foreach ($pct in @(-50, -30, 0, 30, 50)) {
    $gx = [float]($dvZeroX + $pct * $dvScale)
    $penG = if ($pct -eq 0) { $pAxis } elseif ([math]::Abs($pct) -eq 30) { $pDashC } else { $penGrid }
    $g4.DrawLine($penG, $gx, $dvTop, $gx, $dvBot)
    $lbl = if ($pct -gt 0) { "+$pct%" } else { "$pct%" }
    $g4.DrawString($lbl, $fSmB, $bMuted, ($gx - 16), ($dvBot + 8))
}
$g4.DrawString("Deviasi Harga terhadap Median SKU + Satuan yang Sama (%)", $fSmB, $bDark, 395, ($dvBot + 30))

$rowH4 = 38.0
for ($i = 0; $i -lt $priceOutliers.Count; $i++) {
    $po = $priceOutliers[$i]
    $ry = $dvTop + 8 + $i * $rowH4
    if ($i % 2 -eq 0) {
        $bAlt = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC" 160)
        $g4.FillRectangle($bAlt, 68, ($ry - 3), 810, ($rowH4 - 2))
        $bAlt.Dispose()
    }
    $g4.DrawString($po.Label, $fSmB, $bDark, 72, ($ry - 2))
    $g4.DrawString("Harga: $($po.Harga) vs Median: $($po.Med)", $fSm, $bMuted, 72, ($ry + 14))

    $endX = [float]($dvZeroX + $po.Dev * $dvScale)
    $pStem = New-Object System.Drawing.Pen ((New-Color $po.Col), 3.0)
    $bDot  = New-Object System.Drawing.SolidBrush (New-Color $po.Col)
    $g4.DrawLine($pStem, $dvZeroX, ($ry + 14), $endX, ($ry + 14))
    $g4.FillEllipse($bDot, ($endX - 5), ($ry + 9), 10, 10)

    $devStr = if ($po.Dev -gt 0) { "+{0:N1}%" -f $po.Dev } else { "{0:N1}%" -f $po.Dev }
    $txtX = if ($po.Dev -lt 0) { $endX - 46 } else { $endX + 8 }
    $g4.DrawString($devStr, $fSmB, $bDot, $txtX, ($ry + 5))

    $g4.DrawString($po.Cat, $fSm, $bDot, 705, ($ry + 5))
    $pStem.Dispose(); $bDot.Dispose()
}

# Right Panel: Konteks X3 (Satuan Kemasan & SKU Premium) + Ringkasan 3 Perspektif X
$g4.DrawString("Konteks X3: Distribusi Harga Menurut Satuan Kemasan & SKU Premium", $fSec, $bDark, 944, 144)
$g4.DrawString("Mengapa X wajib ditetapkan: Harga Rp 240.000 normal untuk DUS, tetapi outlier ekstrem untuk PACK!", $fSubSec, $bMuted, 944, 170)

$satStats = @(
    @{ Sat="DUS (n=2.662)";  Med="Rp 240.000"; IQR_Range="Rp 210rb - 325rb"; Outlier="EURIAL Mozzarella Rp 960rb-1 Jt & BF Dimsum Rp 825,6rb (56 baris > Pagar Rp 573rb)"; Col="#0284C7" },
    @{ Sat="BAL (n=160)";    Med="Rp 260.000"; IQR_Range="Rp 260rb - 270rb"; Outlier="PK Lolipop Crispy Rp 345.000 & Kei Donut Rp 230.000 (Kemasan Karung Grosir)"; Col="#0284C7" },
    @{ Sat="JRG (n=11)";     Med="Rp 145.000"; IQR_Range="Rp 142,5rb - 145rb"; Outlier="Monopoli Delmonte Saus Jerigen 5,7 Kg (Harga sangat stabil, CV < 2%)"; Col="#10B981" },
    @{ Sat="PAIL (n=514)";   Med="Rp 125.000"; IQR_Range="Rp 120rb - 130rb"; Outlier="Diamond Ice Cream 8 Lt Rp 165rb-185rb vs Miami Reguler Rp 125rb"; Col="#0284C7" },
    @{ Sat="PACK (n=3.022)"; Med="Rp 18.000";  IQR_Range="Rp 13rb - 26rb";   Outlier="Murah: LUTOSA-001 Rp 15rb (-42%) & DEN-002 Rp 4rb (-33%); Mahal: Bakso Sapi Rp 65rb"; Col="#E11D48" },
    @{ Sat="BKS (n=296)";    Med="Rp 15.000";  IQR_Range="Rp 5rb - 15rb";    Outlier="Outlier Mahal: CONE-004 dijual Rp 7.000 vs Median Rp 5.000 (+40,0% pada CASH)"; Col="#E11D48" },
    @{ Sat="PCS (n=75)";     Med="Rp 8.500";   IQR_Range="Rp 8,5rb - 14rb";  Outlier="Jamur Enoki Rp 8.500 vs Tortila Besar Rp 29.000"; Col="#F59E0B" }
)

$sy4 = 210
foreach ($st in $satStats) {
    Draw-Card $g4 944 $sy4 586 68 "#F8FAFC" "#CBD5E1" 1.2 8
    $bC4 = New-Object System.Drawing.SolidBrush (New-Color $st.Col)
    $g4.DrawString("$($st.Sat)  |  Median: $($st.Med)  (Q1-Q3: $($st.IQR_Range))", $fSmB, $bC4, 958, ($sy4 + 8))
    $g4.DrawString("- Temuan Outlier: $($st.Outlier)", $fSm, $bDark, 958, ($sy4 + 32))
    $bC4.Dispose()
    $sy4 += 76
}

Draw-Card $g4 944 746 586 92 "#FFF1F2" "#E11D48" 1.5 10
$g4.DrawString("KESIMPULAN SISI 2 (TIGA DEFINISI KONTEKS 'X' HARGA OUTLIER):", $fSmB, (New-Object System.Drawing.SolidBrush (New-Color "#BE123C")), 960, 756)
$sum4 = "1. X = SKU + Satuan: 7 baris menyimpang >30% (S01: 4 terlalu murah pada LUTOSA-001 & DEN-002; 3 terlalu mahal pada CONE-004, DEN-011, SHIF-003) + 26 baris |Z_robust| > 5 (S02).`n2. X = Kuantitas (QTY) & Aritmetika: 4 baris diskon ekstrem -50% (A02: Pak Erwin) + 20 baris CASH lupa input harga Rp 0 pada QTY hingga 106 DUS (K03a).`n3. X = Kategori Satuan: 56 transaksi keju/dimsum premium > Pagar IQR Satuan DUS (Rp 573.000)."
$g4.DrawString($sum4, $fSm, $bDark, (New-Object System.Drawing.RectangleF(960, 774, 560, 62)))

$bmp4.Save("$outDir\fig4_harga_outlier_konteks_x.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g4.Dispose(); $bmp4.Dispose()
Write-Output "Saved fig4_harga_outlier_konteks_x.png"

# ==============================================================================
# FIG 5: SISI 3A & 3B - DETEKSI TRANSAKSI & KERANJANG NOTA OUTLIER (ITEM & STRUK)
# ==============================================================================
$df = Import-Csv "bersih\penjualan_bersih.csv"
$bmp5 = New-Object System.Drawing.Bitmap(1600, 900)
$g5 = [System.Drawing.Graphics]::FromImage($bmp5)
$g5.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g5.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g5.Clear((New-Color "#F8FAFC"))

Draw-Header $g5 "SISI 3A & 3B  |  DETEKSI TRANSAKSI YANG OUTLIER: LEVEL BARIS ITEM (N = 6.740) & LEVEL STRUK NOTA (N = 1.495)" `
    "208 Baris Melampaui Pagar Log-IQR (Rp 5,62 Jt), 2 Baris > Pagar Ekstrem 3*IQR (Rp 63,2 Jt), & 34 Struk > 3*SD" `
    "Kiri: 2D Scatter QTY vs OMZET per Baris Item (Skala Log)  |  Kanan: Multivariat Keranjang Struk Harian (Jumlah Item SKU vs Total Omzet Struk)"

Draw-Card $g5 48 124 760 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g5 832 124 720 730 "#FFFFFF" "#E2E8F0" 1.5 12

# Left Panel: Scatter Log10(QTY) vs Log10(OMZET in Juta Rp)
$g5.DrawString("Level Baris Transaksi (N = 6.740): Kuantitas (QTY) vs Nilai Baris (OMZET)", $fSec, $bDark, 72, 144)
$g5.DrawString("Pagar Log-IQR (1.5x) = Rp 5,62 Jt (208 baris)  |  Pagar Ekstrem (3.0x IQR / S04) = Rp 54,9 Jt (2 baris)", $fSubSec, $bMuted, 72, 170)

$p5L = 130.0; $p5R = 770.0; $p5T = 215.0; $p5B = 755.0
function Map-P5X($qtyVal) {
    $lg = [math]::Log10([math]::Max($qtyVal, 1.0))
    return [float]($p5L + ($lg / 2.65) * ($p5R - $p5L)) # 1 to 450
}
function Map-P5Y($omzVal) {
    $lg = [math]::Log10([math]::Max($omzVal, 3000.0))
    return [float]($p5B - (($lg - 3.4) / (7.9 - 3.4)) * ($p5B - $p5T)) # Rp 3rb to Rp 80 Jt
}

foreach ($qt in @(1, 2, 5, 10, 25, 50, 100, 200, 400)) {
    $gx = Map-P5X $qt
    $g5.DrawLine($penGrid, $gx, $p5T, $gx, $p5B)
    $g5.DrawString("$qt", $fSm, $bLight, ($gx - 10), ($p5B + 8))
}
$omzTicks = @(
    @{ V=10000; L="10rb" }, @{ V=100000; L="100rb" }, @{ V=240000; L="240rb (Med)" },
    @{ V=1000000; L="1 Jt" }, @{ V=5620000; L="5,6 Jt (1.5 IQR)" },
    @{ V=20000000; L="20 Jt" }, @{ V=54907000; L="54,9 Jt (3 IQR)" }
)
foreach ($ot in $omzTicks) {
    $gy = Map-P5Y $ot.V
    $g5.DrawLine($penGrid, $p5L, $gy, $p5R, $gy)
    $g5.DrawString($ot.L, $fSm, $bLight, ($p5L - 82), ($gy - 8))
}
$g5.DrawLine($pAxis, $p5L, $p5B, $p5R, $p5B)
$g5.DrawLine($pAxis, $p5L, $p5T, $p5L, $p5B)
$g5.DrawString("Kuantitas per Baris Transaksi - QTY (Skala Logaritmik)", $fSmB, $bDark, 280, ($p5B + 32))

# Threshold lines on P5
$gy15IQR = Map-P5Y 5623413
$gy30IQR = Map-P5Y 54907061
$gx3SDQ  = Map-P5X 47.8
$g5.DrawLine($pDashW, $p5L, $gy15IQR, $p5R, $gy15IQR)
$g5.DrawLine($pDashC, $p5L, $gy30IQR, $p5R, $gy30IQR)
$g5.DrawLine($pDashW, $gx3SDQ, $p5T, $gx3SDQ, $p5B)

# Plot sample of inliers + all outliers so rendering is super fast & crisp
$step = 0
foreach ($r in $df) {
    $step++
    $qv = [double]$r.QTY
    $ov = [double]$r.OMZET
    $isExt = ($ov -ge 18000000) -or ($qv -ge 150)
    $isMod = ($ov -ge 5623413) -or ($qv -ge 47.8)
    if (-not $isExt -and -not $isMod -and ($step % 4 -ne 0)) { continue }
    $px = Map-P5X $qv
    $py = Map-P5Y $ov
    if ($isExt) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 235)
        $g5.FillEllipse($br, ($px - 5.5), ($py - 5.5), 11, 11)
        $br.Dispose()
    } elseif ($isMod) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#F59E0B" 190)
        $g5.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 70)
        $g5.FillEllipse($br, ($px - 2.5), ($py - 2.5), 5, 5)
        $br.Dispose()
    }
}

$txLabels = @(
    @{ Q=200; O=63200000; Text="PAK SUTARMUJI: 2x 200 DUS Minaku Otak2 = Rp 63,2 Jt/tx (S04 #1 & #2)"; dx=-340; dy=-20; Col="#E11D48" },
    @{ Q=150; O=45750000; Text="MAS ROHMAT: 150 DUS Minaku = Rp 45,75 Jt"; dx=-245; dy=-8; Col="#E11D48" },
    @{ Q=120; O=36480000; Text="KUBANG JAYA: 120 DUS Minaku = Rp 36,48 Jt"; dx=-245; dy=-8; Col="#E11D48" },
    @{ Q=106; O=25440000; Text="CASH (K03a Dipulihkan): 106 DUS Lutosa = Rp 25,44 Jt"; dx=-285; dy=8; Col="#D97706" },
    @{ Q=25;  O=22000000; Text="ANTON: 25 DUS Keju Eurial = Rp 22,0 Jt"; dx=-245; dy=-18; Col="#0284C7" },
    @{ Q=400; O=3600000;  Text="ANTON: 400 PACK Bakso Mie (QTY #1 = Rp 3,6 Jt)"; dx=-255; dy=-18; Col="#E11D48" },
    @{ Q=240; O=3600000;  Text="EGI/PUTRI: 240 PACK Bakso Ikan"; dx=-175; dy=8; Col="#D97706" }
)
foreach ($tl in $txLabels) {
    $px = Map-P5X $tl.Q
    $py = Map-P5Y $tl.O
    $bT = New-Object System.Drawing.SolidBrush (New-Color $tl.Col)
    $g5.DrawString($tl.Text, $fSmB, $bT, ($px + $tl.dx), ($py + $tl.dy))
    $bT.Dispose()
}

# Right Panel: Basket / Invoice Level Outliers (TGL + PELANGGAN, N = 1.495 Baskets)
$g5.DrawString("Level Keranjang Nota (N = 1.495 Struk Harian): Jumlah Item vs Total Nota", $fSec, $bDark, 856, 144)
$g5.DrawString("Mendeteksi 2 pola struk outlier: Single-SKU Mega Order (1 item = Rp 63,2 Jt) vs Multi-SKU Hyper Basket (39 item)", $fSubSec, $bMuted, 856, 170)

$b5L = 910.0; $b5R = 1515.0; $b5T = 215.0; $b5B = 595.0
function Map-B5X($nItems) { return [float]($b5L + ($nItems / 42.0) * ($b5R - $b5L)) }
function Map-B5Y($totJt)  { return [float]($b5B - ($totJt / 68.0) * ($b5B - $b5T)) }

for ($ni = 0; $ni -le 40; $ni += 5) {
    $gx = Map-B5X $ni
    $g5.DrawLine($penGrid, $gx, $b5T, $gx, $b5B)
    $g5.DrawString("$ni", $fSm, $bLight, ($gx - 6), ($b5B + 6))
}
for ($oj = 0; $oj -le 65; $oj += 10) {
    $gy = Map-B5Y $oj
    $g5.DrawLine($penGrid, $b5L, $gy, $b5R, $gy)
    $g5.DrawString("$oj Jt", $fSm, $bLight, ($b5L - 44), ($gy - 8))
}
$g5.DrawLine($pAxis, $b5L, $b5B, $b5R, $b5B)
$g5.DrawLine($pAxis, $b5L, $b5T, $b5L, $b5B)
$g5.DrawString("Jumlah Variasi Item Barang per Struk Nota Harian (TGL + PELANGGAN)", $fSmB, $bDark, 980, ($b5B + 28))

# Threshold lines on Basket plot: Omzet > 21.46 Jt (3*SD), Items > 13.5 (1.5*IQR)
$gyB3SD = Map-B5Y 21.46
$gxBIQR = Map-B5X 13.5
$g5.DrawLine($pDashC, $b5L, $gyB3SD, $b5R, $gyB3SD)
$g5.DrawLine($pDashW, $gxBIQR, $b5T, $gxBIQR, $b5B)
$g5.DrawString("Pagar 3*SD Nota (Rp 21,5 Jt - 34 Struk Outlier)", $fSm, (New-Object System.Drawing.SolidBrush (New-Color "#E11D48")), ($b5R - 260), ($gyB3SD - 18))

$baskets = $df | Group-Object TGL, PELANGGAN | ForEach-Object {
    $items = $_.Group
    $tot_omzet = ($items | ForEach-Object { [double]$_.OMZET } | Measure-Object -Sum).Sum
    [PSCustomObject]@{ Key = $_.Name; N_Items = $items.Count; Tot_Jt = $tot_omzet / 1e6 }
}

foreach ($bs in $baskets) {
    $px = Map-B5X $bs.N_Items
    $py = Map-B5Y $bs.Tot_Jt
    $isBig = ($bs.Tot_Jt -ge 21.46) -or ($bs.N_Items -ge 25)
    $isMid = ($bs.Tot_Jt -ge 6.385) -or ($bs.N_Items -ge 14)
    if ($isBig) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 230)
        $g5.FillEllipse($br, ($px - 5.5), ($py - 5.5), 11, 11)
        $br.Dispose()
    } elseif ($isMid) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#F59E0B" 180)
        $g5.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 90)
        $g5.FillEllipse($br, ($px - 2.5), ($py - 2.5), 5, 5)
        $br.Dispose()
    }
}

$bLabels = @(
    @{ X=1;  Y=63.20; Text="PAK SUTARMUJI (3 & 13 Agu): 1 Item = Rp 63,2 Jt!"; dx=10; dy=-6; Col="#E11D48" },
    @{ X=1;  Y=45.75; Text="MAS ROHMAT (3 Agu): 1 Item = Rp 45,8 Jt"; dx=10; dy=-6; Col="#E11D48" },
    @{ X=26; Y=58.78; Text="ADEK FROZEN (29 Jul): 26 Item = Rp 58,8 Jt"; dx=-120; dy=-20; Col="#E11D48" },
    @{ X=35; Y=48.64; Text="ADEK FROZEN (26 Jun): 35 Item = Rp 48,6 Jt"; dx=-180; dy=-18; Col="#E11D48" },
    @{ X=39; Y=45.75; Text="ADEK FROZEN (3 Jun): 39 Item = Rp 45,7 Jt"; dx=-210; dy=8; Col="#E11D48" }
)
foreach ($bl in $bLabels) {
    $px = Map-B5X $bl.X
    $py = Map-B5Y $bl.Y
    $bT = New-Object System.Drawing.SolidBrush (New-Color $bl.Col)
    $g5.DrawString($bl.Text, $fSmB, $bT, ($px + $bl.dx), ($py + $bl.dy))
    $bT.Dispose()
}

Draw-Card $g5 856 642 672 194 "#F0F9FF" "#0284C7" 1.5 10
$g5.DrawString("RINGKASAN DEFINISI TRANSAKSI OUTLIER (SISI 3A & 3B):", $fBold, (New-Object System.Drawing.SolidBrush (New-Color "#0369A1")), 872, 654)
$sum5 = "1. Outlier Nilai Baris (Log-IQR & 3*SD):`n   - Median nilai baris = Rp 240.000 (Q1=Rp 120rb, Q3=Rp 558rb). Sebanyak 79 baris melampaui Mean + 3*SD (Rp 6,62 Jt), dan 2 transaksi mencapai Rp 63,20 Juta (200 DUS Minaku Otak-Otak oleh Pak Sutarmuji pada 3 & 13 Agu 2020).`n2. Outlier Kuantitas Spesifik SKU (Z_robust QTY > 8 / S03 = 237 baris):`n   - Pembelian 400 PACK Bakso Mie (Anton), 240 PACK Bakso Ikan (Egi/Putri), 200 PACK Cireng Bonju (Adek Frozen).`n3. Outlier Level Keranjang Struk (LOF & k-NN pada 1.495 Nota):`n   - Memisahkan Borongan Spesialis 1-SKU (Pak Sutarmuji, Mas Rohmat, Kubang Jaya) vs Borongan Restok Supermarket (Adek Frozen: 24-39 SKU berbeda dalam sehari senilai Rp 43-58 Juta)."
$g5.DrawString($sum5, $fSm, $bDark, (New-Object System.Drawing.RectangleF(872, 678, 644, 152)))

$bmp5.Save("$outDir\fig5_transaksi_outlier_multidimensi.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g5.Dispose(); $bmp5.Dispose()
Write-Output "Saved fig5_transaksi_outlier_multidimensi.png"

# ==============================================================================
# FIG 6: SISI 3C - ANOMALI TRANSAKSI TEMPORAL & OPERASIONAL (HARI & LONJAKAN)
# ==============================================================================
$bmp6 = New-Object System.Drawing.Bitmap(1600, 900)
$g6 = [System.Drawing.Graphics]::FromImage($bmp6)
$g6.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g6.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g6.Clear((New-Color "#F8FAFC"))

Draw-Header $g6 "SISI 3C  |  DETEKSI TRANSAKSI OUTLIER TEMPORAL: LONJAKAN OMZET HARIAN & ANOMALI HARI MINGGU" `
    "4 Hari Mengalami Lonjakan Omzet Ekstrem (Z_robust > 5: hingga Rp 188,5 Jt) & 1 Transaksi Jatuh di Hari Minggu" `
    "Kiri: Time-Series Omzet Harian (143 Hari Aktif, Apr-Sep 2020)  |  Kanan: Pola Operasional Mingguan & Bukti Anomali Hari Minggu (T02)"

Draw-Card $g6 48 124 960 730 "#FFFFFF" "#E2E8F0" 1.5 12
Draw-Card $g6 1032 124 520 730 "#FFFFFF" "#E2E8F0" 1.5 12

$g6.DrawString("Time-Series Omzet Harian Toko Frozen Food (1 April - 30 September 2020)", $fSec, $bDark, 72, 144)
$g6.DrawString("Median Harian = Rp 25,65 Jt (MAD = Rp 13,56 Jt)  |  Ambang Lonjakan Z_robust > 5 = Rp 93,45 Jt (Menjaring 4 Hari Outlier)", $fSubSec, $bMuted, 72, 170)

$daily = $df | Group-Object TGL | ForEach-Object {
    $sumO = ($_.Group | ForEach-Object { [double]$_.OMZET } | Measure-Object -Sum).Sum / 1e6
    [PSCustomObject]@{ TGL = $_.Name; Dt = [datetime]::Parse($_.Name); OmzetJt = $sumO; TxCnt = $_.Count }
} | Sort-Object Dt

$t6L = 120.0; $t6R = 975.0; $t6T = 220.0; $t6B = 740.0
$minDt = [datetime]::Parse("2020-04-01")
$maxDt = [datetime]::Parse("2020-09-30")
$totDays = ($maxDt - $minDt).TotalDays

function Map-T6X($dt) { return [float]($t6L + (($dt - $minDt).TotalDays / $totDays) * ($t6R - $t6L)) }
function Map-T6Y($omJt) { return [float]($t6B - ($omJt / 205.0) * ($t6B - $t6T)) }

# Month grid lines
$months = @("2020-04-01", "2020-05-01", "2020-06-01", "2020-07-01", "2020-08-01", "2020-09-01", "2020-09-30")
foreach ($mStr in $months) {
    $mdt = [datetime]::Parse($mStr)
    $gx = Map-T6X $mdt
    $g6.DrawLine($penGrid, $gx, $t6T, $gx, $t6B)
    $g6.DrawString($mdt.ToString("dd MMM"), $fSm, $bLight, ($gx - 18), ($t6B + 8))
}
for ($yv = 0; $yv -le 200; $yv += 40) {
    $gy = Map-T6Y $yv
    $g6.DrawLine($penGrid, $t6L, $gy, $t6R, $gy)
    $g6.DrawString("$yv Jt", $fSm, $bLight, ($t6L - 48), ($gy - 8))
}
$g6.DrawLine($pAxis, $t6L, $t6B, $t6R, $t6B)
$g6.DrawLine($pAxis, $t6L, $t6T, $t6L, $t6B)
$g6.DrawString("Kronologi Tanggal Transaksi (April - September 2020)", $fSmB, $bDark, 380, ($t6B + 32))

# Median & Z_robust > 5 lines
$gyMed6 = Map-T6Y 25.65
$gyZ5_6 = Map-T6Y 93.45
$pMed6 = New-Object System.Drawing.Pen ((New-Color "#0284C7"), 1.8)
$pMed6.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g6.DrawLine($pMed6, $t6L, $gyMed6, $t6R, $gyMed6)
$g6.DrawLine($pDashC, $t6L, $gyZ5_6, $t6R, $gyZ5_6)
$g6.DrawString("Ambang Outlier Z_robust > 5 (Rp 93,5 Jt)", $fSmB, (New-Object System.Drawing.SolidBrush (New-Color "#E11D48")), ($t6L + 12), ($gyZ5_6 - 18))
$g6.DrawString("Median Harian (Rp 25,7 Jt)", $fSmB, (New-Object System.Drawing.SolidBrush (New-Color "#0284C7")), ($t6L + 12), ($gyMed6 - 18))

# Line & points for daily omzet
$pts6 = New-Object 'System.Drawing.PointF[]' $daily.Count
for ($i = 0; $i -lt $daily.Count; $i++) {
    $pts6[$i] = New-Object System.Drawing.PointF((Map-T6X $daily[$i].Dt), (Map-T6Y $daily[$i].OmzetJt))
}
$pLine6 = New-Object System.Drawing.Pen ((New-Color "#64748B" 160), 1.6)
$g6.DrawLines($pLine6, $pts6)

foreach ($d in $daily) {
    $px = Map-T6X $d.Dt
    $py = Map-T6Y $d.OmzetJt
    if ($d.TGL -eq "2020-08-30") {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#D97706")
        $g6.FillEllipse($br, ($px - 6), ($py - 6), 12, 12)
        $g6.DrawString("Minggu 30 Agu (PAK PEPI: 1 tx = Rp 180rb!)", $fSmB, $br, ($px - 140), ($py - 24))
        $br.Dispose()
    } elseif ($d.OmzetJt -gt 93.45) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48")
        $g6.FillEllipse($br, ($px - 6), ($py - 6), 12, 12)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#0284C7" 150)
        $g6.FillEllipse($br, ($px - 3), ($py - 3), 6, 6)
        $br.Dispose()
    }
}

# Callouts for 4 Spike Days
$spikes = @(
    @{ Dt="2020-06-26"; O=188.49; Text="26 Jun: Rp 188,5 Jt (118 baris; Adek Frozen & Firdon)"; dx=-110; dy=-22 },
    @{ Dt="2020-07-29"; O=163.21; Text="29 Jul: Rp 163,2 Jt (118 baris; Adek Frozen Rp 58,8 Jt)"; dx=-130; dy=-22 },
    @{ Dt="2020-08-03"; O=129.03; Text="3 Agu: Rp 129,0 Jt (Pak Sutarmuji Rp 63,2 Jt + Mas Rohmat Rp 45,8 Jt)"; dx=-220; dy=14 },
    @{ Dt="2020-08-18"; O=144.88; Text="18 Agu: Rp 144,9 Jt (86 baris; Adek Frozen & Anton)"; dx=-40; dy=-22 }
)
$bRed = New-Object System.Drawing.SolidBrush (New-Color "#E11D48")
foreach ($sp in $spikes) {
    $px = Map-T6X ([datetime]::Parse($sp.Dt))
    $py = Map-T6Y $sp.O
    $g6.DrawString($sp.Text, $fSmB, $bRed, ($px + $sp.dx), ($py + $sp.dy))
}

# Right Panel: Day-of-Week Distribution
$g6.DrawString("Distribusi Aktivitas per Hari Operasional (T02)", $fSec, $bDark, 1054, 144)
$g6.DrawString("25 dari 26 Hari Minggu tutup total -> 1 transaksi Minggu adalah Outlier!", $fSubSec, $bMuted, 1054, 170)

$dowData = @(
    @{ Day="Senin (Monday)";     Active="21 / 26 hr"; Tx=1198; Omz="Rp 850,4 Jt"; Col="#0284C7" },
    @{ Day="Selasa (Tuesday)";   Active="24 / 26 hr"; Tx=1052; Omz="Rp 724,1 Jt"; Col="#0284C7" },
    @{ Day="Rabu (Wednesday)";   Active="26 / 27 hr"; Tx=1141; Omz="Rp 814,8 Jt"; Col="#0284C7" },
    @{ Day="Kamis (Thursday)";   Active="23 / 26 hr"; Tx=1102; Omz="Rp 712,5 Jt"; Col="#0284C7" },
    @{ Day="Jumat (Friday)";     Active="23 / 26 hr"; Tx=1066; Omz="Rp 775,2 Jt"; Col="#0284C7" },
    @{ Day="Sabtu (Saturday)";   Active="25 / 26 hr"; Tx=1180; Omz="Rp 743,9 Jt"; Col="#0284C7" },
    @{ Day="Minggu (Sunday)*";   Active="1 / 26 hr!"; Tx=1;    Omz="Rp 0,18 Jt!"; Col="#E11D48" }
)

$dy6 = 215
foreach ($dw in $dowData) {
    $bgD = if ($dw.Tx -eq 1) { "#FFF1F2" } else { "#F8FAFC" }
    $bdD = if ($dw.Tx -eq 1) { "#E11D48" } else { "#CBD5E1" }
    Draw-Card $g6 1054 $dy6 476 58 $bgD $bdD 1.2 8
    $g6.DrawString($dw.Day, $fSmB, $bDark, 1068, ($dy6 + 8))
    $g6.DrawString("Hari Aktif: $($dw.Active)", $fSm, $bMuted, 1068, ($dy6 + 30))

    $bw = [math]::Max(6.0, ($dw.Tx / 1250.0) * 180.0)
    $bB6 = New-Object System.Drawing.SolidBrush (New-Color $dw.Col)
    $g6.FillRectangle($bB6, 1230, ($dy6 + 12), $bw, 16)
    $g6.DrawString("$($dw.Tx) tx ($($dw.Omz))", $fSmB, $bB6, 1230, ($dy6 + 31))
    $bB6.Dispose()
    $dy6 += 66
}

Draw-Card $g6 1054 686 476 150 "#FFFBEB" "#F59E0B" 1.5 10
$g6.DrawString("INVESTIGASI ANOMALI HARI MINGGU (BARIS #5546):", $fSmB, (New-Object System.Drawing.SolidBrush (New-Color "#B45309")), 1068, 698)
$sunTxt = "- Tanggal   : Minggu, 30 Agustus 2020 (T02 - Peringatan)`n- Pelanggan : PAK PEPI`n- Barang    : OKEY-003 (OKEY STICK 500 GR X 10 PACK)`n- Volume    : 1,0 DUS @ Rp 180.000 (Omzet = Rp 180.000)`n- Diagnosis : Dari 26 hari Minggu sepanjang Apr-Sep 2020, toko libur pada 25 hari Minggu (96,2%). Satu-satunya transaksi ini terjadi karena salah ketik tanggal nota Sabtu (29 Agu) / Senin (31 Agu) atau pengambilan darurat di luar jam operasional."
$g6.DrawString($sunTxt, $fSm, $bDark, (New-Object System.Drawing.RectangleF(1068, 720, 450, 110)))

$bmp6.Save("$outDir\fig6_transaksi_temporal_operasional.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g6.Dispose(); $bmp6.Dispose()
Write-Output "Saved fig6_transaksi_temporal_operasional.png"
