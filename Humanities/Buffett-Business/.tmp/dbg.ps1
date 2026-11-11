# Setsid: one-shot vault formatter. Rule: module = heading, its images, extracted text; bare --- separates modules.
$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business'
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
  while ($e -ge $s -and $b[$e].Trim() -eq '') { $e-- }
  if ($e -lt $s) { return , [string[]]@() }
  return , [string[]]$b[$s..$e]
}
function Fix-Block([string[]]$raw) {
  $b = Strip-Blanks $raw
  if ($b.Count -eq 0) { return , [string[]]@() }
  $imgs = New-Object System.Collections.Generic.List[string]
  $rest = New-Object System.Collections.Generic.List[string]
  foreach ($x in $b) { if (IsImg $x) { $imgs.Add($x) } else { $rest.Add($x) } }
  if ($imgs.Count -eq 0) { return , $b }
  $r = Strip-Blanks $rest.ToArray()
  if ($r.Count -eq 0) { return , $imgs.ToArray() }
  $out = New-Object System.Collections.Generic.List[string]
  $out.Add($r[0])
  foreach ($m in $imgs) { $out.Add($m) }
  for ($i = 1; $i -lt $r.Count; $i++) { $out.Add($r[$i]) }
  return , (Strip-Blanks $out.ToArray())
}
$files = Get-ChildItem -Path $root -Recurse -File -Filter '*.md' | Where-Object { $_.FullName -notmatch '\\\.' }
$changed = 0
foreach ($f in $files) {
  $text = [System.IO.File]::ReadAllText($f.FullName)
  $lines = [string[]]($text -split "`r?`n") ; Write-Host "DBG $($f.Name) split=$($lines.Count) first=[$($lines[0])]"
  $before = @($lines | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^\s*---\s*$' })
  $segs = Split-Into $lines '^\s*---\s*$'
  $blocks = New-Object System.Collections.Generic.List[string[]]
  for ($i = 0; $i -lt $segs.Count; $i++) {
    $fixed = Fix-Block ([string[]]$segs[$i])
    $fixed = Strip-Blanks $fixed
    if ($fixed.Count -gt 0) { $blocks.Add($fixed) }
  }
  $pile = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $blocks.Count; $i++) {
    $blk = $blocks[$i]
    foreach ($y in $blk) { $pile.Add($y) }
    if ($i -lt $blocks.Count - 1) { $pile.Add('') ; $pile.Add('---'); $pile.Add('') }
  }
  $newLines = $pile.ToArray()
  $after = @($newLines | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^\s*---\s*$' })
  $imgsBefore = @($before | Where-Object { IsImg $_ }).Count
  $imgsAfter = @($after | Where-Object { IsImg $_ }).Count
  if ($before.Count -ne $after.Count -or $imgsBefore -ne $imgsAfter) { throw ("line/image count drift in {0}: {1}/{2} -> {3}/{4}" -f $f.Name, $before.Count, $imgsBefore, $after.Count, $imgsAfter) }
  $out = ($newLines -join "`n").TrimEnd() + "`n"
  Write-Host "CMP $($f.Name) eq=$($out -eq $text) newFirst=[$(($out -split "`n")[0])]"; if ($out -ne $text) { [System.IO.File]::WriteAllText($f.FullName, $out); $changed++ }
}
Write-Output "changed=$changed of $($files.Count)"