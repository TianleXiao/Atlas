$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\.tmp'
$ignoreRe = '^-$|'
$a = @(Get-ChildItem -Path $root -Recurse -File -Filter '*.md')
Write-Host "A=$($a.Count)"
$b = @($a | Where-Object { $_.FullName -notmatch $ignoreRe })
Write-Host "B=$($b.Count) ign=[$ignoreRe]"
$c = @($b | Sort-Object Name)
Write-Host "C=$($c.Count)"
if ($b.Count -gt 0) { Write-Host "full=[$($b[0].FullName)]" }