# Setsid: one-shot vault formatter (ponytail: single-pass, idempotent; re-run any time, no args).
# Rule: each module separated by a bare `---` line = one heading line, its images directly under it, then the extracted text.
$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business'

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

$files = Get-ChildItem -Path $root -Recurse -File -Filter '*.md' | Where-Object { $_.FullName -notmatch '\\\.' } | Sort-Object Name
$changed = 0
foreach ($f in $files) {
  $text = [System.IO.File]::ReadAllText($f.FullName)
  $lines = @($text -split "`r?`n")
  Write-Host "READ $($f.Name) len=$($text.Length) first=[$(($text -split "`n")[0])]"; $before = 0
  $imgsBefore = 0
  foreach ($x in $lines) {
    if ((Is-EmptyLine $x) -or (Is-Sep $x)) { continue }
    $before++
    if (Is-Img $x) { $imgsBefore++ }
  }
  $segs = Split-Segs $lines
  $pile = New-Object System.Collections.Generic.List[string]
  $kept = 0
  foreach ($seg in $segs) {
    $fixed = Fix-Blk $seg
    if ($fixed.Count -eq 0) { continue }
    if ($kept -gt 0) { $pile.Add(''); $pile.Add('---'); $pile.Add('') }
    foreach ($y in $fixed) { $pile.Add([string]$y) }
    $kept++
  }
  $outLines = $pile.ToArray()
  $after = 0
  $imgsAfter = 0
  foreach ($x in $outLines) {
    if ((Is-EmptyLine $x) -or (Is-Sep $x)) { continue }
    $after++
    if (Is-Img $x) { $imgsAfter++ }
  }
  if ($before -ne $after -or $imgsBefore -ne $imgsAfter) {
    Write-Host ("DRIFT {0}: lines {1}->{2} imgs {3}->{4}" -f $f.Name, $before, $after, $imgsBefore, $imgsAfter)
    continue
  }
  $new = (($outLines -join "`n").TrimEnd()) + "`n"
  if ($new -ne $text) {
    [System.IO.File]::WriteAllText($f.FullName, $new)
    $changed++
    Write-Host ("FIXED {0}" -f $f.Name)
  }
}
Write-Host "changed=$changed of $($files.Count)"
