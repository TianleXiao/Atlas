# ponytail: one-shot vault formatter; delete after the layout migration lands.
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$imgRe = '^!\[[^\]]*\]\(.+\)\s*$'
$wikiRe = '^!\[\[.+\]\]\s*$'
function IsImg($s) { return ([string]$s).Trim() -match $imgRe -or ([string]$s).Trim() -match $wikiRe }
function IsHead($s) { return ([string]$s) -match '^\s*#{1,6}\s+\S' }
function IsSep($s) { return ([string]$s) -match '^\s*---\s*$' }
function IsBlank($s) { return ([string]$s).Trim() -eq '' }

function Fix-Text([string[]]$lines) {
  $segs = New-Object System.Collections.Generic.List[string[]]
  $cur = New-Object System.Collections.Generic.List[string]
  foreach ($x in $lines) {
    if (IsSep $x) { $segs.Add([string[]]$cur.ToArray()); $cur = New-Object System.Collections.Generic.List[string] }
    else { $cur.Add([string]$x) }
  }
  $segs.Add([string[]]$cur.ToArray())

  $imgs = @()
  while ($segs.Count -gt 1) {
    $pre = @($segs[0]) | Where-Object { -not (IsBlank $_) }
    if (-not $pre -or (IsHead $pre[0]) -or -not (IsImg $pre[0]) -or @($pre | Where-Object { -not (IsImg $_) })) { break }
    $imgs += @($pre | ForEach-Object { ([string]$_).Trim() })
    $segs.RemoveAt(0)
  }
  if ($imgs) {
    $b = [string[]]$segs[0]
    $hb = -1
    for ($k = 0; $k -lt $b.Count; $k++) { if (IsHead $b[$k]) { $hb = $k; break } }
    if ($hb -ge 0) {
      $nb = New-Object System.Collections.Generic.List[string]
      for ($k = 0; $k -lt $b.Count; $k++) {
        $nb.Add([string]$b[$k])
        if ($k -eq $hb) { foreach ($i in $imgs) { $nb.Add($i) } }
      }
      $segs[0] = [string[]]$nb.ToArray()
    } else { $segs.Insert(0, [string[]]$imgs) }
  }

  for ($m = 0; $m -lt $segs.Count; $m++) {
    $seg = [string[]]$segs[$m]
    if (-not @($seg | Where-Object { IsImg $_ })) { continue }
    $vis = @($seg | Where-Object { -not (IsBlank $_) })
    if (-not $vis -or -not (IsHead $vis[0])) { continue }
    $imgLines = New-Object System.Collections.Generic.List[string]
    $body = New-Object System.Collections.Generic.List[string]
    foreach ($x in $seg) { if (IsImg $x) { $imgLines.Add(([string]$x).Trim()) } else { $body.Add([string]$x) } }
    $hb = 0
    for ($k = 0; $k -lt $body.Count; $k++) { if (IsHead $body[$k]) { $hb = $k; break } }
    $out = New-Object System.Collections.Generic.List[string]
    for ($k = 0; $k -lt $body.Count; $k++) {
      $out.Add([string]$body[$k])
      if ($k -eq $hb) { foreach ($im in $imgLines) { $out.Add($im) } }
    }
    $segs[$m] = [string[]]$out.ToArray()
  }

  $flat = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $segs.Count; $i++) {
    foreach ($x in $segs[$i]) { $flat.Add([string]$x) }
    if ($i -lt $segs.Count - 1) { $flat.Add('---') }
  }
  $fin = New-Object System.Collections.Generic.List[string]
  foreach ($x in $flat) {
    if (IsBlank $x) {
      if (-not $fin) { continue }
      $pv = $fin[$fin.Count - 1]
      if ((IsBlank $pv) -or (IsImg $pv) -or (IsHead $pv)) { continue }
    }
    if (IsSep $x) {
      if ($fin -and -not (IsBlank $fin[$fin.Count - 1])) { $fin.Add('') }
      $fin.Add('---'); $fin.Add(''); continue
    }
    $fin.Add([string]$x)
  }
  while ($fin -and (IsBlank $fin[$fin.Count - 1])) { $fin.RemoveAt($fin.Count - 1) }
  return , $fin.ToArray()
}

$sig = @()
$n1 = Fix-Text @('![[a.png]]', '', '---', '## Head', 'text')
$n2 = Fix-Text @('## Head', 'text', '![[b.png]]', '', '---', '## Two', '![[c.png]]', 'body')
if (($n1 -join '|') -eq '## Head|![[a.png]]|text') { $sig += 'ok1' }
if (($n2 -join '|') -eq '## Head|![[b.png]]|text|---|## Two|![[c.png]]|body') { $sig += 'ok2' }
if ($sig.Count -ne 2) { throw "self-check failed: $($n1 -join '|') / $($n2 -join '|')" }
"self-check ok"

$applied = 0; $skipped = @()
foreach ($f in (Get-ChildItem -LiteralPath $Root -Filter '*.md' | Sort-Object Name)) {
  $raw = [System.IO.File]::ReadAllText($f.FullName)
  $out = Fix-Text ($raw -split "`r?`n")
  $before = @(($raw -split "`r?`n") | Where-Object { $_ -match '\S' }).Count
  $after = @($out | Where-Object { $_ -match '\S' }).Count
  if ($before -ne $after) { $skipped += "$($f.Name) $before -> $after"; continue }
  $text = ($out -join "`n") + "`n"
  if ($text -ne $raw) { [System.IO.File]::WriteAllText($f.FullName, $text); $applied++ }
}
"applied=$applied"
if ($skipped) { "SKIPPED (content lines changed):"; $skipped }
