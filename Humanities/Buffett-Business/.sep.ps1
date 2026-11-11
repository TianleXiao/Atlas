$total = 0
$files = Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.md
foreach ($file in $files) {
  $p = $file.FullName
  $lines = [System.Collections.Generic.List[string]]::new([string[]][IO.File]::ReadAllLines($p))
  $orig = $lines.ToArray()
  while ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim() -eq '') { $lines.RemoveAt($lines.Count - 1) }

  # 1. split into modules on separator lines (drops them), trim each module
  $mods = [System.Collections.Generic.List[object]]::new()
  $cur = [System.Collections.Generic.List[string]]::new()
  foreach ($ln in $lines) {
    if ($ln -match '^\s*-{3,}\s*$') { $mods.Add($cur); $cur = [System.Collections.Generic.List[string]]::new() }
    else { $cur.Add($ln) }
  }
  $mods.Add($cur)

  # 2. hoist module head (heading / caveat), keep images attached to the extracted text
  $out = [System.Collections.Generic.List[string]]::new()
  $first = $true
  foreach ($m in $mods) {
    while ($m.Count -gt 0 -and $m[0].Trim() -eq '') { $m.RemoveAt(0) }
    while ($m.Count -gt 0 -and $m[$m.Count - 1].Trim() -eq '') { $m.RemoveAt($m.Count - 1) }
    if ($m.Count -eq 0) { continue }

    $head = [System.Collections.Generic.List[string]]::new()
    $body = [System.Collections.Generic.List[string]]::new()
    $seen = 0
    foreach ($ln in $m) {
      $isImg = $ln -match '^\s*!\[\[[^\]]*\]\]\s*$'
      $isHead = -not $isImg -and ($ln -match '^#{1,6}\s' -or $ln.Trim() -eq '')
      if ($seen -eq 0 -and $isHead) { $head.Add($ln); continue }
      if ($ln.Trim() -ne '') { $seen = 1 }
      $body.Add($ln)
    }
    while ($body.Count -gt 0 -and $body[0].Trim() -eq '') { $body.RemoveAt(0) }
    while ($body.Count -gt 0 -and $body[$body.Count - 1].Trim() -eq '') { $body.RemoveAt($body.Count - 1) }

    if (-not $first) { $out.Add(''); $out.Add('---'); $out.Add('') }
    $first = $false
    foreach ($ln in $head) { $out.Add($ln) }
    foreach ($ln in $body) { $out.Add($ln) }
  }

  $res = [System.Collections.Generic.List[string]]::new()
  foreach ($ln in $out) {
    if ($ln.Trim() -eq '' -and $res.Count -gt 0 -and $res[$res.Count - 1].Trim() -eq '') { continue }
    $res.Add($ln)
  }

  $new = $res.ToArray() + @('')
  if ((($new -join "`n") -ne ($orig -join "`n"))) { [IO.File]::WriteAllLines($p, $new); $total++ }
}
"files changed: $total"
