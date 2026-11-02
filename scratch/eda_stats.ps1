$df = Import-Csv "bersih\penjualan_bersih.csv"
$lrfm = Import-Csv "bersih\lrfm_pelanggan.csv"

function Get-Stats($arr, $name) {
    $sorted = $arr | Sort-Object
    $n = $sorted.Count
    $sum = ($sorted | Measure-Object -Sum).Sum
    $mean = $sum / $n
    $sqDiff = 0.0
    foreach ($v in $sorted) { $sqDiff += ($v - $mean) * ($v - $mean) }
    $std = [math]::Sqrt($sqDiff / ($n - 1))
    $q1 = $sorted[[int][math]::Floor(($n - 1) * 0.25)]
    $med = $sorted[[int][math]::Floor(($n - 1) * 0.50)]
    $q3 = $sorted[[int][math]::Floor(($n - 1) * 0.75)]
    $iqr = $q3 - $q1
    $absDev = $sorted | ForEach-Object { [math]::Abs($_ - $med) } | Sort-Object
    $mad = $absDev[[int][math]::Floor(($n - 1) * 0.50)] * 1.4826
    $ub_iqr = $q3 + 1.5 * $iqr
    $ub_ext = $q3 + 3.0 * $iqr
    $ub_3s = $mean + 3.0 * $std
    $cnt_iqr = ($sorted | Where-Object { $_ -gt $ub_iqr -or $_ -lt ($q1 - 1.5 * $iqr) }).Count
    $cnt_3s = ($sorted | Where-Object { $_ -gt $ub_3s -or $_ -lt ($mean - 3.0 * $std) }).Count
    Write-Output ("{0,-18} | N={1,4} | Mean={2,12:N2} | SD={3,12:N2} | Med={4,11:N2} | MAD={5,10:N2} | Q1={6,10:N2} | Q3={7,11:N2} | IQR={8,11:N2} | UB_1.5IQR={9,12:N2} (n={10,3}) | UB_3SD={11,12:N2} (n={12,3})" -f $name, $n, $mean, $std, $med, $mad, $q1, $q3, $iqr, $ub_iqr, $cnt_iqr, $ub_3s, $cnt_3s)
}

Write-Output "=== CUSTOMER LRFM STATS (N=180 NAMED CUSTOMERS) ==="
$M_arr = $lrfm | ForEach-Object { [double]$_.M }
$F_arr = $lrfm | ForEach-Object { [double]$_.F }
$R_arr = $lrfm | ForEach-Object { [double]$_.R }
$L_arr = $lrfm | ForEach-Object { [double]$_.L }
$AOV_arr = $lrfm | ForEach-Object { [double]$_.M / [double]$_.F }

Get-Stats $M_arr "Customer M (Rp)"
Get-Stats $F_arr "Customer F (days)"
Get-Stats $R_arr "Customer R (days)"
Get-Stats $L_arr "Customer L (days)"
Get-Stats $AOV_arr "Customer AOV (Rp)"

Write-Output "`n=== TRANSACTION STATS (N=6740 CLEAN ROWS) ==="
$omzet_arr = $df | ForEach-Object { [double]$_.OMZET }
$qty_arr = $df | ForEach-Object { [double]$_.QTY }
$harga_arr = $df | ForEach-Object { [double]$_.HARGA }
$log_omzet = $df | ForEach-Object { [math]::Log10([double]$_.OMZET) }

Get-Stats $omzet_arr "Tx OMZET (Rp)"
Get-Stats $qty_arr "Tx QTY"
Get-Stats $harga_arr "Tx HARGA (Rp)"
Get-Stats $log_omzet "Tx Log10(OMZET)"

# Invoice / Basket level (TGL + PELANGGAN)
$baskets = $df | Group-Object TGL, PELANGGAN | ForEach-Object {
    $items = $_.Group
    $tot_omzet = ($items | ForEach-Object { [double]$_.OMZET } | Measure-Object -Sum).Sum
    $tot_qty = ($items | ForEach-Object { [double]$_.QTY } | Measure-Object -Sum).Sum
    [PSCustomObject]@{
        Key = $_.Name
        N_Items = $items.Count
        Tot_QTY = $tot_qty
        Tot_Omzet = $tot_omzet
    }
}
Write-Output "`n=== BASKET / INVOICE STATS (TGL + PELANGGAN) ==="
Get-Stats ($baskets | ForEach-Object { [double]$_.Tot_Omzet }) "Basket Omzet"
Get-Stats ($baskets | ForEach-Object { [double]$_.Tot_QTY }) "Basket QTY"
Get-Stats ($baskets | ForEach-Object { [double]$_.N_Items }) "Basket Items"
Write-Output "`nTop 10 Baskets by Omzet:"
$baskets | Sort-Object Tot_Omzet -Descending | Select-Object -First 10 | Format-Table -AutoSize

