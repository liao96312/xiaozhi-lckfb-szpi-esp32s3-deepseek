# Rebuild the xiaozhi firmware for the LCKFB SZPI ESP32-S3 (立创·实战派 S3).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\tools\build.ps1
#
# The project is built from D:\xz\xiaozhi (a short path) because the full
# workspace path makes ninja's command lines exceed the Windows limit.

$ErrorActionPreference = 'Stop'
$ws = Split-Path -Parent $PSScriptRoot
. "$ws\tools\idf-env.ps1"

$project = 'D:\xz\xiaozhi'
if (-not (Test-Path $project)) {
    throw "Project not found: $project"
}

Set-Location $project
& "$env:IDF_PYTHON_ENV_PATH\Scripts\python.exe" scripts\build.py lckfb/szpi-esp32s3 --name lichuang-dev
exit $LASTEXITCODE
