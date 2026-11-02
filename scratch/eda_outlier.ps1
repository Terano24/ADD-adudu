$df = Import-Csv "bersih\penjualan_bersih.csv"
Write-Output "Total clean rows: $($df.Count)"

# Top 15 transactions by OMZET
Write-Output "`n=== TOP 15 TRANSACTIONS BY OMZET ==="
$df | Sort-Object { [double]$_.OMZET } -Descending | Select-Object -First 15 TGL, PELANGGAN, KODE, NAMA_BARANG, QTY, SATUAN, HARGA, OMZET | Format-Table -AutoSize

# Top 15 transactions by QTY
Write-Output "`n=== TOP 15 TRANSACTIONS BY QTY ==="
$df | Sort-Object { [double]$_.QTY } -Descending | Select-Object -First 15 TGL, PELANGGAN, KODE, NAMA_BARANG, QTY, SATUAN, HARGA, OMZET | Format-Table -AutoSize

# Sunday transactions
Write-Output "`n=== SUNDAY TRANSACTIONS ==="
$df | Where-Object { $_.HARI -eq "Sunday" } | Select-Object TGL, HARI, PELANGGAN, KODE, NAMA_BARANG, QTY, SATUAN, HARGA, OMZET | Format-Table -AutoSize

# Customer LRFM summary
$lrfm = Import-Csv "bersih\lrfm_pelanggan.csv"
Write-Output "`nTotal LRFM customers: $($lrfm.Count)"
Write-Output "`n=== TOP 15 CUSTOMERS BY MONETARY ==="
$lrfm | Sort-Object { [double]$_.M } -Descending | Select-Object -First 15 PELANGGAN, L, R, F, M, SEGMEN | Format-Table -AutoSize

# Customers with high AOV (M / F) and low F (e.g. F <= 3)
Write-Output "`n=== TOP 15 CUSTOMERS BY AOV (M/F) WHERE F <= 5 ==="
$lrfm | Where-Object { [int]$_.F -le 5 } | Select-Object PELANGGAN, L, R, F, M, @{Name="AOV";Expression={[math]::Round([double]$_.M / [int]$_.F, 0)}}, SEGMEN | Sort-Object AOV -Descending | Select-Object -First 15 | Format-Table -AutoSize

# Price anomalies from log_anomali.csv
$anom = Import-Csv "bersih\log_anomali.csv"
Write-Output "`n=== LOG ANOMALI S01, S02, S04, A02, T02 ==="
$anom | Where-Object { $_.kode_aturan -in @("S01", "S02", "S04", "A02", "T02") } | Select-Object kode_aturan, BARIS_ASLI, TGL, KODE, NAMA_BARANG, QTY, SATUAN_K, HARGA_FINAL, OMZET_FINAL, PELANGGAN | Format-Table -AutoSize

