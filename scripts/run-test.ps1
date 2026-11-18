param(
    [ValidateRange(1024, 65535)][int]$Port = 8787,
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$client = Join-Path $root 'client'
if ($Build) {
    $sdk = Get-Command flutter -ErrorAction SilentlyContinue | Select-Object -First 1
    $flutter = if ($sdk) { $sdk.Source } else { 'C:\src\flutter\bin\flutter.bat' }
    if (!(Test-Path -LiteralPath $flutter)) { throw 'Flutter SDK was not found.' }
    Push-Location $client
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0 -and !(Test-Path '.dart_tool\package_config.json')) { throw 'Unable to resolve Flutter dependencies.' }
        & $flutter build web --no-pub --no-web-resources-cdn
        if ($LASTEXITCODE -ne 0) { throw 'Flutter Web build failed.' }
    } finally {
        Pop-Location
    }
}
$env:SONG_WEB_ROOT = Join-Path $client 'build\web'
if (!(Test-Path -LiteralPath (Join-Path $env:SONG_WEB_ROOT 'index.html'))) {
    throw 'Web files were not found. Start with -Build.'
}
Push-Location (Join-Path $root 'services\audio')
try {
    & uv run --locked --no-dev uvicorn server:app --host 127.0.0.1 --port $Port
    if ($LASTEXITCODE -ne 0) { throw 'Unable to start the local test server.' }
} finally {
    Pop-Location
}
