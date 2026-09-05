<#
  Resolve the Google Maps short links from the Spain 2026 planning sheet
  into place names and coordinates.

  Put this file and unresolved_links.json in the same folder, then run:

      powershell -ExecutionPolicy Bypass -File .\resolve_links.ps1

  It writes resolved.tsv next to itself. Paste that file's contents back
  into the chat.

  Works on Windows PowerShell 5.1 (the one built into Windows) and on
  PowerShell 7. The only requests made are to Google - the same ones your
  browser makes when you click one of these links.
#>
[CmdletBinding()]
param(
    [string]$InputJson = (Join-Path $PSScriptRoot 'unresolved_links.json'),
    [string]$OutFile   = (Join-Path $PSScriptRoot 'resolved.tsv')
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 still defaults to TLS 1.0, which Google refuses.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36'
$INV = [Globalization.CultureInfo]::InvariantCulture

if (-not (Test-Path -LiteralPath $InputJson)) {
    Write-Host "Can't find unresolved_links.json." -ForegroundColor Red
    Write-Host "Put it in the same folder as this script:  $PSScriptRoot"
    exit 1
}

$items = @(Get-Content -LiteralPath $InputJson -Raw -Encoding UTF8 | ConvertFrom-Json)
Write-Host "Resolving $($items.Count) links..." -ForegroundColor Cyan

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(25)
$client.DefaultRequestHeaders.Add('User-Agent', $UA)
$client.DefaultRequestHeaders.Add('Accept-Language', 'en-US,en;q=0.9')

function Get-PlaceFromUrl {
    param([string]$Url)
    $name = $null; $lat = $null; $lng = $null

    $m = [regex]::Match($Url, '/(?:place|search)/([^/@?]+)')
    if ($m.Success) {
        $n = [uri]::UnescapeDataString($m.Groups[1].Value) -replace '\+', ' '
        if ($n -notmatch '^(?i)data=') { $name = $n.Trim() }
    }

    # !3d/!4d is the place pin itself; /@ is only where the map was centred.
    $m = [regex]::Match($Url, '!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)')
    if (-not $m.Success) { $m = [regex]::Match($Url, '/@(-?\d+\.\d+),(-?\d+\.\d+)') }
    if ($m.Success) {
        $lat = [double]::Parse($m.Groups[1].Value, $INV)
        $lng = [double]::Parse($m.Groups[2].Value, $INV)
    }

    [pscustomobject]@{ Name = $name; Lat = $lat; Lng = $lng }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("date`tblock`tsheet_text`tshort_url`tname`tlat`tlng`tstatus`tfinal_url")

$i = 0; $got = 0; $failed = 0
foreach ($it in $items) {
    $i++
    $short = [string]$it.u
    $final = ''; $status = 'ok'; $name = ''; $latS = ''; $lngS = ''

    try {
        $resp  = $client.GetAsync($short).GetAwaiter().GetResult()
        $final = $resp.RequestMessage.RequestUri.AbsoluteUri
        $p     = Get-PlaceFromUrl $final
        if ($p.Name) { $name = $p.Name }
        if ($null -ne $p.Lat) {
            $latS = $p.Lat.ToString('F6', $INV)
            $lngS = $p.Lng.ToString('F6', $INV)
        }
        if (-not $name -and -not $latS) { $status = 'no-data' } else { $got++ }
    }
    catch {
        $status = 'error: ' + ($_.Exception.Message -replace '\s+', ' ')
        $failed++
    }

    $clean = { param($s) if ($null -eq $s) { '' } else { ([string]$s) -replace "[`t`r`n]", ' ' } }
    $lines.Add((@(
        (& $clean $it.date), (& $clean $it.b), (& $clean $it.txt), (& $clean $short),
        (& $clean $name), $latS, $lngS, (& $clean $status), (& $clean $final)
    ) -join "`t"))

    $shown = if ($name) { $name } else { '-' }
    Write-Host ("[{0,2}/{1}] {2} {3,-9} {4}" -f $i, $items.Count, $it.date, $status, $shown)
    Start-Sleep -Milliseconds 400
}

# UTF-8 with no BOM, so the text pastes cleanly.
[IO.File]::WriteAllLines($OutFile, $lines, (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "resolved $got/$($items.Count)  ($failed network failures)" -ForegroundColor Green
Write-Host "wrote $OutFile"
Write-Host ""
Write-Host "Now paste that file's contents back into the chat." -ForegroundColor Cyan
Write-Host "Tip: run  Get-Content .\resolved.tsv | Set-Clipboard  to copy it all."
