$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business'
$ignoreRe = '\\\.tmp\\|\\\.obsidian\\|\\\.git\\|\\\.trash\\'
$imgRe = '^!\[[^\]]*\]\(.+\)$'
$wikiRe = '^!\[\[.+\]\]$'
function T($x) { return ([string]$x).Trim() }
function Is-Img($x) { $s = T $x; return ($s -match $imgRe) -or ($s -match $wikiRe) }
$files = @(Get-ChildItem -Path $root -Recurse -File -Filter '*.md' | Where-Object { -not [regex]::IsMatch($_.FullName, $ignoreRe) } | Sort-Object Name)
Write-Host "N=$($files.Count)"
$drift = 0
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
  $before = @($lines | Where-Object { (T $_) -ne '' })
  $after = @($segs | ForEach-Object { @($_) } | Where-Object { (T $_) -ne '' })
  if ($before.Count -ne $after.Count) { $drift++; Write-Host "DRIFT $($f.Name) $($before.Count) -> $($after.Count) segs=$($segs.Count)" }
}
Write-Host "drift=$drift"