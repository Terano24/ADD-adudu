Add-Type -AssemblyName System.Drawing

$rawDir = "slide_assets\outlier_ppt\raw"
if (-not (Test-Path $rawDir)) { New-Item -ItemType Directory -Path $rawDir -Force | Out-Null }

$df = Import-Csv "bersih\penjualan_bersih.csv"
$lrfm = Import-Csv "bersih\lrfm_pelanggan.csv"

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

function New-PlotCanvas($w=1500, $h=900, $title="", $subtitle="") {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.Clear((New-Color "#FFFFFF"))

    $fTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $fSub   = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Regular)
    $bTitle = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
    $bSub   = New-Object System.Drawing.SolidBrush (New-Color "#475569")

    if ($title -ne "") {
        $g.DrawString($title, $fTitle, $bTitle, 60, 32)
    }
    if ($subtitle -ne "") {
        $g.DrawString($subtitle, $fSub, $bSub, 60, 64)
    }

    $fTitle.Dispose(); $fSub.Dispose(); $bTitle.Dispose(); $bSub.Dispose()
    return @{ Bitmap = $bmp; Graphics = $g; Width = $w; Height = $h }
}

$fAxis = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$fAxisB = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fLeg  = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fLegB = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$fSm   = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$fSmB  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$bDark = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
$bMuted = New-Object System.Drawing.SolidBrush (New-Color "#64748B")
$bLight = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8")
$penGrid = New-Object System.Drawing.Pen ((New-Color "#E2E8F0"), 1.0)
$penAxis = New-Object System.Drawing.Pen ((New-Color "#334155"), 1.5)

function Draw-LegendBox($g, $x, $y, $w, $h, $items, $title="") {
    $bBg = New-Object System.Drawing.SolidBrush (New-Color "#FFFFFF" 245)
    $pBd = New-Object System.Drawing.Pen ((New-Color "#CBD5E1"), 1.2)
    $path = New-RoundedRect $x $y $w $h 6
    $g.FillPath($bBg, $path)
    $g.DrawPath($pBd, $path)
    $bBg.Dispose(); $pBd.Dispose(); $path.Dispose()

    $curY = $y + 10
    if ($title -ne "") {
        $bT = New-Object System.Drawing.SolidBrush (New-Color "#0F172A")
        $g.DrawString($title, $fLegB, $bT, ($x + 14), $curY)
        $bT.Dispose()
        $curY += 24
    }

    $itemH = 26
    $bTxt = New-Object System.Drawing.SolidBrush (New-Color "#1E293B")

    foreach ($it in $items) {
        $c = New-Color $it.Color
        $bShape = New-Object System.Drawing.SolidBrush $c
        $pShape = New-Object System.Drawing.Pen $c
        $pShape.Width = 2.0

        if ($it.Shape -eq "circle") {
            $g.FillEllipse($bShape, ($x + 14), ($curY + 3), 12, 12)
            $pEdge = New-Object System.Drawing.Pen (New-Color "#0F172A" 120)
            $g.DrawEllipse($pEdge, ($x + 14), ($curY + 3), 12, 12)
            $pEdge.Dispose()
        } elseif ($it.Shape -eq "ring") {
            $bShA = New-Object System.Drawing.SolidBrush (New-Color $it.Color 40)
            $g.FillEllipse($bShA, ($x + 11), ($curY + 0), 18, 18)
            $g.DrawEllipse($pShape, ($x + 11), ($curY + 0), 18, 18)
            $g.FillEllipse($bShape, ($x + 16), ($curY + 5), 8, 8)
            $bShA.Dispose()
        } elseif ($it.Shape -eq "dash") {
            $pShape.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $pShape.Width = 2.5
            $g.DrawLine($pShape, ($x + 12), ($curY + 9), ($x + 34), ($curY + 9))
        } elseif ($it.Shape -eq "line") {
            $pShape.Width = 2.5
            $g.DrawLine($pShape, ($x + 12), ($curY + 9), ($x + 34), ($curY + 9))
        } else {
            $g.FillRectangle($bShape, ($x + 14), ($curY + 2), 16, 14)
            $pB = New-Object System.Drawing.Pen (New-Color "#0F172A" 80)
            $g.DrawRectangle($pB, ($x + 14), ($curY + 2), 16, 14)
            $pB.Dispose()
        }

        $g.DrawString($it.Label, $fLeg, $bTxt, ($x + 40), $curY)
        $bShape.Dispose(); $pShape.Dispose()
        $curY += $itemH
    }
    $bTxt.Dispose()
}

# ==============================================================================
# RAW 01: BAR CHART FREKUENSI ATURAN ANOMALI & OUTLIER DENGAN LEGEND
# ==============================================================================
$p1 = New-PlotCanvas 1500 880 "Distribusi Frekuensi Temuan Anomali & Outlier Berdasarkan Kategori" `
    "Sumber: Data Penjualan April - Sep 2020.xlsx (N = 6.779 baris mentah)  |  Kategori Taksonomi Penyebab"
$g = $p1.Graphics

$rules = @(
    @{ Label="R01: Kode SKU Memiliki >1 Ejaan Nama"; Count=533; Pct="7,86%"; Cat="Integritas Master Data"; Color="#64748B" },
    @{ Label="R03: Outlet Tercatat di >1 Kode Kanal"; Count=402; Pct="5,93%"; Cat="Integritas Master Data"; Color="#64748B" },
    @{ Label="T01: Hari Lonjakan Omzet (Z_harian > 5)"; Count=370; Pct="5,46%"; Cat="Outlier Transaksi"; Color="#0284C7" },
    @{ Label="S03: Kuantitas Borongan Ekstrem (Z_QTY > 8)"; Count=237; Pct="3,50%"; Cat="Outlier Transaksi"; Color="#0284C7" },
    @{ Label="R02: Nama Barang Sama Dipakai >1 Kode"; Count=172; Pct="2,54%"; Cat="Integritas Master Data"; Color="#64748B" },
    @{ Label="D01: Duplikat Baris Identik Persis"; Count=73;  Pct="1,08%"; Cat="Error Sistem / Human"; Color="#E11D48" },
    @{ Label="A01: Diskon Grosir Wajar (Rasio 85-97%)"; Count=73; Pct="1,08%"; Cat="Variasi Bisnis Sah"; Color="#10B981" },
    @{ Label="K03b/K05: Barang Keluar Gratis (Sampling)"; Count=38; Pct="0,56%"; Cat="Error Sistem / Human"; Color="#E11D48" },
    @{ Label="S02: Harga Menyimpang Statistik (|Z| > 5)"; Count=26; Pct="0,38%"; Cat="Outlier Harga"; Color="#F59E0B" },
    @{ Label="K03a: Harga Kosong pada CASH Volume Besar"; Count=20; Pct="0,30%"; Cat="Error Sistem / Human"; Color="#E11D48" },
    @{ Label="S01: Harga Menyimpang Ekstrem (>30% Median)"; Count=7; Pct="0,10%"; Cat="Outlier Harga"; Color="#F59E0B" },
    @{ Label="A02: Potongan Harga Tak Wajar (Diskon 50%)"; Count=4; Pct="0,06%"; Cat="Outlier Harga"; Color="#F59E0B" },
    @{ Label="S04: Nilai Transaksi > Pagar Log-IQR (Rp 63,2 Jt)"; Count=2; Pct="0,03%"; Cat="Outlier Transaksi"; Color="#0284C7" },
    @{ Label="T02: Transaksi Hari Minggu (Toko Tutup)"; Count=1; Pct="0,01%"; Cat="Outlier Transaksi"; Color="#0284C7" }
)

$startY = 120; $rowH = 46; $maxBarW = 620.0; $maxVal = 550.0
for ($i = 0; $i -lt $rules.Count; $i++) {
    $r = $rules[$i]
    $y = $startY + $i * $rowH
    if ($i % 2 -eq 0) {
        $bRow = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC")
        $g.FillRectangle($bRow, 50, ($y - 4), 1050, ($rowH - 2))
        $bRow.Dispose()
    }
    $g.DrawString($r.Label, $fSmB, $bDark, 60, ($y + 8))
    $barX = 420
    $barW = [math]::Max(8.0, ($r.Count / $maxVal) * $maxBarW)
    $bBar = New-Object System.Drawing.SolidBrush (New-Color $r.Color)
    $pathBar = New-RoundedRect $barX ($y + 6) $barW 24 4
    $g.FillPath($bBar, $pathBar)
    $bBar.Dispose(); $pathBar.Dispose()
    $g.DrawString("$($r.Count) ($($r.Pct))", $fSmB, $bDark, ($barX + $barW + 10), ($y + 8))
}

$leg1 = @(
    @{ Label="Integritas Master Data (R01-R03)"; Color="#64748B"; Shape="box" },
    @{ Label="Outlier Transaksi Bisnis (T01, S03, S04, T02)"; Color="#0284C7"; Shape="box" },
    @{ Label="Error Sistem / Human (D01, K03a, K03b)"; Color="#E11D48"; Shape="box" },
    @{ Label="Outlier Harga Barang (S01, S02, A02)"; Color="#F59E0B"; Shape="box" },
    @{ Label="Variasi Bisnis Sah (A01)"; Color="#10B981"; Shape="box" }
)
Draw-LegendBox $g 1130 140 320 170 $leg1 "KATEGORI ANOMALI"

$p1.Bitmap.Save("$rawDir\raw_01_frekuensi_aturan_anomali.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p1.Bitmap.Dispose()
Write-Output "Saved raw_01_frekuensi_aturan_anomali.png"

# ==============================================================================
# RAW 02: 1D BOXPLOT & STRIP PLOT MONETARY & AOV DENGAN LEGEND
# ==============================================================================
$p2 = New-PlotCanvas 1500 850 "Distribusi Total Belanja (Monetary) & Nilai Belanja per Kunjungan (AOV)" `
    "N = 180 Pelanggan Outlet Bernama  |  Skala Logaritmik  |  Perbandingan Pagar Q3 + 1.5*IQR vs Mean + 3*SD"
