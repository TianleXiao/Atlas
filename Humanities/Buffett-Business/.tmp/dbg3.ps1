$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\.tmp\t'
$files = Get-ChildItem -Path $root -Recurse -File -Filter '*.md'
Write-Host "raw=$($files.Count)"
$f2 = $files | Where-Object { $_.FullName -notmatch '\\\.' }
Write-Host "filtered=$(@($f2).Count)"