# Prepara el entorno y dependencias de SmartCart Consumer
# Uso: .\setup.ps1

param(
    [string]$FlutterPath = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$visualFlutter = Join-Path (Split-Path $PSScriptRoot -Parent) "flutter"
$flutterDir = if ($FlutterPath) { $FlutterPath } elseif (Test-Path $visualFlutter) { $visualFlutter } else { $null }

if (-not $flutterDir -or -not (Test-Path "$flutterDir\bin\flutter.bat")) {
    Write-Host "No se encontro Flutter. Descargalo en: $visualFlutter" -ForegroundColor Red
    exit 1
}

$flutterBin = Join-Path $flutterDir "bin"
$env:Path = "$flutterBin;" + $env:Path

Write-Host "Flutter: $flutterDir" -ForegroundColor Cyan

# secrets.properties para Android Maps
$secretsExample = Join-Path $PSScriptRoot "android\secrets.properties.example"
$secretsFile = Join-Path $PSScriptRoot "android\secrets.properties"
if (-not (Test-Path $secretsFile) -and (Test-Path $secretsExample)) {
    Copy-Item $secretsExample $secretsFile
    Write-Host "Creado android/secrets.properties desde example" -ForegroundColor Yellow
}

& "$flutterBin\flutter.bat" pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$flutterBin\flutter.bat" analyze --no-fatal-infos
Write-Host ""
Write-Host "Listo. En Cursor: Ctrl+Shift+P -> Dart: Restart Analysis Server" -ForegroundColor Green
Write-Host "Correr app: $flutterBin\flutter.bat run" -ForegroundColor Green
