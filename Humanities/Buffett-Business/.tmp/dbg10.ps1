$ErrorActionPreference = 'Stop'
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.3.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$sepIdx = @()
for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq '---') { $sepIdx += $i } }
Write-Host "seps=$($sepIdx -join ',') total=$($lines.Count)"
$before = @($lines | Where-Object { $_.Trim() -ne '' })
$after = @(($lines -split "`r?`n") | Where-Object { $_.Trim() -ne '' })
Write-Host "before=$($before.Count)"
$nf = @($lines | Where-Object { $_.Trim() -ne '' })
Write-Host "nf count=$($nf.Count)"
Write-Host "lines with CR: $(@($lines | Where-Object { $_ -match "`r" }).Count)"