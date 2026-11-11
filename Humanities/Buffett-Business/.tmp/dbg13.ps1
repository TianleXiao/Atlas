$c = 3
$x = @(1..5)
$out = @($x | Where-Object { $_ -ne 0 })
Write-Host "out=$($out.Count) c=$c"
$y = @(1..4 | Where-Object { $_ -ne 0 })
Write-Host "y=$($y.Count) y+1=$($y.Count + 1)"
Write-Host "inline=$(@($x | Where-Object { $_ -ne 0 }).Count + 1)"
$z = @($x | Where-Object { $_ -ne 0 })
$w = $z.Count
Write-Host "z=$($z.Count) w=$w"
$wrap = @($z)
Write-Host "wrap=$($wrap.Count)"
$cnt = @($z).Count
Write-Host "cnt=$cnt"