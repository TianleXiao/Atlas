$ErrorActionPreference = 'Stop'
$f = Get-Item -LiteralPath 'C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business\Business 1.1.1.md'
$lines = @([System.IO.File]::ReadAllText($f.FullName) -split "`r?`n")
$probe = @(0..2)
Write-Host "probe=$($probe.Count)"
# does $lines get rebound inside Where-Object blocks? test $lines in script block
$c1 = @($lines | Where-Object { $true }).Count
Write-Host "lines via where-all: $c1 of $($lines.Count)"
$c2 = @($lines | Where-Object { $_ -ne $null }).Count
Write-Host "lines nonnull: $c2"
$c3 = @($lines | Where-Object { $_.GetType().Name -ne 'X' }).Count
Write-Host "c3=$c3"