$g = $p2.Graphics

function Map-LogX($valJuta, $xLeft, $xRight, $minLog, $maxLog) {
    $lg = [math]::Log10([math]::Max($valJuta, 0.05))
    return [float]($xLeft + (($lg - $minLog) / ($maxLog - $minLog)) * ($xRight - $xLeft))
}

$bxL = 100.0; $bxR = 1080.0
$minLg = -1.3; $maxLg = 2.85 # 0.05 to 700 Jt

# Section A: Monetary
$by1 = 230.0
$g.DrawString("A. Total Belanja Pelanggan (Monetary - Juta Rp)", $fAxisB, $bDark, 100, 140)
$g.DrawString("Q1 = Rp 2,38 Jt  |  Median = Rp 5,99 Jt  |  Q3 = Rp 18,20 Jt  |  Pagar 1.5*IQR = Rp 41,93 Jt (19 Outlier)  |  Pagar 3*SD = Rp 215,79 Jt (4 Outlier)", $fSm, $bMuted, 100, 164)

$ticksM = @(0.1, 0.5, 1, 2.38, 5.99, 18.2, 41.9, 100, 215.8, 547.8)
foreach ($tk in $ticksM) {
    $tx = Map-LogX $tk $bxL $bxR $minLg $maxLg
    $g.DrawLine($penGrid, $tx, ($by1 - 15), $tx, ($by1 + 105))
    $lbl = if ($tk -ge 10) { "{0:N0}" -f $tk } else { "{0:N1}" -f $tk }
    $g.DrawString($lbl, $fSm, $bLight, ($tx - 12), ($by1 + 108))
}
$g.DrawString("Monetary (Juta Rp - Skala Logaritmik)", $fSmB, $bMuted, 510, ($by1 + 130))

$xQ1_M = Map-LogX 2.3835 $bxL $bxR $minLg $maxLg
$xMed_M = Map-LogX 5.9892 $bxL $bxR $minLg $maxLg
$xQ3_M = Map-LogX 18.204 $bxL $bxR $minLg $maxLg
$xIQR_M = Map-LogX 41.935 $bxL $bxR $minLg $maxLg
$x3SD_M = Map-LogX 215.79 $bxL $bxR $minLg $maxLg
$xMin_M = Map-LogX 0.08 $bxL $bxR $minLg $maxLg

$bBox = New-Object System.Drawing.SolidBrush (New-Color "#BAE6FD" 160)
$pBox = New-Object System.Drawing.Pen ((New-Color "#0284C7"), 2.0)
$g.FillRectangle($bBox, $xQ1_M, ($by1 + 5), ($xQ3_M - $xQ1_M), 40)
$g.DrawRectangle($pBox, $xQ1_M, ($by1 + 5), ($xQ3_M - $xQ1_M), 40)
$pMed = New-Object System.Drawing.Pen ((New-Color "#0F172A"), 3.0)
$g.DrawLine($pMed, $xMed_M, ($by1 + 5), $xMed_M, ($by1 + 45))
$g.DrawLine($pBox, $xMin_M, ($by1 + 25), $xQ1_M, ($by1 + 25))
$g.DrawLine($pBox, $xQ3_M, ($by1 + 25), $xIQR_M, ($by1 + 25))

$pDashW = New-Object System.Drawing.Pen ((New-Color "#F59E0B"), 2.0); $pDashW.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$pDashC = New-Object System.Drawing.Pen ((New-Color "#E11D48"), 2.0); $pDashC.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g.DrawLine($pDashW, $xIQR_M, ($by1 - 15), $xIQR_M, ($by1 + 105))
$g.DrawLine($pDashC, $x3SD_M, ($by1 - 15), $x3SD_M, ($by1 + 105))

$rnd = New-Object System.Random(42)
foreach ($c in $lrfm) {
    $mJt = [double]$c.M / 1e6
    $px = Map-LogX $mJt $bxL $bxR $minLg $maxLg
    $py = $by1 + 75 + ($rnd.NextDouble() - 0.5) * 30
    $col = if ($mJt -gt 215.79) { "#E11D48" } elseif ($mJt -gt 41.935) { "#F59E0B" } else { "#64748B" }
    $al  = if ($mJt -gt 41.935) { 240 } else { 120 }
    $sz  = if ($mJt -gt 41.935) { 9 } else { 5.5 }
    $br  = New-Object System.Drawing.SolidBrush (New-Color $col $al)
    $g.FillEllipse($br, ($px - $sz/2), ($py - $sz/2), $sz, $sz)
    $br.Dispose()
}

# Section B: AOV
$by2 = 490.0
$minLg2 = -1.3; $maxLg2 = 2.0
$g.DrawString("B. Rata-Rata Nilai Belanja per Kunjungan (AOV = Monetary / Frequency - Juta Rp)", $fAxisB, $bDark, 100, 400)
$g.DrawString("Q1 = Rp 0,75 Jt  |  Median = Rp 1,62 Jt  |  Q3 = Rp 3,04 Jt  |  Pagar 1.5*IQR = Rp 6,48 Jt (18 Outlier)  |  Pagar 3*SD = Rp 22,68 Jt (3 Outlier)", $fSm, $bMuted, 100, 424)

$ticksA = @(0.1, 0.3, 0.75, 1.62, 3.04, 6.48, 12.15, 22.68, 38.25, 63.2)
foreach ($tk in $ticksA) {
    $tx = Map-LogX $tk $bxL $bxR $minLg2 $maxLg2
    $g.DrawLine($penGrid, $tx, ($by2 - 15), $tx, ($by2 + 105))
    $lbl = if ($tk -ge 10) { "{0:N1}" -f $tk } else { "{0:N2}" -f $tk }
    $g.DrawString($lbl, $fSm, $bLight, ($tx - 12), ($by2 + 108))
}
$g.DrawString("AOV = M / F (Juta Rp / Hari Kunjungan - Skala Logaritmik)", $fSmB, $bMuted, 450, ($by2 + 130))

