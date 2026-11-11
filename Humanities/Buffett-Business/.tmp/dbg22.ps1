$ErrorActionPreference = 'Stop'
function T($x) { return ([string]$x).Trim() }
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$segs = New-Object System.Collections.Generic.List[object]
$cur = New-Object System.Collections.Generic.List[string]
foreach ($x in $lines) {
  if ((T $x) -eq '---') { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
  else { $cur.Add([string]$x) }
}
$segs.Add($cur.ToArray())
$flat = @()
foreach ($seg in $segs) {
  Write-Host "  seg type=$($seg.GetType().Name) count=$($seg.Count)"
  foreach ($v in $seg) { $flat += [string]$v }
  Write-Host "  flat now=$($flat.Count)"
}
Write-Host "flat=$($flat.Count)"