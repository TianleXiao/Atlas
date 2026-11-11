$ErrorActionPreference = 'Stop'
$imgRe = '^!\[[^\]]*\]\(.+\)$'
$wikiRe = '^!\[\[.+\]\]$'
function T($x) { return ([string]$x).Trim() }
function Is-Img($x) { $s = T $x; return ($s -match $imgRe) -or ($s -match $wikiRe) }
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$segs = New-Object System.Collections.Generic.List[object]
$cur = New-Object System.Collections.Generic.List[string]
foreach ($x in $lines) {
  if ((T $x) -eq '---') { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
  else { $cur.Add([string]$x) }
}
$segs.Add($cur.ToArray())
Write-Host "segs=$($segs.Count)"
$cnt = 0
foreach ($seg in $segs) {
  $n = @($seg | Where-Object { (T $_) -ne '' }).Count
  Write-Host "  seg n=$n"
  $cnt = $cnt + $n
}
Write-Host "sum=$cnt expected=15"
$cnt2 = 0
foreach ($seg in $segs) { foreach ($v in $seg) { if ((T $v) -ne '') { $cnt2++ } } }
Write-Host "sum2=$cnt2"