$xQ1_A = Map-LogX 0.749 $bxL $bxR $minLg2 $maxLg2
$xMed_A = Map-LogX 1.622 $bxL $bxR $minLg2 $maxLg2
$xQ3_A = Map-LogX 3.041 $bxL $bxR $minLg2 $maxLg2
$xIQR_A = Map-LogX 6.479 $bxL $bxR $minLg2 $maxLg2
$x3SD_A = Map-LogX 22.677 $bxL $bxR $minLg2 $maxLg2
$xMin_A = Map-LogX 0.058 $bxL $bxR $minLg2 $maxLg2

$g.FillRectangle($bBox, $xQ1_A, ($by2 + 5), ($xQ3_A - $xQ1_A), 40)
$g.DrawRectangle($pBox, $xQ1_A, ($by2 + 5), ($xQ3_A - $xQ1_A), 40)
$g.DrawLine($pMed, $xMed_A, ($by2 + 5), $xMed_A, ($by2 + 45))
$g.DrawLine($pBox, $xMin_A, ($by2 + 25), $xQ1_A, ($by2 + 25))
$g.DrawLine($pBox, $xQ3_A, ($by2 + 25), $xIQR_A, ($by2 + 25))
$g.DrawLine($pDashW, $xIQR_A, ($by2 - 15), $xIQR_A, ($by2 + 105))
$g.DrawLine($pDashC, $x3SD_A, ($by2 - 15), $x3SD_A, ($by2 + 105))

foreach ($c in $lrfm) {
    $aovJt = ([double]$c.M / [double]$c.F) / 1e6
    $px = Map-LogX $aovJt $bxL $bxR $minLg2 $maxLg2
    $py = $by2 + 75 + ($rnd.NextDouble() - 0.5) * 30
    $col = if ($aovJt -gt 22.677) { "#E11D48" } elseif ($aovJt -gt 6.479) { "#F59E0B" } else { "#64748B" }
    $al  = if ($aovJt -gt 6.479) { 240 } else { 120 }
    $sz  = if ($aovJt -gt 6.479) { 9 } else { 5.5 }
    $br  = New-Object System.Drawing.SolidBrush (New-Color $col $al)
    $g.FillEllipse($br, ($px - $sz/2), ($py - $sz/2), $sz, $sz)
    $br.Dispose()
}

$leg2 = @(
    @{ Label="Titik Data Normal (Inlier)"; Color="#64748B"; Shape="circle" },
    @{ Label="Pagar Q3 + 1.5*IQR (Outlier Moderat)"; Color="#F59E0B"; Shape="dash" },
    @{ Label="Titik Outlier Moderat (> 1.5*IQR)"; Color="#F59E0B"; Shape="circle" },
    @{ Label="Pagar Mean + 3*SD (Outlier Ekstrem)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Titik Outlier Ekstrem (> 3*SD)"; Color="#E11D48"; Shape="circle" },
    @{ Label="Rentang Interkuartil [Q1, Q3]"; Color="#0284C7"; Shape="box" },
    @{ Label="Garis Median Data (Q2)"; Color="#0F172A"; Shape="line" }
)
Draw-LegendBox $g 1130 180 320 220 $leg2 "KETERANGAN SIMBOL"

