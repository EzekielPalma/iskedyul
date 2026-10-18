# Runs the exact packaged Windows executable; no Flutter SDK is installed here.
param(
    [Parameter(Mandatory = $true)][string]$Archive,
    [int]$Port = 18080
)
$ErrorActionPreference = 'Stop'
$directory = Join-Path $env:RUNNER_TEMP 'iSkedyul Windows check'
Expand-Archive -LiteralPath $Archive -DestinationPath $directory -Force
$executable = Join-Path $directory 'Start-iSkedyul.exe'
$process = Start-Process -FilePath $executable -ArgumentList '-no-browser', '-port', $Port -PassThru -NoNewWindow
try {
    $address = "http://127.0.0.1:$Port"
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $process.Refresh()
        if ($process.HasExited) { throw 'The Windows launcher exited before serving the app.' }
        try {
            $response = Invoke-WebRequest -Uri "$address/" -TimeoutSec 2
            if ($response.StatusCode -eq 200) { $ready = $true; break }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }
    if (!$ready) { throw 'The Windows launcher did not become ready.' }
    if ($response.Content -notmatch '<base href="/">') { throw 'The web build must use the root base path.' }
    foreach ($asset in @(
        '/main.dart.js',
        '/flutter_bootstrap.js',
        '/canvaskit/canvaskit.wasm',
        '/assets/assets/fonts/DejaVuSans.ttf',
        '/assets/fonts/MaterialIcons-Regular.otf'
    )) {
        $response = Invoke-WebRequest -Uri "$address$asset" -TimeoutSec 15
        if ($response.StatusCode -ne 200 -or $response.RawContentLength -le 0) {
            throw "Missing bundled asset: $asset"
        }
        if ($asset.EndsWith('.wasm') -and [string]$response.Headers['Content-Type'] -notlike 'application/wasm*') {
            throw 'The runtime must be served as application/wasm.'
        }
    }
    Write-Output 'Windows executable starts and serves the app, JavaScript, WASM runtime, fonts, and icons.'
} finally {
    $process.Refresh()
    if (!$process.HasExited) { Stop-Process -Id $process.Id -Force }
}
