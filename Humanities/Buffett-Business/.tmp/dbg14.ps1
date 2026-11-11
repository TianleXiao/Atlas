$ErrorActionPreference = 'Stop'
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$nonBlank = @($lines | Where-Object { $_.Trim() -ne '' })
Write-Host "nonBlank=$($nonBlank.Count) type=$($nonBlank.GetType().Name)"
if ($nonBlank.Count -ge 1) { Write-Host " [0]=[$($nonBlank[0])]" }
$sepIdx = @()
for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq '---') { $sepIdx += $i } }
Write-Host "sepIdx=$($sepIdx.Count) vals=$($sepIdx -join ',')"
$probe = @(0..2)
Write-Host "probe=$($probe.Count)"
$probe2 = @($sepIdx | ForEach-Object { $_ })
Write-Host "probe2=$($probe2.Count)"