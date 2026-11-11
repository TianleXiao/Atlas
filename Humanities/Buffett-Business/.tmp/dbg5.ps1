$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\.tmp'
$ignoreRe = '\\\.tmp\\'
$a = @(Get-ChildItem -Path $root -Recurse -File -Filter '*.md')
Write-Host "A=$($a.Count) full=[$($a[0].FullName)]"
Write-Host "isMatch=[$([regex]::IsMatch($a[0].FullName, $ignoreRe))]"
$b = @($a | Where-Object { -not [regex]::IsMatch($_.FullName, $ignoreRe) })
Write-Host "B=$($b.Count)"