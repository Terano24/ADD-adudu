$df = Import-Csv "bersih\penjualan_bersih.csv"
$lrfm = Import-Csv "bersih\lrfm_pelanggan.csv"

# 1. Compute Customer features: L, R, F, M, AOV, Tot_QTY, N_SKU
$custStats = @{}
foreach ($row in $df) {
    $p = $row.PELANGGAN
    if (-not $custStats.ContainsKey($p)) {
        $custStats[$p] = @{ Tot_QTY = 0.0; Tx_Count = 0; SKUs = @{} }
    }
    $custStats[$p].Tot_QTY += [double]$row.QTY
    $custStats[$p].Tx_Count += 1
    $custStats[$p].SKUs[$row.KODE] = $true
}

$custList = @()
foreach ($c in $lrfm) {
    $p = $c.PELANGGAN
    $L = [double]$c.L
    $R = [double]$c.R
    $F = [double]$c.F
    $M = [double]$c.M
    $aov = $M / $F
    $tqty = if ($custStats.ContainsKey($p)) { $custStats[$p].Tot_QTY } else { 0.0 }
    $nsku = if ($custStats.ContainsKey($p)) { $custStats[$p].SKUs.Count } else { 1 }
    $custList += [PSCustomObject]@{
        PELANGGAN = $p
        L = $L; R = $R; F = $F; M = $M; AOV = $aov
        Tot_QTY = $tqty; N_SKU = $nsku; SEGMEN = $c.SEGMEN
        LogF = [math]::Log10($F + 1)
        LogM = [math]::Log10($M)
        LogAOV = [math]::Log10($aov)
        R_norm = $R / 180.0
    }
}

# Standardize features (LogF, LogM, LogAOV, R_norm)
$feats = @("LogF", "LogM", "LogAOV", "R_norm")
$means = @{}; $stds = @{}
foreach ($f in $feats) {
    $vals = $custList | ForEach-Object { $_.$f }
    $m = ($vals | Measure-Object -Average).Average
    $sq = 0.0; foreach ($v in $vals) { $sq += ($v - $m)*($v - $m) }
    $s = [math]::Sqrt($sq / ($vals.Count - 1))
    $means[$f] = $m; $stds[$f] = $s
}

$n = $custList.Count
$coords = New-Object 'double[,]' $n, 4
for ($i = 0; $i -lt $n; $i++) {
    for ($j = 0; $j -lt 4; $j++) {
        $f = $feats[$j]
        $coords[$i, $j] = ($custList[$i].$f - $means[$f]) / $stds[$f]
    }
}

# Distance matrix & k-NN (k=5) + LOF (k=5)
$k = 5
$distMat = New-Object 'double[,]' $n, $n
$knnDist = New-Object 'double[]' $n
$kDist = New-Object 'double[]' $n
$neighbors = New-Object 'object[]' $n

for ($i = 0; $i -lt $n; $i++) {
    $dList = @()
    for ($m = 0; $m -lt $n; $m++) {
        if ($i -eq $m) { $distMat[$i, $m] = 0.0; continue }
        $sumSq = 0.0
        for ($j = 0; $j -lt 4; $j++) {
            $diff = $coords[$i, $j] - $coords[$m, $j]
            $sumSq += $diff * $diff
        }
        $d = [math]::Sqrt($sumSq)
        $distMat[$i, $m] = $d
        $dList += [PSCustomObject]@{ Idx = $m; Dist = $d }
    }
    $sortedD = $dList | Sort-Object Dist | Select-Object -First $k
    $neighbors[$i] = $sortedD
    $knnDist[$i] = ($sortedD | ForEach-Object { $_.Dist } | Measure-Object -Average).Average
    $kDist[$i] = $sortedD[$k - 1].Dist
}

# LRD (Local Reachability Density)
$lrd = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $sumReach = 0.0
    foreach ($nb in $neighbors[$i]) {
        $o = $nb.Idx
        $reach = [math]::Max($kDist[$o], $nb.Dist)
        $sumReach += $reach
    }
    $lrd[$i] = $k / ($sumReach + 1e-9)
}

# LOF
for ($i = 0; $i -lt $n; $i++) {
    $sumRatio = 0.0
    foreach ($nb in $neighbors[$i]) {
        $o = $nb.Idx
        $sumRatio += ($lrd[$o] / $lrd[$i])
    }
    $lofScore = $sumRatio / $k
    $custList[$i] | Add-Member -NotePropertyName "KNN_Dist" -NotePropertyValue ([math]::Round($knnDist[$i], 3))
    $custList[$i] | Add-Member -NotePropertyName "LOF_Score" -NotePropertyValue ([math]::Round($lofScore, 3))
}

Write-Output "=== TOP 20 CUSTOMERS BY LOF SCORE ==="
$custList | Sort-Object LOF_Score -Descending | Select-Object -First 20 PELANGGAN, F, R, L, @{N="M_Juta";E={[math]::Round($_.M/1e6,2)}}, @{N="AOV_Juta";E={[math]::Round($_.AOV/1e6,2)}}, KNN_Dist, LOF_Score, SEGMEN | Format-Table -AutoSize

Write-Output "=== TOP 20 CUSTOMERS BY KNN DISTANCE ==="
$custList | Sort-Object KNN_Dist -Descending | Select-Object -First 20 PELANGGAN, F, R, L, @{N="M_Juta";E={[math]::Round($_.M/1e6,2)}}, @{N="AOV_Juta";E={[math]::Round($_.AOV/1e6,2)}}, KNN_Dist, LOF_Score, SEGMEN | Format-Table -AutoSize

