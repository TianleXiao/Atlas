function Is-EmptyLine($x) { return (([string]$x).Trim() -eq '') }
function Is-Sep($x) { return ([string]$x).Trim() -eq '---' }
function Is-Img($x) {
  $s = ([string]$x).Trim()
  return ($s -match '^!\[[^\]]*\]\(.+\)$') -or ($s -match '^!\[\[.+\]\]$')
}
function Is-Head($x) { return ([string]$x) -match '^\s*#{1,6}\s+\S' }

function Split-Segs($lines) {
  $segs = New-Object System.Collections.Generic.List[object]
  $cur = New-Object System.Collections.Generic.List[string]
  foreach ($x in $lines) {
    if (Is-Sep $x) { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
    else { $cur.Add([string]$x) }
  }
  $segs.Add($cur.ToArray())
  return , $segs
}

function Trim-Blk($arr) {
  $n = $arr.Count
  $s = 0
  while ($s -lt $n -and (Is-EmptyLine $arr[$s])) { $s++ }
  $e = $n - 1
  while ($e -ge $s -and (Is-EmptyLine $arr[$e])) { $e-- }
  if ($e -lt $s) { return , @() }
  return , @($arr[$s..$e])
}

function Fix-Blk($arr) {
  $b = Trim-Blk $arr
  if ($b.Count -eq 0) { return , $b }
  $imgs = New-Object System.Collections.Generic.List[string]
  $txt = New-Object System.Collections.Generic.List[string]
  foreach ($x in $b) {
    if (Is-Img $x) { $imgs.Add([string]$x) } else { $txt.Add([string]$x) }
  }
  if ($imgs.Count -eq 0) { return , $b }
  $t = Trim-Blk $txt.ToArray()
  if ($t.Count -eq 0) { return , $imgs.ToArray() }
  $out = New-Object System.Collections.Generic.List[string]
  $out.Add([string]$t[0])
  foreach ($m in $imgs) { $out.Add($m) }
  for ($i = 1; $i -lt $t.Count; $i++) { $out.Add([string]$t[$i]) }
  return , (Trim-Blk $out.ToArray())
}


$t = @('![[a.png]]','','---','','## H','x')
$segs = Split-Segs $t
Write-Host "segs=$($segs.Count) s0count=$($segs[0].Count) s0t0=[$($segs[0][0])]"
$fb = Fix-Blk $segs[0]
Write-Host "fb count=$($fb.Count) [0]=[$($fb[0])]"
$pile = New-Object System.Collections.Generic.List[string]
$kept = 0
foreach ($seg in $segs) {
  $fixed = Fix-Blk $seg
  Write-Host "  seg fixed count=$($fixed.Count)"
  if ($fixed.Count -eq 0) { continue }
  if ($kept -gt 0) { $pile.Add(''); $pile.Add('---'); $pile.Add('') }
  foreach ($y in $fixed) { $pile.Add([string]$y) }
  $kept++
}
Write-Host "pile=$($pile.Count)"
for ($i=0; $i -lt $pile.Count; $i++) { Write-Host "  $i [$($pile[$i])]" }