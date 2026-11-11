$ErrorActionPreference = 'Stop'
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$sepIdx = @()
for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq '---') { $sepIdx += $i } }
Write-Host "seps=$($sepIdx.Count)"
$probe = @(0..2)
Write-Host "probe=$($probe.Count)"
$probe10 = @(0..9)
Write-Host "probe10=$($probe10.Count)"