$p2.Bitmap.Save("$rawDir\raw_02_pelanggan_boxplot_monetary_aov.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p2.Bitmap.Dispose()
Write-Output "Saved raw_02_pelanggan_boxplot_monetary_aov.png"

# ==============================================================================
# RAW 03: 2D SCATTER PLOT FREQUENCY VS MONETARY + CONVEX HULL DENGAN LEGEND
# ==============================================================================
$p3 = New-PlotCanvas 1500 900 "2D Scatter Plot & Convex Hull: Frequency vs Monetary Pelanggan" `
    "N = 180 Pelanggan Outlet Bernama  |  Materi Week 5 Slide 4-8 & Week 7 (Pendekatan Grafis Multivariat)"
$g = $p3.Graphics

$scL = 120.0; $scR = 1120.0; $scT = 130.0; $scB = 800.0
function Map-ScX($fVal) { return [float]($scL + ($fVal / 85.0) * ($scR - $scL)) }
function Map-ScY($mValJt) { return [float]($scB - ($mValJt / 580.0) * ($scB - $scT)) }

for ($fv = 0; $fv -le 80; $fv += 10) {
    $gx = Map-ScX $fv
    $g.DrawLine($penGrid, $gx, $scT, $gx, $scB)
    $g.DrawString("$fv", $fAxis, $bLight, ($gx - 8), ($scB + 8))
}
for ($mv = 0; $mv -le 550; $mv += 100) {
    $gy = Map-ScY $mv
    $g.DrawLine($penGrid, $scL, $gy, $scR, $gy)
    $g.DrawString("$mv Jt", $fAxis, $bLight, ($scL - 55), ($gy - 8))
}
$g.DrawLine($penAxis, $scL, $scB, $scR, $scB)
$g.DrawLine($penAxis, $scL, $scT, $scL, $scB)
$g.DrawString("Frequency (Jumlah Hari Kunjungan Aktif Selama 6 Bulan)", $fAxisB, $bDark, 480, ($scB + 36))

# Pagar IQR
$gxIQR = Map-ScX 17.0
$gyIQR = Map-ScY 41.935
$g.DrawLine($pDashW, $gxIQR, $scT, $gxIQR, $scB)
$g.DrawLine($pDashW, $scL, $gyIQR, $scR, $gyIQR)

# Convex Hull Polygon
$hullPts = @(
    (New-Object System.Drawing.PointF((Map-ScX 1), (Map-ScY 0.06))),
    (New-Object System.Drawing.PointF((Map-ScX 2), (Map-ScY 126.4))),
    (New-Object System.Drawing.PointF((Map-ScX 11), (Map-ScY 420.73))),
    (New-Object System.Drawing.PointF((Map-ScX 50), (Map-ScY 547.77))),
    (New-Object System.Drawing.PointF((Map-ScX 80), (Map-ScY 113.73))),
    (New-Object System.Drawing.PointF((Map-ScX 46), (Map-ScY 23.98))),
    (New-Object System.Drawing.PointF((Map-ScX 26), (Map-ScY 4.68)))
)
$bHull = New-Object System.Drawing.SolidBrush (New-Color "#FFE4E6" 60)
$pHull = New-Object System.Drawing.Pen ((New-Color "#E11D48" 180), 2.0)
$pHull.DashStyle = [System.Drawing.Drawing2D.DashStyle]::DashDot
$g.FillPolygon($bHull, $hullPts)
$g.DrawPolygon($pHull, $hullPts)

foreach ($c in $lrfm) {
    $fv = [double]$c.F
    $mv = [double]$c.M / 1e6
    $px = Map-ScX $fv
    $py = Map-ScY $mv
    $isWhale = ($mv -gt 110.0) -or ($fv -ge 45)
    $isBulkOnce = ($fv -le 2) -and ($mv -ge 12.0)
    $isFreqLowM = ($fv -ge 25) -and ($mv -lt 10.0)
    if ($isWhale) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 240)
        $g.FillEllipse($br, ($px - 7), ($py - 7), 14, 14)
        $br.Dispose()
    } elseif ($isBulkOnce) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#D97706" 240)
        $g.FillEllipse($br, ($px - 7), ($py - 7), 14, 14)
        $br.Dispose()
    } elseif ($isFreqLowM -or $mv -gt 41.935 -or $fv -gt 17) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#0284C7" 220)
        $g.FillEllipse($br, ($px - 5), ($py - 5), 10, 10)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 140)
        $g.FillEllipse($br, ($px - 4), ($py - 4), 8, 8)
        $br.Dispose()
    }
}

$leg3 = @(
    @{ Label="Pelanggan Normal (Inlier)"; Color="#94A3B8"; Shape="circle" },
    @{ Label="p1: Wholesale Whale (M > 3*SD / F > 3*SD)"; Color="#E11D48"; Shape="circle" },
    @{ Label="p2: One-Shot Bulk Buyer (F <= 2, M >= 12 Jt)"; Color="#D97706"; Shape="circle" },
    @{ Label="p3: Frekuensi / Kunjungan Di Atas Rata-rata"; Color="#0284C7"; Shape="circle" },
    @{ Label="Batas Convex Hull Terluar (Week 7)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Ambang Batas 1.5*IQR (M=41,9 Jt; F=17 hr)"; Color="#F59E0B"; Shape="dash" }
)
Draw-LegendBox $g 1145 150 330 200 $leg3 "LEGENDA KLASIFIKASI"

$p3.Bitmap.Save("$rawDir\raw_03_pelanggan_scatter_convexhull.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p3.Bitmap.Dispose()
Write-Output "Saved raw_03_pelanggan_scatter_convexhull.png"

# ==============================================================================
# RAW 04: 2D LOF DENSITY PLOT DENGAN LEGEND
# ==============================================================================
$p4 = New-PlotCanvas 1500 900 "2D Local Outlier Factor (LOF): Frekuensi vs Nilai Belanja per Kunjungan (AOV)" `
    "Materi Week 7 (Density-Based Outlier Detection)  |  Radius Cincin Sebanding dengan Skor LOF Pelanggan"
$g = $p4.Graphics

$p4L = 120.0; $p4R = 1120.0; $p4T = 130.0; $p4B = 800.0
function Map-P4X($fVal) {
    $lg = [math]::Log10([math]::Max($fVal, 1.0))
    return [float]($p4L + ($lg / 1.95) * ($p4R - $p4L))
}
function Map-P4Y($aovJt) {
    $lg = [math]::Log10([math]::Max($aovJt, 0.04))
    return [float]($p4B - (($lg - (-1.4)) / (1.9 - (-1.4))) * ($p4B - $p4T))
}

foreach ($ft in @(1, 2, 3, 5, 10, 20, 40, 80)) {
    $gx = Map-P4X $ft
    $g.DrawLine($penGrid, $gx, $p4T, $gx, $p4B)
    $g.DrawString("$ft hr", $fAxis, $bLight, ($gx - 12), ($p4B + 8))
}
foreach ($at in @(0.06, 0.15, 0.5, 1.62, 5.0, 15.0, 38.0, 63.2)) {
    $gy = Map-P4Y $at
    $g.DrawLine($penGrid, $p4L, $gy, $p4R, $gy)
    $lbl = if ($at -ge 1) { "{0:N1} Jt" -f $at } else { "{0:N2} Jt" -f $at }
    $g.DrawString($lbl, $fAxis, $bLight, ($p4L - 65), ($gy - 8))
}
$g.DrawLine($penAxis, $p4L, $p4B, $p4R, $p4B)
$g.DrawLine($penAxis, $p4L, $p4T, $p4L, $p4B)
$g.DrawString("Frequency Kunjungan (Hari Aktif - Skala Logaritmik)", $fAxisB, $bDark, 480, ($p4B + 36))

# Core cluster zone
$cZone = New-RoundedRect (Map-P4X 1.5) (Map-P4Y 5.5) ((Map-P4X 22) - (Map-P4X 1.5)) ((Map-P4Y 0.35) - (Map-P4Y 5.5)) 25
$bCore = New-Object System.Drawing.SolidBrush (New-Color "#E0F2FE" 70)
$pCore = New-Object System.Drawing.Pen ((New-Color "#38BDF8" 150), 1.5)
$pCore.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g.FillPath($bCore, $cZone)
$g.DrawPath($pCore, $cZone)
$bCore.Dispose(); $pCore.Dispose(); $cZone.Dispose()

$topOutliersMap = @{
    "PAK SUTARMUJI"      = @{ LOF=1.495; Col="#E11D48"; Cat="p2: Bulk Buyer" }
    "ADEK FROZEN"        = @{ LOF=1.181; Col="#E11D48"; Cat="p1: Whale Grosir" }
    "MAS ROHMAT"         = @{ LOF=1.246; Col="#D97706"; Cat="p2: Bulk Buyer" }
    "YUDI"               = @{ LOF=1.262; Col="#D97706"; Cat="p2: One-Shot Bulk" }
    "FRESH SUN SWALAYAN" = @{ LOF=1.210; Col="#D97706"; Cat="p2: One-Shot Bulk" }
    "DEFRIADI"           = @{ LOF=1.454; Col="#E11D48"; Cat="p2: One-Shot Churn" }
    "TOKO CITA RASA BARU"= @{ LOF=1.340; Col="#E11D48"; Cat="p1: Whale Grosir" }
    "ANTON"              = @{ LOF=1.150; Col="#0284C7"; Cat="p1: Whale Grosir" }
    "AMANAH FROZEN"      = @{ LOF=1.219; Col="#E11D48"; Cat="p1: Frekuensi Tinggi" }
    "FADIL ANAK BOS"     = @{ LOF=1.341; Col="#0284C7"; Cat="p3: Eceran Sering" }
    "KAK YENI"           = @{ LOF=1.609; Col="#E11D48"; Cat="p3: Kepadatan Lokal" }
    "OKE MART"           = @{ LOF=1.545; Col="#D97706"; Cat="p2: Churn Mendadak" }
}

foreach ($c in $lrfm) {
    $p = $c.PELANGGAN
    $fv = [double]$c.F
    $aov = ([double]$c.M / $fv) / 1e6
    $px = Map-P4X $fv
    $py = Map-P4Y $aov
    if ($topOutliersMap.ContainsKey($p)) {
        $info = $topOutliersMap[$p]
        $ringR = [float](($info.LOF - 0.95) * 40.0)
        $pRing = New-Object System.Drawing.Pen ((New-Color $info.Col 190), 2.0)
        $bRing = New-Object System.Drawing.SolidBrush (New-Color $info.Col 40)
        $g.FillEllipse($bRing, ($px - $ringR/2), ($py - $ringR/2), $ringR, $ringR)
        $g.DrawEllipse($pRing, ($px - $ringR/2), ($py - $ringR/2), $ringR, $ringR)
        $bDot = New-Object System.Drawing.SolidBrush (New-Color $info.Col 255)
        $g.FillEllipse($bDot, ($px - 5), ($py - 5), 10, 10)
        $pRing.Dispose(); $bRing.Dispose(); $bDot.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 130)
        $g.FillEllipse($br, ($px - 4), ($py - 4), 8, 8)
        $br.Dispose()
    }
}

$leg4 = @(
    @{ Label="Pelanggan Klaster Utama (LOF ~ 1,0)"; Color="#94A3B8"; Shape="circle" },
    @{ Label="Outlier LOF Kritis (LOF > 1,35)"; Color="#E11D48"; Shape="ring" },
    @{ Label="Outlier LOF Moderat (LOF > 1,20)"; Color="#D97706"; Shape="ring" },
    @{ Label="Whale / Frekuensi Khusus"; Color="#0284C7"; Shape="ring" },
    @{ Label="Zona Klaster Normal Inliers"; Color="#38BDF8"; Shape="dash" }
)
Draw-LegendBox $g 1145 150 330 170 $leg4 "LEGENDA KEPADATAN LOF"

