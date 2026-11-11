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
Write-Host "segs=$($segs.Count) s0=$($segs[0].Count) s1=$($segs[1].Count)"
$flat = @()
$flat += $segs[0]
Write-Host "after seg0 flat=$($flat.Count)"
$flat += $segs[1]
Write-Host "after seg1 flat=$($flat.Count) expected=$($segs[0].Count + $segs[1].Count)"
$flat2 = New-Object System.Collections.Generic.List[string]
foreach ($m in $segs[0]) { $flat2.Add($m) }
foreach ($m in $segs[1]) { $flat2.Add($m) }
Write-Host "flat2=$($flat2.Count)"