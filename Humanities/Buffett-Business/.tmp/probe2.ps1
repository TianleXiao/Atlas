# Setsid: one-shot vault formatter. Rule: module = heading, its images, extracted text; bare --- separates modules.
$ErrorActionPreference = 'Stop'
$unused = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business'
$imgRe = '^!\[[^\]]*\]\(.+\)\s*$'
$wikiRe = '^!\[\[.+\]\]\s*$'
function IsImg([string]$s) { return ($s.Trim() -match $imgRe) -or ($s.Trim() -match $wikiRe) }
function IsHead([string]$s) { return $s -match '^\s*#{1,6}\s+\S' }
function Split-Into([string[]]$lines, [string]$sep) {
  $out = New-Object System.Collections.Generic.List[string[]]
  $cur = New-Object System.Collections.Generic.List[string]
  foreach ($x in $lines) {
    if ($x -match $sep) { $out.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
    else { $cur.Add($x) }
  }
  $out.Add($cur.ToArray())
  return , $out
}
function Strip-Blanks([string[]]$b) {
  $s = 0
  while ($s -lt $b.Count -and $b[$s].Trim() -eq '') { $s++ }
  $e = $b.Count - 1
$t = [string[]]@('![[a.png]]','','---','','## H','x')
$a = @($t | Where-Object { $_.Trim() -ne '' })
Write-Host "A=$($a.Count) t0=$($a[0].GetType().Name) [$($a -join '/')]"
$s = Split-Into $t '^\s*---\s*$'
Write-Host "segs=$($s.Count) s0=$($s[0].Count)"
$b = @($s[0] | Where-Object { $_.Trim() -ne '' })
Write-Host "B=$($b.Count) t0=$($b[0].GetType().Name)"
function Probe([string[]]$lines) {
  $x = @($lines | Where-Object { $_.Trim() -ne '' })
  Write-Host "inFunc=$($x.Count) t0=$($x[0].GetType().Name)"
}
Probe $t