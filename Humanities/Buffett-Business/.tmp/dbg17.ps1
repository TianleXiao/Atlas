$sepIdx = @()
for ($i=0; $i -lt 5; $i++) { if ($i -eq 1) { $sepIdx += $i } }
Write-Host "seps=$($sepIdx.Count)"
$probe = @(0..2)
Write-Host "probe=$($probe.Count)"