$p4.Bitmap.Save("$rawDir\raw_04_pelanggan_lof_density.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p4.Bitmap.Dispose()
Write-Output "Saved raw_04_pelanggan_lof_density.png"

# ==============================================================================
# RAW 05: DIVERGING LOLLIPOP DEVIASI HARGA THD MEDIAN SKU+SATUAN DENGAN LEGEND
# ==============================================================================
$p5 = New-PlotCanvas 1500 850 "Deviasi Harga Satuan Transaksi (%) terhadap Median SKU + Satuan (Konteks X1 & X2)" `
    "Menyaring Harga Terlalu Murah (< -30%) atau Terlalu Mahal (> +30%) serta Diskon Aritmetika Tak Wajar"
$g = $p5.Graphics

$priceOutliers = @(
    @{ Label="MIT-005 (PACK) | Pak Erwin (3 tx, QTY 6-27)"; Dev=-50.0; Col="#E11D48"; Cat="Diskon Ekstrem (A02 -50%)" },
    @{ Label="MIT-013 (PACK) | Pak Erwin (1 tx, QTY 51)";   Dev=-50.0; Col="#E11D48"; Cat="Diskon Ekstrem (A02 -50%)" },
    @{ Label="LUTOSA-001 (PACK) | Fadil Anak Bos (3 tx, QTY 1-2)"; Dev=-42.3; Col="#E11D48"; Cat="Terlalu Murah (S01: -42,3%)" },
    @{ Label="DEN-002 (PACK) | Toko Cita Rasa Baru (QTY 27)"; Dev=-33.3; Col="#E11D48"; Cat="Terlalu Murah (S01: -33,3%)" },
    @{ Label="MIT-004 (PACK) | Adek Frozen (QTY 10)"; Dev=-22.8; Col="#F59E0B"; Cat="Deviasi Moderat (S02: 10-30%)" },
    @{ Label="MIN-002 (DUS) | Kubang Jaya Food (QTY 1)"; Dev=-20.6; Col="#F59E0B"; Cat="Deviasi Moderat (S02: 10-30%)" },
    @{ Label="MIT-009 (PACK) | Adek Frozen (2 tx, QTY 5)"; Dev=-14.5; Col="#F59E0B"; Cat="Tier Grosir Wajar (S02)" },
    @{ Label="FOODY-001 (DUS) | Adek Frozen (QTY 2)"; Dev=-13.6; Col="#F59E0B"; Cat="Tier Grosir Wajar (S02)" },
    @{ Label="FINNA-001 (DUS) | 4 Transaksi (QTY 1-5)"; Dev=12.0; Col="#F59E0B"; Cat="Deviasi Moderat (S02: 10-30%)" },
    @{ Label="MIT-008 (PACK) | 3 Transaksi (QTY 5-20)"; Dev=14.3; Col="#F59E0B"; Cat="Deviasi Moderat (S02: 10-30%)" },
    @{ Label="CHA-001 (PACK) | 2 Transaksi (QTY 2-4)"; Dev=17.6; Col="#F59E0B"; Cat="Deviasi Moderat (S02: 10-30%)" },
    @{ Label="SHIF-003 (DUS) | Anjani Frozen Food (QTY 2)"; Dev=30.6; Col="#E11D48"; Cat="Terlalu Mahal (S01: +30,6%)" },
    @{ Label="DEN-011 (PACK) | CASH Walk-in (QTY 6)"; Dev=33.3; Col="#E11D48"; Cat="Terlalu Mahal (S01: +33,3%)" },
    @{ Label="CONE-004 (BKS) | CASH Walk-in (QTY 2)"; Dev=40.0; Col="#E11D48"; Cat="Terlalu Mahal (S01: +40,0%)" }
)

$dvZeroX = 760.0
$dvScale = 3.6
$dvTop = 130.0; $dvBot = 770.0

# Shaded Normal Zone [-30%, +30%]
$xM30 = [float]($dvZeroX - 30.0 * $dvScale)
$xP30 = [float]($dvZeroX + 30.0 * $dvScale)
$bNorm = New-Object System.Drawing.SolidBrush (New-Color "#ECFDF5" 150)
$g.FillRectangle($bNorm, $xM30, $dvTop, ($xP30 - $xM30), ($dvBot - $dvTop))
$bNorm.Dispose()

foreach ($pct in @(-50, -30, -20, 0, 20, 30, 50)) {
    $gx = [float]($dvZeroX + $pct * $dvScale)
    $penG = if ($pct -eq 0) { $penAxis } elseif ([math]::Abs($pct) -eq 30) { $pDashC } else { $penGrid }
    $g.DrawLine($penG, $gx, $dvTop, $gx, $dvBot)
    $lbl = if ($pct -gt 0) { "+$pct%" } else { "$pct%" }
    $g.DrawString($lbl, $fSmB, $bMuted, ($gx - 16), ($dvBot + 8))
}
$g.DrawString("Deviasi Harga terhadap Median SKU + Satuan yang Sama (%)", $fAxisB, $bDark, 580, ($dvBot + 32))

$rowH5 = 44.0
for ($i = 0; $i -lt $priceOutliers.Count; $i++) {
    $po = $priceOutliers[$i]
    $ry = $dvTop + 10 + $i * $rowH5
    if ($i % 2 -eq 0) {
        $bAlt = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC" 180)
        $g.FillRectangle($bAlt, 60, ($ry - 3), 1050, ($rowH5 - 2))
        $bAlt.Dispose()
    }
    $g.DrawString($po.Label, $fSmB, $bDark, 65, ($ry + 7))

    $endX = [float]($dvZeroX + $po.Dev * $dvScale)
    $pStem = New-Object System.Drawing.Pen ((New-Color $po.Col), 3.0)
    $bDot  = New-Object System.Drawing.SolidBrush (New-Color $po.Col)
    $g.DrawLine($pStem, $dvZeroX, ($ry + 16), $endX, ($ry + 16))
    $g.FillEllipse($bDot, ($endX - 6), ($ry + 10), 12, 12)

    $devStr = if ($po.Dev -gt 0) { "+{0:N1}%" -f $po.Dev } else { "{0:N1}%" -f $po.Dev }
    $txtX = if ($po.Dev -lt 0) { $endX - 52 } else { $endX + 10 }
    $g.DrawString($devStr, $fSmB, $bDot, $txtX, ($ry + 8))
    $pStem.Dispose(); $bDot.Dispose()
}

$leg5 = @(
    @{ Label="Outlier Kritis: Terlalu Murah / Terlalu Mahal (|Dev| > 30%)"; Color="#E11D48"; Shape="circle" },
    @{ Label="Outlier Statistik Tier Grosir (Deviasi 10-30%)"; Color="#F59E0B"; Shape="circle" },
    @{ Label="Zona Normal Wajar [-30%, +30%]"; Color="#10B981"; Shape="box" },
    @{ Label="Pagar Ambang Outlier Kritis (S01 = +/- 30%)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Median SKU+Satuan Acuan (Deviasi 0%)"; Color="#334155"; Shape="line" }
)
Draw-LegendBox $g 1140 150 335 170 $leg5 "LEGENDA PENYIMPANGAN HARGA"

$p5.Bitmap.Save("$rawDir\raw_05_harga_diverging_sku_median.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p5.Bitmap.Dispose()
Write-Output "Saved raw_05_harga_diverging_sku_median.png"

# ==============================================================================
# RAW 06: DISTRIBUSI HARGA BERDASARKAN KATEGORI KEMASAN (KONTEKS X3)
# ==============================================================================
$p6 = New-PlotCanvas 1500 850 "Distribusi Harga Barang Berdasarkan Kategori Satuan Kemasan (Konteks X3)" `
    "N = 6.740 Transaksi Bersih  |  7 Satuan Kemasan  |  Pagar IQR per Satuan & Identifikasi SKU Premium"
$g = $p6.Graphics

$satKemasan = @(
    @{ Sat="DUS";  N=2662; Med=240000; Q1=210000; Q3=325000; Fence=573000; Min=115000; Max=1000000; Col="#0284C7" },
    @{ Sat="BAL";  N=160;  Med=260000; Q1=260000; Q3=270000; Fence=285000; Min=230000; Max=345000;  Col="#0284C7" },
    @{ Sat="JRG";  N=11;   Med=145000; Q1=142500; Q3=145000; Fence=148750; Min=142500; Max=145000;  Col="#10B981" },
    @{ Sat="PAIL"; N=514;  Med=125000; Q1=120000; Q3=130000; Fence=145000; Min=120000; Max=185000;  Col="#0284C7" },
    @{ Sat="PACK"; N=3022; Med=18000;  Q1=13000;  Q3=26000;  Fence=45500;  Min=4000;   Max=65000;   Col="#E11D48" },
    @{ Sat="BKS";  N=296;  Med=15000;  Q1=5000;   Q3=15000;  Fence=30000;  Min=5000;   Max=15000;   Col="#0284C7" },
    @{ Sat="PCS";  N=75;   Med=8500;   Q1=8500;   Q3=14000;  Fence=22250;  Min=8500;   Max=29000;   Col="#F59E0B" }
)

$kL = 160.0; $kR = 1100.0; $kT = 130.0; $kB = 780.0
function Map-Ky($valRp) {
    $lg = [math]::Log10([math]::Max($valRp, 2000.0))
    return [float]($kB - (($lg - 3.4) / (6.1 - 3.4)) * ($kB - $kT)) # Rp 2,5rb to 1,2 Juta
}

foreach ($vr in @(5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000)) {
    $gy = Map-Ky $vr
    $g.DrawLine($penGrid, $kL, $gy, $kR, $gy)
    $lbl = if ($vr -ge 1000000) { "Rp 1 Juta" } elseif ($vr -ge 1000) { "Rp {0:N0}rb" -f ($vr/1000) } else { "$vr" }
    $g.DrawString($lbl, $fAxis, $bLight, ($kL - 75), ($gy - 8))
}
$g.DrawLine($penAxis, $kL, $kB, $kR, $kB)
$g.DrawLine($penAxis, $kL, $kT, $kL, $kB)

$slotW = ($kR - $kL) / $satKemasan.Count
for ($i = 0; $i -lt $satKemasan.Count; $i++) {
    $sk = $satKemasan[$i]
    $cx = [float]($kL + ($i + 0.5) * $slotW)

    $yQ1 = Map-Ky $sk.Q1
    $yMed = Map-Ky $sk.Med
    $yQ3 = Map-Ky $sk.Q3
    $yMin = Map-Ky $sk.Min
    $yMax = Map-Ky $sk.Max
    $yFence = Map-Ky $sk.Fence

    $boxW = 60.0
    $bB = New-Object System.Drawing.SolidBrush (New-Color $sk.Col 60)
    $pB = New-Object System.Drawing.Pen ((New-Color $sk.Col), 2.0)
    $pM = New-Object System.Drawing.Pen ((New-Color "#0F172A"), 3.0)

    # Box
    $g.FillRectangle($bB, ($cx - $boxW/2), $yQ3, $boxW, ($yQ1 - $yQ3))
    $g.DrawRectangle($pB, ($cx - $boxW/2), $yQ3, $boxW, ($yQ1 - $yQ3))
    $g.DrawLine($pM, ($cx - $boxW/2), $yMed, ($cx + $boxW/2), $yMed)

    # Whiskers
    $g.DrawLine($pB, $cx, $yQ1, $cx, $yMin)
    $g.DrawLine($pB, ($cx - 15), $yMin, ($cx + 15), $yMin)
    $g.DrawLine($pB, $cx, $yQ3, $cx, [math]::Max($yFence, $yMax))
    $g.DrawLine($pB, ($cx - 15), [math]::Max($yFence, $yMax), ($cx + 15), [math]::Max($yFence, $yMax))

    # Outlier points
    if ($sk.Max -gt $sk.Fence) {
        $brOut = New-Object System.Drawing.SolidBrush (New-Color "#E11D48")
        $g.FillEllipse($brOut, ($cx - 5), ($yMax - 5), 10, 10)
        $brOut.Dispose()
    }

    # Labels below axis
    $g.DrawString($sk.Sat, $fAxisB, $bDark, ($cx - 18), ($kB + 10))
    $g.DrawString("(n=$($sk.N))", $fSm, $bMuted, ($cx - 24), ($kB + 30))

    $bB.Dispose(); $pB.Dispose(); $pM.Dispose()
}

$leg6 = @(
    @{ Label="Rentang Interkuartil [Q1, Q3]"; Color="#0284C7"; Shape="box" },
    @{ Label="Garis Median per Satuan"; Color="#0F172A"; Shape="line" },
    @{ Label="Batas Atas / Whisker (Pagar IQR)"; Color="#0284C7"; Shape="line" },
    @{ Label="Titik Outlier Melampaui Pagar Satuan"; Color="#E11D48"; Shape="circle" },
    @{ Label="Satuan Harga Sangat Stabil (CV < 2%)"; Color="#10B981"; Shape="box" }
)
Draw-LegendBox $g 1140 150 335 170 $leg6 "LEGENDA DISTRIBUSI SATUAN"

$p6.Bitmap.Save("$rawDir\raw_06_harga_distribusi_satuan_kemasan.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p6.Bitmap.Dispose()
Write-Output "Saved raw_06_harga_distribusi_satuan_kemasan.png"

# ==============================================================================
# RAW 07: 2D SCATTER QTY VS OMZET LEVEL BARIS DENGAN LEGEND
# ==============================================================================
$p7 = New-PlotCanvas 1500 900 "Deteksi Transaksi Outlier Level Baris Item (N = 6.740 Transaksi)" `
    "Kuantitas Fisik (QTY) vs Nilai Transaksi (OMZET)  |  Skala Logaritmik  |  Pagar Log-IQR & 3-SD"
$g = $p7.Graphics

$p7L = 120.0; $p7R = 1120.0; $p7T = 130.0; $p7B = 800.0
function Map-P7X($qtyVal) {
    $lg = [math]::Log10([math]::Max($qtyVal, 1.0))
    return [float]($p7L + ($lg / 2.65) * ($p7R - $p7L))
}
function Map-P7Y($omzVal) {
    $lg = [math]::Log10([math]::Max($omzVal, 3000.0))
    return [float]($p7B - (($lg - 3.4) / (7.9 - 3.4)) * ($p7B - $p7T))
}

foreach ($qt in @(1, 2, 5, 10, 25, 50, 100, 200, 400)) {
    $gx = Map-P7X $qt
    $g.DrawLine($penGrid, $gx, $p7T, $gx, $p7B)
    $g.DrawString("$qt", $fAxis, $bLight, ($gx - 10), ($p7B + 8))
}
$omzTicks = @(
    @{ V=10000; L="10rb" }, @{ V=100000; L="100rb" }, @{ V=240000; L="240rb (Med)" },
    @{ V=1000000; L="1 Jt" }, @{ V=5620000; L="5,6 Jt" },
    @{ V=20000000; L="20 Jt" }, @{ V=54907000; L="54,9 Jt" }
)
foreach ($ot in $omzTicks) {
    $gy = Map-P7Y $ot.V
    $g.DrawLine($penGrid, $p7L, $gy, $p7R, $gy)
    $g.DrawString($ot.L, $fAxis, $bLight, ($p7L - 85), ($gy - 8))
}
$g.DrawLine($penAxis, $p7L, $p7B, $p7R, $p7B)
$g.DrawLine($penAxis, $p7L, $p7T, $p7L, $p7B)
$g.DrawString("Kuantitas Pembelian per Baris - QTY (Skala Logaritmik)", $fAxisB, $bDark, 480, ($p7B + 36))

$gy15IQR = Map-P7Y 5623413
$gy30IQR = Map-P7Y 54907061
$gx3SDQ  = Map-P7X 47.8
$g.DrawLine($pDashW, $p7L, $gy15IQR, $p7R, $gy15IQR)
$g.DrawLine($pDashC, $p7L, $gy30IQR, $p7R, $gy30IQR)
$g.DrawLine($pDashW, $gx3SDQ, $p7T, $gx3SDQ, $p7B)

$step = 0
foreach ($r in $df) {
    $step++
    $qv = [double]$r.QTY
    $ov = [double]$r.OMZET
    $isExt = ($ov -ge 18000000) -or ($qv -ge 150)
    $isMod = ($ov -ge 5623413) -or ($qv -ge 47.8)
    if (-not $isExt -and -not $isMod -and ($step % 4 -ne 0)) { continue }
    $px = Map-P7X $qv
    $py = Map-P7Y $ov
    if ($isExt) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 240)
        $g.FillEllipse($br, ($px - 6), ($py - 6), 12, 12)
        $br.Dispose()
    } elseif ($isMod) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#F59E0B" 200)
        $g.FillEllipse($br, ($px - 4), ($py - 4), 8, 8)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 90)
        $g.FillEllipse($br, ($px - 3), ($py - 3), 6, 6)
        $br.Dispose()
    }
}

$leg7 = @(
    @{ Label="Transaksi Normal (Inlier)"; Color="#94A3B8"; Shape="circle" },
    @{ Label="Outlier Nilai Baris Log-IQR 1.5x (> Rp 5,62 Jt)"; Color="#F59E0B"; Shape="circle" },
    @{ Label="Outlier Nilai Ekstrem Log-IQR 3.0x (> Rp 54,9 Jt)"; Color="#E11D48"; Shape="circle" },
    @{ Label="Pagar Moderat Log-IQR 1.5x (Rp 5,62 Jt)"; Color="#F59E0B"; Shape="dash" },
    @{ Label="Pagar Ekstrem S04 Log-IQR 3.0x (Rp 54,9 Jt)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Pagar Kuantitas Ekstrem QTY > 3*SD (47,8 Unit)"; Color="#F59E0B"; Shape="dash" }
)
Draw-LegendBox $g 1140 150 335 190 $leg7 "LEGENDA OUTLIER BARIS"

$p7.Bitmap.Save("$rawDir\raw_07_transaksi_scatter_qty_omzet.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p7.Bitmap.Dispose()
Write-Output "Saved raw_07_transaksi_scatter_qty_omzet.png"

# ==============================================================================
# RAW 08: 2D SCATTER KERANJANG STRUK NOTA HARIAN DENGAN LEGEND
# ==============================================================================
$p8 = New-PlotCanvas 1500 900 "Deteksi Keranjang Struk Nota Outlier (Level Struk Harian: TGL + PELANGGAN)" `
    "N = 1.495 Struk Kunjungan  |  Jumlah Variasi Item SKU vs Total Nilai Struk  |  Single-SKU vs Multi-SKU"
$g = $p8.Graphics

$b8L = 120.0; $b8R = 1120.0; $b8T = 130.0; $b8B = 800.0
function Map-B8X($nItems) { return [float]($b8L + ($nItems / 42.0) * ($b8R - $b8L)) }
function Map-B8Y($totJt)  { return [float]($b8B - ($totJt / 68.0) * ($b8B - $b8T)) }

for ($ni = 0; $ni -le 40; $ni += 5) {
    $gx = Map-B8X $ni
    $g.DrawLine($penGrid, $gx, $b8T, $gx, $b8B)
    $g.DrawString("$ni", $fAxis, $bLight, ($gx - 8), ($b8B + 8))
}
for ($oj = 0; $oj -le 65; $oj += 10) {
    $gy = Map-B8Y $oj
    $g.DrawLine($penGrid, $b8L, $gy, $b8R, $gy)
    $g.DrawString("$oj Jt", $fAxis, $bLight, ($b8L - 55), ($gy - 8))
}
$g.DrawLine($penAxis, $b8L, $b8B, $b8R, $b8B)
$g.DrawLine($penAxis, $b8L, $b8T, $b8L, $b8B)
$g.DrawString("Jumlah Variasi Item Barang per Struk Nota (SKU Count)", $fAxisB, $bDark, 460, ($b8B + 36))

$gyB3SD = Map-B8Y 21.46
$gxBIQR = Map-B8X 13.5
$g.DrawLine($pDashC, $b8L, $gyB3SD, $b8R, $gyB3SD)
$g.DrawLine($pDashW, $gxBIQR, $b8T, $gxBIQR, $b8B)

$baskets = $df | Group-Object TGL, PELANGGAN | ForEach-Object {
    $items = $_.Group
    $tot_omzet = ($items | ForEach-Object { [double]$_.OMZET } | Measure-Object -Sum).Sum
    [PSCustomObject]@{ Key = $_.Name; N_Items = $items.Count; Tot_Jt = $tot_omzet / 1e6 }
}

foreach ($bs in $baskets) {
    $px = Map-B8X $bs.N_Items
    $py = Map-B8Y $bs.Tot_Jt
    $isBig = ($bs.Tot_Jt -ge 21.46) -or ($bs.N_Items -ge 25)
    $isMid = ($bs.Tot_Jt -ge 6.385) -or ($bs.N_Items -ge 14)
    if ($isBig) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48" 240)
        $g.FillEllipse($br, ($px - 6.5), ($py - 6.5), 13, 13)
        $br.Dispose()
    } elseif ($isMid) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#F59E0B" 200)
        $g.FillEllipse($br, ($px - 4.5), ($py - 4.5), 9, 9)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#94A3B8" 110)
        $g.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    }
}

