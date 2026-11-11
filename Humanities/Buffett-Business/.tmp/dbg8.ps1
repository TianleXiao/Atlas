$root = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business'
$files = @(Get-ChildItem -Path $root -Recurse -File -Filter '*.md' | Where-Object { -not [regex]::IsMatch($_.FullName, '\\\.') })
Write-Host "N=$($files.Count)"
$nonBlank = 0; $separators = 0
foreach ($f in $files) {
  foreach ($x in [System.IO.File]::ReadAllLines($f.FullName)) { if ($x.Trim() -ne '') { $nonBlank++ } }
}
Write-Host "nonBlankLines=$nonBlank"