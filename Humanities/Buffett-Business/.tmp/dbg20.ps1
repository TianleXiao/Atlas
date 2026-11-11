function T($x) { return ([string]$x).Trim() }
function Trim2($x) { return ([string]$x).Trim() }
$s = '---'
Write-Host "T(s)=[$((T $s))] type=$((T $s).GetType().Name)"
Write-Host "Trim2(s)=[$((Trim2 $s))]"
Write-Host "direct=[$($s.Trim())]"
Write-Host "eq: $((T $s) -eq '---')"
$lst = New-Object System.Collections.Generic.List[string]
$lst.Add('a'); $lst.Add('---')
foreach ($x in $lst) { Write-Host "  item=[$x] T=[$(T $x)] eq=$((T $x) -eq '---')" }