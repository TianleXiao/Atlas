# Setsid: one-shot vault formatter (ponytail: single pass, idempotent; re-run any time, no args).
# Rule: a module (segment between bare `---` lines) = heading line, then its image lines, then the extracted text.
$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\.tmp'
$ignoreRe = '\\\.tmp\\|\\\.obsidian\\|\\\.git\\|\\\.trash\\'
$imgRe = '^!\[[^\]]*\]\(.+\)$'
$wikiRe = '^!\[\[.+\]\]$'

function T($x) { return ([string]$x).Trim() }
function Is-Img($x) { $s = T $x; return ($s -match $imgRe) -or ($s -match $wikiRe) }

$files = @(Get-ChildItem -Path $root -Recurse -File -Filter '*.md' | Where-Object { -not [regex]::IsMatch($_.FullName, $ignoreRe) } | Sort-Object Name)
Write-Host "N=$($files.Count)"; $changed = 0
foreach ($f in $files) {
  $text = [System.IO.File]::ReadAllText($f.FullName)
  $lines = @($text -split "`r?`n")

  $segs = New-Object System.Collections.Generic.List[object]
  $cur = New-Object System.Collections.Generic.List[string]
  foreach ($x in $lines) {
    if ((T $x) -eq '---') { $segs.Add($cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
    else { $cur.Add([string]$x) }
  }
  $segs.Add($cur.ToArray())

  $pile = New-Object System.Collections.Generic.List[string]
  $kept = 0
  foreach ($seg in $segs) {
    $imgs = New-Object System.Collections.Generic.List[string]
    $txt = New-Object System.Collections.Generic.List[string]
    foreach ($x in $seg) {
      if ((T $x) -eq '') { continue }
      if (Is-Img $x) { $imgs.Add([string]$x) } else { $txt.Add([string]$x) }
    }
    if ($txt.Count -eq 0 -and $imgs.Count -eq 0) { continue }
    if ($kept -gt 0) { $pile.Add(''); $pile.Add('---'); $pile.Add('') }
    if ($txt.Count -gt 0) { $pile.Add($txt[0]) } else { $pile.Add($imgs[0]) }
    foreach ($m in $imgs) { if ($txt.Count -eq 0 -and $m -eq $imgs[0]) { continue }; $pile.Add($m) }
    for ($i = 1; $i -lt $txt.Count; $i++) { $pile.Add($txt[$i]) }
    $kept++
  }

  $outLines = $pile.ToArray()
  $before = @($lines | Where-Object { (T $_) -ne '' -and (T $_) -ne '---' })
  $after = @($outLines | Where-Object { (T $_) -ne '' -and (T $_) -ne '---' })
  $ib = @($before | Where-Object { Is-Img $_ }).Count
  $ia = @($after | Where-Object { Is-Img $_ }).Count
  if ($before.Count -ne $after.Count -or $ib -ne $ia) {
    Write-Host ("DRIFT {0}: lines {1}->{2} imgs {3}->{4}" -f $f.Name, $before.Count, $after.Count, $ib, $ia)
    continue
  }
  $new = (($outLines -join "`n").TrimEnd()) + "`n"
  if ($new -ne $text) { [System.IO.File]::WriteAllText($f.FullName, $new); $changed++; Write-Host ("FIXED {0}" -f $f.Name) }
}
Write-Host "changed=$changed of $($files.Count)"
