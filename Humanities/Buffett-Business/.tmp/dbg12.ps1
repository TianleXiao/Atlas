$ErrorActionPreference = 'Stop'
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.3.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$b = @($lines | Where-Object { $_.Trim() -ne '' })
Write-Host "B=$($b.Count)"
$h = @{}
foreach ($x in $b) { $h[$x] = 1 + $(if ($h.ContainsKey($x)) { $h[$x] } else { 0 }) }
# manual segmentation + blank rebuild (no reorder yet): count nonblank after removing consecutive duplicate '---' separators
$kept = @($lines | Where-Object { $_.Trim() -ne '' })
Write-Host "kept=$($kept.Count)"
$dup = @($kept | Group-Object | Where-Object { $_.Count -gt 1 })
Write-Host "dupLines=$($dup.Count)"
$dup | Select-Object -First 5 | ForEach-Object { Write-Host "  dup x$($_.Count): [$($_.Name)]" }