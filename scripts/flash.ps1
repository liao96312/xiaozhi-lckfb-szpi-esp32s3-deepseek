# Flash the built xiaozhi firmware for the LCKFB SZPI ESP32-S3 (立创·实战派 S3).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\tools\flash.ps1              # auto-detect the serial port
#   .\tools\flash.ps1 -Port COM7   # explicit port
#
# Prerequisite: the board must be connected over USB and powered on.

param(
    [string]$Port
)

$ErrorActionPreference = 'Stop'
$ws = Split-Path -Parent $PSScriptRoot
. "$ws\tools\idf-env.ps1"

$project = 'D:\xz\xiaozhi'
if (-not (Test-Path $project)) {
    throw "Build directory not found: $project  (run tools/build.ps1 first)"
}

if (-not $Port) {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($ports.Count -eq 0) {
        throw @"
No serial port detected. Check that:
  * the board is connected with a DATA cable (not a charge-only cable),
  * the board is powered on,
  * a USB-UART driver is installed (CH343/CP210x) if the board uses one.
"@
    }
    $Port = $ports[0]
    Write-Host "Auto-detected port: $Port (available: $($ports -join ', '))"
}

Set-Location $project
Write-Host "Flashing to $Port ..."
& "$env:IDF_PYTHON_ENV_PATH\Scripts\python.exe" "$env:IDF_PATH\tools\idf.py" -p $Port flash

if ($LASTEXITCODE -ne 0) {
    Write-Warning "flash failed. If the port is busy, close any serial monitor, then retry."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Flash complete. Opening the serial monitor (Ctrl+] to exit)..."
& "$env:IDF_PYTHON_ENV_PATH\Scripts\python.exe" "$env:IDF_PATH\tools\idf.py" -p $Port monitor