$leg8 = @(
    @{ Label="Struk Nota Reguler (Inlier)"; Color="#94A3B8"; Shape="circle" },
    @{ Label="Struk Outlier Ekstrem (> 3*SD = Rp 21,5 Jt / >25 Item)"; Color="#E11D48"; Shape="circle" },
    @{ Label="Struk Outlier Moderat (> 1.5*IQR = Rp 6,38 Jt)"; Color="#F59E0B"; Shape="circle" },
    @{ Label="Pagar 3*SD Total Omzet Struk (Rp 21,5 Jt)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Pagar 1.5*IQR Jumlah Item SKU (13,5 Item)"; Color="#F59E0B"; Shape="dash" }
)
Draw-LegendBox $g 1140 150 335 170 $leg8 "LEGENDA OUTLIER KERANJANG"

$p8.Bitmap.Save("$rawDir\raw_08_transaksi_keranjang_struk.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p8.Bitmap.Dispose()
Write-Output "Saved raw_08_transaksi_keranjang_struk.png"

# ==============================================================================
# RAW 09: TIME SERIES OMZET HARIAN DENGAN LEGEND
# ==============================================================================
$p9 = New-PlotCanvas 1500 850 "Time-Series Omzet Penjualan Harian Toko Frozen Food (1 April - 30 September 2020)" `
    "143 Hari Aktif  |  Median Harian = Rp 21,32 Jt  |  Ambang Lonjakan Ekstrem Mean + 3*SD (Rp 127,89 Jt)"
$g = $p9.Graphics

$daily = $df | Group-Object TGL | ForEach-Object {
    $sumO = ($_.Group | ForEach-Object { [double]$_.OMZET } | Measure-Object -Sum).Sum / 1e6
    [PSCustomObject]@{ TGL = $_.Name; Dt = [datetime]::Parse($_.Name); OmzetJt = $sumO; TxCnt = $_.Count }
} | Sort-Object Dt

$t9L = 120.0; $t9R = 1120.0; $t9T = 130.0; $t9B = 760.0
$minDt = [datetime]::Parse("2020-04-01")
$maxDt = [datetime]::Parse("2020-09-30")
$totDays = ($maxDt - $minDt).TotalDays

function Map-T9X($dt) { return [float]($t9L + (($dt - $minDt).TotalDays / $totDays) * ($t9R - $t9L)) }
function Map-T9Y($omJt) { return [float]($t9B - ($omJt / 205.0) * ($t9B - $t9T)) }

foreach ($mStr in @("2020-04-01", "2020-05-01", "2020-06-01", "2020-07-01", "2020-08-01", "2020-09-01", "2020-09-30")) {
    $mdt = [datetime]::Parse($mStr)
    $gx = Map-T9X $mdt
    $g.DrawLine($penGrid, $gx, $t9T, $gx, $t9B)
    $g.DrawString($mdt.ToString("dd MMM"), $fAxis, $bLight, ($gx - 18), ($t9B + 8))
}
for ($yv = 0; $yv -le 200; $yv += 40) {
    $gy = Map-T9Y $yv
    $g.DrawLine($penGrid, $t9L, $gy, $t9R, $gy)
    $g.DrawString("$yv Jt", $fAxis, $bLight, ($t9L - 55), ($gy - 8))
}
$g.DrawLine($penAxis, $t9L, $t9B, $t9R, $t9B)
$g.DrawLine($penAxis, $t9L, $t9T, $t9L, $t9B)
$g.DrawString("Kronologi Waktu Transaksi (April s.d. September 2020)", $fAxisB, $bDark, 480, ($t9B + 36))

$gyMed9 = Map-T9Y 21.32
$gyZ5_9 = Map-T9Y 127.89
$pMed9 = New-Object System.Drawing.Pen ((New-Color "#0284C7"), 2.0); $pMed9.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$g.DrawLine($pMed9, $t9L, $gyMed9, $t9R, $gyMed9)
$g.DrawLine($pDashC, $t9L, $gyZ5_9, $t9R, $gyZ5_9)

$pts9 = New-Object 'System.Drawing.PointF[]' $daily.Count
for ($i = 0; $i -lt $daily.Count; $i++) {
    $pts9[$i] = New-Object System.Drawing.PointF((Map-T9X $daily[$i].Dt), (Map-T9Y $daily[$i].OmzetJt))
}
$pLine9 = New-Object System.Drawing.Pen ((New-Color "#64748B" 180), 1.8)
$g.DrawLines($pLine9, $pts9)

foreach ($d in $daily) {
    $px = Map-T9X $d.Dt
    $py = Map-T9Y $d.OmzetJt
    if ($d.TGL -eq "2020-08-30") {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#D97706")
        $g.FillEllipse($br, ($px - 7), ($py - 7), 14, 14)
        $br.Dispose()
    } elseif ($d.OmzetJt -gt 127.89) {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#E11D48")
        $g.FillEllipse($br, ($px - 7), ($py - 7), 14, 14)
        $br.Dispose()
    } else {
        $br = New-Object System.Drawing.SolidBrush (New-Color "#0284C7" 160)
        $g.FillEllipse($br, ($px - 3.5), ($py - 3.5), 7, 7)
        $br.Dispose()
    }
}

$leg9 = @(
    @{ Label="Omzet Penjualan Harian Reguler"; Color="#0284C7"; Shape="circle" },
    @{ Label="Hari Lonjakan Omzet Ekstrem (Mean + 3*SD)"; Color="#E11D48"; Shape="circle" },
    @{ Label="Transaksi Anomali Hari Minggu (Toko Tutup)"; Color="#D97706"; Shape="circle" },
    @{ Label="Ambang Lonjakan Ekstrem (Rp 127,9 Jt)"; Color="#E11D48"; Shape="dash" },
    @{ Label="Median Omzet Harian (Rp 21,3 Jt)"; Color="#0284C7"; Shape="dash" },
    @{ Label="Fluktuasi Time-Series Harian"; Color="#64748B"; Shape="line" }
)
Draw-LegendBox $g 1140 150 335 190 $leg9 "LEGENDA TIME-SERIES"

$p9.Bitmap.Save("$rawDir\raw_09_transaksi_timeseries_harian.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p9.Bitmap.Dispose()
Write-Output "Saved raw_09_transaksi_timeseries_harian.png"

# ==============================================================================
# RAW 10: BAR CHART DISTRIBUSI HARI OPERASIONAL DENGAN LEGEND
# ==============================================================================
$p10 = New-PlotCanvas 1500 850 "Distribusi Aktivitas Transaksi Menurut Hari Operasional Mingguan (T02)" `
    "Total Transaksi & Nilai Omzet per Hari  |  25 dari 26 Hari Minggu Toko Tutup (Bukti Anomali Hari Minggu)"
$g = $p10.Graphics

$dowData = @(
    @{ Day="Senin (Monday)";     Active="21 / 26 hr"; Tx=1198; Omz="Rp 850,4 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Selasa (Tuesday)";   Active="24 / 26 hr"; Tx=1052; Omz="Rp 724,1 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Rabu (Wednesday)";   Active="26 / 27 hr"; Tx=1141; Omz="Rp 814,8 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Kamis (Thursday)";   Active="23 / 26 hr"; Tx=1102; Omz="Rp 712,5 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Jumat (Friday)";     Active="23 / 26 hr"; Tx=1066; Omz="Rp 775,2 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Sabtu (Saturday)";   Active="25 / 26 hr"; Tx=1180; Omz="Rp 743,9 Jt"; Col="#0284C7"; IsSun=$false },
    @{ Day="Minggu (Sunday)*";   Active="1 / 26 hr!"; Tx=1;    Omz="Rp 0,18 Jt!"; Col="#E11D48"; IsSun=$true }
)

$dy10 = 150; $rowH10 = 80; $maxBarW10 = 620.0
for ($i = 0; $i -lt $dowData.Count; $i++) {
    $dw = $dowData[$i]
    $y = $dy10 + $i * $rowH10
    if ($dw.IsSun) {
        $bBgRow = New-Object System.Drawing.SolidBrush (New-Color "#FFF1F2")
        $pBdRow = New-Object System.Drawing.Pen ((New-Color "#E11D48"), 1.5)
        $pathRow = New-RoundedRect 80 ($y - 6) 1030 68 8
        $g.FillPath($bBgRow, $pathRow)
        $g.DrawPath($pBdRow, $pathRow)
        $bBgRow.Dispose(); $pBdRow.Dispose(); $pathRow.Dispose()
    } else {
        $bBgRow = New-Object System.Drawing.SolidBrush (New-Color "#F8FAFC")
        $pBdRow = New-Object System.Drawing.Pen ((New-Color "#E2E8F0"), 1.0)
        $pathRow = New-RoundedRect 80 ($y - 6) 1030 68 8
        $g.FillPath($bBgRow, $pathRow)
        $g.DrawPath($pBdRow, $pathRow)
        $bBgRow.Dispose(); $pBdRow.Dispose(); $pathRow.Dispose()
    }

    $g.DrawString($dw.Day, $fAxisB, $bDark, 100, $y)
    $g.DrawString("Aktif: $($dw.Active)", $fSm, $bMuted, 100, ($y + 26))

    $bw = [math]::Max(8.0, ($dw.Tx / 1250.0) * $maxBarW10)
    $bBar10 = New-Object System.Drawing.SolidBrush (New-Color $dw.Col)
    $pathB10 = New-RoundedRect 380 ($y + 8) $bw 26 4
    $g.FillPath($bBar10, $pathB10)
    $bBar10.Dispose(); $pathB10.Dispose()

    $txtInfo = "$($dw.Tx) Transaksi  |  $($dw.Omz)"
    $g.DrawString($txtInfo, $fAxisB, (New-Object System.Drawing.SolidBrush (New-Color $dw.Col)), (390 + $bw + 10), ($y + 12))
}

$leg10 = @(
    @{ Label="Hari Operasional Resmi Toko (Senin - Sabtu)"; Color="#0284C7"; Shape="box" },
    @{ Label="Hari Tutup Operasional Toko (Hari Minggu)"; Color="#E11D48"; Shape="box" }
)
Draw-LegendBox $g 1140 180 335 110 $leg10 "LEGENDA STATUS OPERASIONAL"

$p10.Bitmap.Save("$rawDir\raw_10_transaksi_hari_operasional.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $p10.Bitmap.Dispose()
Write-Output "Saved raw_10_transaksi_hari_operasional.png"
