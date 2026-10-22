# Flash the built xiaozhi firmware for the LCKFB SZPI ESP32-S3 (立创·实战派 S3).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\scripts\flash.ps1              # auto-detect the serial port
#   .\scripts\flash.ps1 -Port COM3   # explicit port (use your own)
#   .\scripts\flash.ps1 -ProjectDir D:\path\to\xiaozhi-esp32
#
# Prerequisite: the board must be connected over USB and powered on.

param(
    [string]$Port,
    [string]$ProjectDir = $(if ($env:XIAOZHI_PROJECT_DIR) { $env:XIAOZHI_PROJECT_DIR } else { 'D:\xz\xiaozhi' })
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'idf-env.ps1')

$project = $ProjectDir
if (-not (Test-Path $project)) {
    throw "Project not found: $project  (pass -ProjectDir or set XIAOZHI_PROJECT_DIR, and run scripts/build.ps1 first)"
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
