param([string]$Root = (Get-Location).Path, [switch]$Apply)
$ErrorActionPreference = 'Stop'
$imgRe = '^!\[[^\]]*\]\(.+\)\s*$'
$wikiRe = '^!\[\[.+\]\]\s*$'

function IsImg($s) { return ([string]$s).Trim() -match $imgRe -or ([string]$s).Trim() -match $wikiRe }
function IsHead($s) { return ([string]$s) -match '^\s*#{1,6}\s+\S' }
function IsSep($s) { return ([string]$s) -match '^\s*---\s*$' }
function IsBlank($s) { return ([string]$s).Trim() -eq '' }

function Split-Segments([string[]]$all) {
  $segs = New-Object System.Collections.Generic.List[string[]]
  $cur = New-Object System.Collections.Generic.List[string]
  foreach ($x in $all) {
    if (IsSep $x) { $segs.Add([string[]]$cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
    else { $cur.Add([string]$x) }
  }
  $segs.Add([string[]]$cur.ToArray())
  return ,$segs
}

function Join-Segments($segs) {
  $out = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $segs.Count; $i++) {
    foreach ($x in $segs[$i]) { $out.Add([string]$x) }
    if ($i -lt $segs.Count - 1) { $out.Add('---') }
  }
  return ,$out.ToArray()
}

function Norm([string[]]$all) {
  $segs = Split-Segments $all
  # 1) leading orphan images (before first separator, no heading) -> attach under first heading of body
  for ($guard = 0; $guard -lt 20; $guard++) {
    if ($segs.Count -lt 2) { break }
    $pre = $segs[0]
    $preNe = @($pre | Where-Object { -not (IsBlank $_) })
    if ($preNe.Count -eq 0) {
      $rest = New-Object System.Collections.Generic.List[string[]]
      for ($s = 1; $s -lt $segs.Count; $s++) { $rest.Add($segs[$s]) }
      $segs = Split-Segments (Join-Segments $rest)
      continue
    }
    if ((IsHead $preNe[0]) -or -not (IsImg $preNe[0])) { break }
    $imgs = @($preNe | Where-Object { IsImg $_ })
    $txt = @($preNe | Where-Object { -not (IsImg $_) })
    $b0 = $segs[1]
    $hb = -1
    for ($k = 0; $k -lt $b0.Count; $k++) { if (IsHead $b0[$k]) { $hb = $k; break } }
    if ($txt.Count -gt 0 -or $hb -lt 0) { break }
    $nb = New-Object System.Collections.Generic.List[string]
    for ($k = 0; $k -lt $b0.Count; $k++) {
      $nb.Add([string]$b0[$k])
      if ($k -eq $hb) { foreach ($i in $imgs) { $nb.Add(([string]$i).Trim()) } }
    }
    $nsegs = New-Object System.Collections.Generic.List[string[]]
    $nsegs.Add([string[]]$nb.ToArray())
    for ($s = 2; $s -lt $segs.Count; $s++) { $nsegs.Add($segs[$s]) }
    $segs = Split-Segments (Join-Segments $nsegs)
  }
  # 2) module starting with heading: every image directly under the heading, dedup
  for ($m = 0; $m -lt $segs.Count; $m++) {
    $seg = $segs[$m]
    $imgLines = @($seg | Where-Object { IsImg $_ })
    if ($imgLines.Count -eq 0) { continue }
    $ne = @($seg | Where-Object { -not (IsBlank $_) })
    if ($ne.Count -eq 0 -or -not (IsHead $ne[0])) { continue }
    $imgs = New-Object System.Collections.Generic.List[string]
    $body = New-Object System.Collections.Generic.List[string]
    foreach ($x in $seg) {
      if (IsImg $x) { $imgs.Add(([string]$x).Trim()) }
      else { $body.Add([string]$x) }
    }
    $hb = -1
    for ($k = 0; $k -lt $body.Count; $k++) { if (IsHead $body[$k]) { $hb = $k; break } }
    $res = New-Object System.Collections.Generic.List[string]
    for ($k = 0; $k -lt $body.Count; $k++) {
      $res.Add([string]$body[$k])
      if ($k -eq $hb) { foreach ($i in $imgs) { $res.Add([string]$i) } }
    }
    $segs[$m] = [string[]]$res.ToArray()
  }
  # 3) blank normalisation
  $flat = Join-Segments $segs
  $fin = New-Object System.Collections.Generic.List[string]
  foreach ($x0 in $flat) {
    $x = [string]$x0
    if (IsBlank $x) {
      if ($fin.Count -eq 0) { continue }
      $pv = [string]$fin[$fin.Count - 1]
      if ((IsBlank $pv) -or (IsImg $pv) -or (IsHead $pv)) { continue }
    }
    if (IsSep $x) {
      if ($fin.Count -gt 0 -and -not (IsBlank $fin[$fin.Count - 1])) { $fin.Add('') }
      $fin.Add('---'); $fin.Add(''); continue
    }
    $fin.Add($x)
  }
  while ($fin.Count -gt 0 -and (IsBlank $fin[$fin.Count - 1])) { $fin.RemoveAt($fin.Count - 1) }
  return ,$fin.ToArray()
}

# ---- self-check ----
$t1 = @('![[a.png]]', '', '---', '## Head', 'text')
$o1 = Norm $t1
if ($o1.Count -ne 3 -or $o1[0] -ne '## Head' -or $o1[1] -ne '![[a.png]]' -or $o1[2] -ne 'text') { throw "selfcheck1 failed: $($o1 -join '|')" }
$t2 = @('## Head', 'text', '![[b.png]]', '', '---', '## Two', '![[c.png]]', 'body')
$o2 = Norm $t2
if ($o2[0] -ne '## Head' -or $o2[1] -ne '![[b.png]]' -or $o2[2] -ne 'text') { throw "selfcheck2 failed: $($o2 -join '|')" }
$idx = [array]::IndexOf($o2, '## Two')
if ($o2[$idx + 1] -ne '![[c.png]]' -or $o2[$idx + 2] -ne 'body') { throw "selfcheck3 failed: $($o2 -join '|')" }
"self-check ok"

$files = Get-ChildItem -LiteralPath $Root -Filter '*.md' | Sort-Object Name
$changed = 0; $bad = 0
foreach ($f in $files) {
  $all = [System.IO.File]::ReadAllText($f.FullName) -split "`r?`n"
  $out = Norm $all
  $neBefore = @($all | Where-Object { $_ -match '\S' }).Count
  $neAfter = @($out | Where-Object { $_ -match '\S' }).Count
  if ($neAfter -ne $neBefore) { "CONTENT-CHANGE $($f.Name): $neBefore -> $neAfter"; $bad++; continue }
  $text = ($out -join "`n") + "`n"
  if ($text -ne [System.IO.File]::ReadAllText($f.FullName)) {
    $changed++
    if ($Apply) { [System.IO.File]::WriteAllText($f.FullName, $text) }
  }
}
"files=$($files.Count) changed=$changed content-changes=$bad apply=$($Apply.IsPresent)"
