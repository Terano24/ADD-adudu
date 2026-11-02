Add-Type -AssemblyName System.IO.Compression.FileSystem

$pptx = "C:\Users\Terano\Downloads\Week 5 - Find Anomaly.pptx"
Write-Output "==================== $pptx ===================="
if (Test-Path $pptx) {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($pptx)
    $slides = $zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' } | Sort-Object { [int]($_.Name -replace '\D','') }
    foreach ($s in $slides) {
        $stream = $s.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        [xml]$xml = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        $texts = $xml.SelectNodes("//*[local-name()='t']") | ForEach-Object { $_.InnerText } | Where-Object { $_.Trim() -ne "" }
        Write-Output "--- $($s.Name) ---"
        Write-Output ($texts -join " | ")
    }
    $zip.Dispose()
}

$ppt = "C:\Users\Terano\Downloads\Week 7 - OutlierDetection ML.ppt"
Write-Output "==================== $ppt ===================="
if (Test-Path $ppt) {
    $bytes = [System.IO.File]::ReadAllBytes($ppt)
    $unicodeStr = [System.Text.Encoding]::Unicode.GetString($bytes)
    $matchesU = [regex]::Matches($unicodeStr, '[A-Za-z0-9 \-\.,:;?!\(\)/''"\+%=<>]{6,}')
    $seen = @{}
    foreach ($m in $matchesU) {
        $val = $m.Value.Trim()
        if ($val.Length -gt 6 -and -not $seen.ContainsKey($val)) {
            $seen[$val] = $true
            Write-Output "[U16] $val"
        }
    }
    $asciiStr = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($bytes)
    $matchesA = [regex]::Matches($asciiStr, '[A-Za-z0-9 \-\.,:;?!\(\)/''"\+%=<>]{8,}')
    foreach ($m in $matchesA) {
        $val = $m.Value.Trim()
        if ($val.Length -gt 8 -and -not $seen.ContainsKey($val)) {
            $seen[$val] = $true
            Write-Output "[ASC] $val"
        }
    }
}

