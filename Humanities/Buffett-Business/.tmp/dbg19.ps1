$ErrorActionPreference = 'Stop'
function T($x) { return ([string]$x).Trim() }
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
Write-Host "lines=$($lines.Count)"
$segs = New-Object System.Collections.Generic.List[object]
$cur = New-Object System.Collections.Generic.List[string]
foreach ($x in $lines) {
  if ((T $x) -eq '---') { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
  else { $cur.Add([string]$x) }
}
$segs.Add($cur.ToArray())
$flat = @()
foreach ($seg in $segs) { foreach ($v in $seg) { $flat += [string]$v } }
Write-Host "flat=$($flat.Count)"
$b = @($lines | Where-Object { (T $_) -ne '' })
$f2 = @($flat | Where-Object { (T $_) -ne '' })
Write-Host "b=$($b.Count) f2=$($f2.Count)"
foreach ($x in $b) { if (-not ($flat -contains $x)) { Write-Host "  MISSING in flat: [$x]" } }
foreach ($x in $flat) { if (-not ($lines -contains $x)) { Write-Host "  EXTRA in flat: [$x]" } }