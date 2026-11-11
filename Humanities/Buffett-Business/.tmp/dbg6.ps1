$p = 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\.tmp\t\x.md'
$r = $p -notmatch 'zzz'
Write-Host "script -notmatch zzz: [$r] type=$($r.GetType().Name)"
$s = New-Object System.Collections.Generic.List[string]
$s.Add('a')
$q = @($s | Where-Object { -not ($_ -eq 'zzz') })
Write-Host "list where neg: $($q.Count)"
$t = [string[]]@('a','b')
Write-Host "array neg: $(@($t | Where-Object { $_ -notmatch 'zzz' }).Count)"
Write-Host "hw: $($t.Count)"