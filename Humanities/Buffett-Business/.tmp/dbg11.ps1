$ErrorActionPreference = 'Stop'
$imgRe = '^!\[[^\]]*\]\(.+\)$'
$wikiRe = '^!\[\[.+\]\]$'
function T($x) { return ([string]$x).Trim() }
function Is-Img($x) { $s = T $x; return ($s -match $imgRe) -or ($s -match $wikiRe) }
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.3.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$segs = New-Object System.Collections.Generic.List[object]
$cur = New-Object System.Collections.Generic.List[string]
foreach ($x in $lines) {
  if ((T $x) -eq '---') { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
  else { $cur.Add([string]$x) }
}
$segs.Add($cur.ToArray())
Write-Host "segs=$($segs.Count)"
$blk = @()
for ($i=0; $i -lt $segs.Count; $i++) {
  $s = $segs[$i]
  $cnt = @($s | Where-Object { (T $_) -ne '' }).Count
  $raw = @($s).Count
  Write-Host " seg$i raw=$raw nonblank=$cnt"
  foreach ($v in $s) { if ((T $v) -ne '') { $blk += $v } }
}
Write-Host "blk=$($blk.Count)"
$uniq = @($blk | Sort-Object -Unique).Count
Write-Host "uniq=$uniq"